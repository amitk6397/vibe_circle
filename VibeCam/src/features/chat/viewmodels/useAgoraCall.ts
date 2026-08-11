import { useCallback, useEffect, useRef, useState } from 'react';
import { PermissionsAndroid, Platform } from 'react-native';
import {
  ChannelProfileType,
  ClientRoleType,
  ConnectionStateType,
  createAgoraRtcEngine,
  ErrorCodeType,
  IRtcEngine,
  IRtcEngineEventHandler,
} from 'react-native-agora';
import { callApi } from '../services/callApi';

type ConnectionStatus = 'initializing' | 'connecting' | 'connected' | 'reconnecting' | 'ended';

async function requestCallPermissions(video: boolean) {
  if (Platform.OS !== 'android') return;
  const permissions = [PermissionsAndroid.PERMISSIONS.RECORD_AUDIO];
  if (video) permissions.push(PermissionsAndroid.PERMISSIONS.CAMERA);
  if (Number(Platform.Version) >= 31) {
    permissions.push(PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT);
  }
  const result = await PermissionsAndroid.requestMultiple(permissions);
  if (permissions.some((permission) => result[permission] !== PermissionsAndroid.RESULTS.GRANTED)) {
    throw new Error('Microphone and camera permissions are required for calls.');
  }
}

export function useAgoraCall(callId: string, video: boolean) {
  const engineRef = useRef<IRtcEngine | null>(null);
  const activeRef = useRef(true);
  const [status, setStatus] = useState<ConnectionStatus>('initializing');
  const [remoteUid, setRemoteUid] = useState<number | null>(null);
  const [muted, setMuted] = useState(false);
  const [speaker, setSpeaker] = useState(video);
  const [cameraEnabled, setCameraEnabled] = useState(video);
  const [seconds, setSeconds] = useState(0);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    activeRef.current = true;
    let handler: IRtcEngineEventHandler | null = null;
    let pollTimer: ReturnType<typeof setInterval> | null = null;

    const initialize = async () => {
      try {
        await requestCallPermissions(video);
        const { data: rtc } = await callApi.token(callId);
        if (!activeRef.current) return;
        const engine = createAgoraRtcEngine();
        engineRef.current = engine;
        const initializeCode = engine.initialize({ appId: rtc.appId });
        if (initializeCode < 0) throw new Error(`Agora initialization failed (${initializeCode}).`);
        handler = {
          onJoinChannelSuccess: () => {
            if (!activeRef.current) return;
            setStatus('connecting');
            void callApi.join(callId).catch(() => setError('Could not confirm session join.'));
          },
          onUserJoined: (_connection, uid) => {
            if (!activeRef.current) return;
            setRemoteUid(uid);
            setStatus('connected');
          },
          onUserOffline: () => {
            if (!activeRef.current) return;
            setRemoteUid(null);
            setStatus('ended');
          },
          onConnectionStateChanged: (_connection, state) => {
            if (!activeRef.current) return;
            if (state === ConnectionStateType.ConnectionStateReconnecting)
              setStatus('reconnecting');
            if (state === ConnectionStateType.ConnectionStateFailed) {
              setError('The call connection failed. Please try again.');
              setStatus('ended');
            }
          },
          onError: (code: ErrorCodeType, message: string) => {
            if (!activeRef.current) return;
            setError(message || `Agora error ${code}`);
          },
          onTokenPrivilegeWillExpire: () => {
            void callApi
              .token(callId)
              .then(({ data }) => engine.renewToken(data.token))
              .catch(() => setError('Could not renew the secure call token.'));
          },
          onRequestToken: () => {
            void callApi
              .token(callId)
              .then(({ data }) => engine.renewToken(data.token))
              .catch(() => setError('The secure call token expired.'));
          },
        };
        engine.registerEventHandler(handler);
        engine.enableAudio();
        engine.setEnableSpeakerphone(video);
        if (video) {
          engine.enableVideo();
          engine.startPreview();
        } else {
          engine.disableVideo();
        }
        setStatus('connecting');
        const joinCode = engine.joinChannelWithUserAccount(
          rtc.token,
          rtc.channel,
          rtc.userAccount,
          {
            channelProfile: ChannelProfileType.ChannelProfileCommunication,
            clientRoleType: ClientRoleType.ClientRoleBroadcaster,
            publishMicrophoneTrack: true,
            publishCameraTrack: video,
            autoSubscribeAudio: true,
            autoSubscribeVideo: video,
          },
        );
        if (joinCode < 0) throw new Error(`Could not join the call (${joinCode}).`);
        pollTimer = setInterval(() => {
          void callApi
            .get(callId)
            .then(({ data }) => {
              if (['rejected', 'ended', 'missed'].includes(data.status)) {
                setStatus('ended');
                setError(data.status === 'rejected' ? 'The call was declined.' : 'The call ended.');
              }
            })
            .catch(() => undefined);
        }, 3000);
      } catch (reason) {
        if (!activeRef.current) return;
        setError(reason instanceof Error ? reason.message : 'Could not start the call.');
        setStatus('ended');
      }
    };

    void initialize();
    return () => {
      activeRef.current = false;
      if (pollTimer) clearInterval(pollTimer);
      const engine = engineRef.current;
      if (engine) {
        if (handler) engine.unregisterEventHandler(handler);
        engine.stopPreview();
        engine.leaveChannel();
        engine.release();
        engineRef.current = null;
      }
    };
  }, [callId, video]);

  useEffect(() => {
    if (status !== 'connected') return;
    const timer = setInterval(() => setSeconds((value) => value + 1), 1000);
    return () => clearInterval(timer);
  }, [status]);

  const toggleMute = useCallback(() => {
    setMuted((value) => {
      engineRef.current?.muteLocalAudioStream(!value);
      return !value;
    });
  }, []);
  const toggleSpeaker = useCallback(() => {
    setSpeaker((value) => {
      engineRef.current?.setEnableSpeakerphone(!value);
      return !value;
    });
  }, []);
  const toggleCamera = useCallback(() => {
    setCameraEnabled((value) => {
      engineRef.current?.muteLocalVideoStream(value);
      return !value;
    });
  }, []);
  const switchCamera = useCallback(() => engineRef.current?.switchCamera(), []);

  return {
    status,
    remoteUid,
    muted,
    speaker,
    cameraEnabled,
    seconds,
    error,
    toggleMute,
    toggleSpeaker,
    toggleCamera,
    switchCamera,
  };
}
