import React, { useEffect, useRef, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { SafeAreaView } from 'react-native-safe-area-context';
import { RtcSurfaceView } from 'react-native-agora';
import { Avatar } from '../../../components/ui';
import { callApi } from '../services/callApi';
import { useAgoraCall } from '../viewmodels/useAgoraCall';
import { CallSession } from '../models/CallSession';
import { safetyApi } from '../../../services/api';

type Props = {
  callId: string;
  name: string;
  personId: string;
  video: boolean;
  onClose: (session?: CallSession) => void;
};

function duration(value: number) {
  const minutes = Math.floor(value / 60);
  const seconds = value % 60;
  return `${String(minutes).padStart(2, '0')}:${String(seconds).padStart(2, '0')}`;
}

export function CallScreenContent({ callId, name, personId, video, onClose }: Props) {
  const ended = useRef(false);
  const call = useAgoraCall(callId, video);
  const [reservedMinutes, setReservedMinutes] = useState(0);

  useEffect(() => {
    void callApi.get(callId).then(({ data }) => setReservedMinutes(data.reservedMinutes || 0));
  }, [callId]);

  useEffect(
    () => () => {
      if (!ended.current) void callApi.action(callId, 'end').catch(() => undefined);
    },
    [callId],
  );

  const endCall = () => {
    if (ended.current) return;
    ended.current = true;
    void callApi
      .action(callId, 'end')
      .then(({ data }) => onClose(data))
      .catch(() => onClose());
  };

  useEffect(() => {
    if (call.status !== 'ended' || ended.current) return;
    ended.current = true;
    void callApi
      .action(callId, 'end')
      .then(({ data }) => onClose(data))
      .catch(() => onClose());
  }, [call.status, callId, onClose]);

  const extend = () =>
    void callApi
      .config()
      .then(({ data }) =>
        Alert.alert('Extend session', 'Additional coins are locked immediately.', [
          { text: 'Cancel', style: 'cancel' },
          ...data.durationOptions.map((minutes) => ({
            text: `+${minutes} minutes`,
            onPress: () =>
              void callApi
                .extend(callId, minutes)
                .then(({ data: session }) => {
                  setReservedMinutes(session.reservedMinutes || reservedMinutes + minutes);
                  Alert.alert('Session extended');
                })
                .catch((error) => Alert.alert('Could not extend', error.message)),
          })),
        ]),
      )
      .catch((error) => Alert.alert('Could not load durations', error.message));

  const statusText = call.error
    ? call.error
    : call.status === 'connected'
      ? duration(call.seconds)
      : call.status === 'reconnecting'
        ? 'Reconnecting securely…'
        : call.status === 'ended'
          ? 'Call ended'
          : 'Connecting securely…';

  return (
    <View style={styles.root}>
      {video && call.remoteUid !== null ? (
        <RtcSurfaceView style={StyleSheet.absoluteFill} canvas={{ uid: call.remoteUid }} />
      ) : (
        <View style={styles.person}>
          <Avatar name={name} size={112} color="#7879EA" />
          <Text style={styles.name}>{name}</Text>
        </View>
      )}

      {video && call.cameraEnabled && (
        <RtcSurfaceView
          style={styles.localVideo}
          canvas={{ uid: 0 }}
          zOrderMediaOverlay
          zOrderOnTop
        />
      )}

      <SafeAreaView style={styles.overlay} edges={['top', 'bottom']}>
        <View style={styles.header}>
          <Text style={styles.mode}>{video ? 'VIDEO CALL' : 'AUDIO CALL'}</Text>
          <Text style={styles.status}>{statusText}</Text>
        </View>

        <View style={styles.controls}>
          <Control
            icon={call.muted ? 'mic-off' : 'mic'}
            label={call.muted ? 'Unmute' : 'Mute'}
            active={call.muted}
            onPress={call.toggleMute}
          />
          <Control
            icon={call.speaker ? 'volume-high' : 'volume-medium'}
            label="Speaker"
            active={call.speaker}
            onPress={call.toggleSpeaker}
          />
          {video && (
            <Control
              icon={call.cameraEnabled ? 'videocam' : 'videocam-off'}
              label="Camera"
              active={!call.cameraEnabled}
              onPress={call.toggleCamera}
            />
          )}
          {video && <Control icon="camera-reverse" label="Flip" onPress={call.switchCamera} />}
          <Control icon="time-outline" label="Extend" onPress={extend} />
          <Control
            icon="flag-outline"
            label="Report"
            onPress={() =>
              void safetyApi
                .report('call', callId, 'Inappropriate behaviour')
                .then(() => Alert.alert('Report submitted'))
                .catch((error) => Alert.alert('Report failed', error.message))
            }
          />
          <Control
            icon="ban-outline"
            label="Block"
            onPress={() =>
              Alert.alert(`Block ${name}?`, 'This prevents future calls and requests.', [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Block',
                  style: 'destructive',
                  onPress: () =>
                    void safetyApi
                      .block(personId)
                      .then(endCall)
                      .catch((error) => Alert.alert('Block failed', error.message)),
                },
              ])
            }
          />
          <Control icon="call" label="End" danger onPress={endCall} />
        </View>
      </SafeAreaView>
      {!!reservedMinutes && (
        <Text style={styles.remaining}>
          {Math.max(0, reservedMinutes - Math.floor(call.seconds / 60))} min remaining
        </Text>
      )}
    </View>
  );
}

function Control({ icon, label, active, danger, onPress }: any) {
  return (
    <Pressable onPress={onPress} style={styles.controlWrap} accessibilityLabel={label}>
      <View style={[styles.control, active && styles.active, danger && styles.danger]}>
        <Ionicons name={icon} size={24} color="#fff" />
      </View>
      <Text style={styles.controlLabel}>{label}</Text>
    </Pressable>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: '#0D1020' },
  person: { flex: 1, alignItems: 'center', justifyContent: 'center', gap: 14 },
  name: { color: '#fff', fontSize: 28, fontWeight: '900' },
  localVideo: {
    position: 'absolute',
    right: 18,
    top: 70,
    width: 110,
    height: 160,
    borderRadius: 18,
    overflow: 'hidden',
    backgroundColor: '#262B45',
  },
  overlay: { ...StyleSheet.absoluteFillObject, justifyContent: 'space-between' },
  header: { alignItems: 'center', paddingTop: 12, gap: 5 },
  mode: { color: '#C7CAE0', fontSize: 11, fontWeight: '900', letterSpacing: 1.4 },
  status: { color: '#fff', fontSize: 14, textAlign: 'center', paddingHorizontal: 24 },
  controls: {
    flexDirection: 'row',
    justifyContent: 'center',
    alignItems: 'center',
    flexWrap: 'wrap',
    gap: 18,
    padding: 22,
    backgroundColor: 'rgba(8,10,22,.72)',
  },
  controlWrap: { alignItems: 'center', gap: 7, minWidth: 56 },
  control: {
    width: 56,
    height: 56,
    borderRadius: 28,
    backgroundColor: '#34384F',
    alignItems: 'center',
    justifyContent: 'center',
  },
  active: { backgroundColor: '#6C63FF' },
  danger: { backgroundColor: '#F04464' },
  controlLabel: { color: '#ECEEFA', fontSize: 11, fontWeight: '700' },
  remaining: {
    position: 'absolute',
    top: 128,
    alignSelf: 'center',
    color: '#fff',
    fontWeight: '800',
  },
});
