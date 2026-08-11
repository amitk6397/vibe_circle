import React, { useEffect, useRef, useState } from 'react';
import {
  Alert,
  Animated,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  PermissionsAndroid,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import {
  ChannelProfileType,
  ClientRoleType,
  createAgoraRtcEngine,
  IRtcEngine,
  RtcSurfaceView,
} from 'react-native-agora';
import { colors } from '../../../theme';
import { useAppStore } from '../../../store/useAppStore';
import { livestreamApi } from '../../../services/api';

const GIFT_OPTIONS = [
  { name: 'Heart', emoji: '❤️', coins: 5 },
  { name: 'Star', emoji: '⭐', coins: 10 },
  { name: 'Fire', emoji: '🔥', coins: 20 },
  { name: 'Diamond', emoji: '💎', coins: 50 },
  { name: 'Crown', emoji: '👑', coins: 100 },
  { name: 'Rocket', emoji: '🚀', coins: 200 },
];

type ChatMessage = { id: string; sender: string; text: string; isGift?: boolean; emoji?: string };

export function GoLiveScreen({ navigation }: any) {
  const insets = useSafeAreaInsets();
  const profile = useAppStore((s) => s.profile);
  const dark = useAppStore((s) => s.darkMode);

  const [step, setStep] = useState<'setup' | 'live'>('setup');
  const [title, setTitle] = useState('');
  const [category, setCategory] = useState('General');
  const [streamId, setStreamId] = useState<string | null>(null);
  const [channelName, setChannelName] = useState('');
  const [agoraToken, setAgoraToken] = useState('');
  const [agoraAppId, setAgoraAppId] = useState('');
  const [hostUid, setHostUid] = useState(0);
  
  const [starting, setStarting] = useState(false);
  const [duration, setDuration] = useState(0);
  const [viewers, setViewers] = useState(0);
  const [totalGifts, setTotalGifts] = useState(0);
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([]);
  const [chatInput, setChatInput] = useState('');
  const chatRef = useRef<FlatList>(null);

  // Ref to track latest streamId for unmount cleanup
  const streamIdRef = useRef<string | null>(null);
  useEffect(() => {
    streamIdRef.current = streamId;
  }, [streamId]);

  // Intercept back actions (mobile hardware button and swipe gestures)
  useEffect(() => {
    const unsubscribe = navigation.addListener('beforeRemove', (e: any) => {
      if (step !== 'live') {
        return;
      }
      e.preventDefault();
      Alert.alert(
        'End Live Stream?',
        'Going back will stop your broadcast. End stream now?',
        [
          { text: 'Cancel', style: 'cancel', onPress: () => {} },
          {
            text: 'End Stream',
            style: 'destructive',
            onPress: () => {
              if (streamIdRef.current) {
                livestreamApi.end(streamIdRef.current).catch(() => {});
              }
              navigation.dispatch(e.data.action);
            },
          },
        ]
      );
    });
    return unsubscribe;
  }, [navigation, step]);

  // Agora states
  const engineRef = useRef<IRtcEngine | null>(null);
  const dataStreamId = useRef<number>(-1);
  const [cameraEnabled, setCameraEnabled] = useState(true);
  const [muted, setMuted] = useState(false);

  // Request Microphone and Camera Permissions (Android)
  const requestStreamPermissions = async () => {
    if (Platform.OS !== 'android') return true;
    try {
      const permissions = [
        PermissionsAndroid.PERMISSIONS.RECORD_AUDIO,
        PermissionsAndroid.PERMISSIONS.CAMERA,
      ];
      if (Number(Platform.Version) >= 31) {
        permissions.push(PermissionsAndroid.PERMISSIONS.BLUETOOTH_CONNECT);
      }
      const granted = await PermissionsAndroid.requestMultiple(permissions);
      const allGranted = permissions.every(
        (perm) => granted[perm] === PermissionsAndroid.RESULTS.GRANTED
      );
      if (!allGranted) {
        Alert.alert(
          'Permissions Required',
          'Camera and Microphone permissions are required to broadcast live streams.'
        );
        return false;
      }
      return true;
    } catch (err) {
      console.warn(err);
      return false;
    }
  };

  // Duration counter
  useEffect(() => {
    if (step !== 'live') return;
    const t = setInterval(() => setDuration((d) => d + 1), 1000);
    return () => clearInterval(t);
  }, [step]);

  // Agora Engine Hook/Effect
  useEffect(() => {
    if (step !== 'live' || !agoraToken || !channelName || !agoraAppId) return;

    let isMounted = true;
    const initAgora = async () => {
      try {
        const engine = createAgoraRtcEngine();
        engineRef.current = engine;

        const initCode = engine.initialize({ appId: agoraAppId });
        if (initCode < 0) throw new Error(`Agora init failed: ${initCode}`);

        // Set channel profile and client role explicitly
        engine.setChannelProfile(ChannelProfileType.ChannelProfileLiveBroadcasting);
        engine.setClientRole(ClientRoleType.ClientRoleBroadcaster);

        // Create RTC Data Stream for real-time chat & gifts
        const streamCode = engine.createDataStream({ syncWithAudio: false, ordered: false });
        if (streamCode >= 0) {
          dataStreamId.current = streamCode;
        }

        engine.registerEventHandler({
          onJoinChannelSuccess: (connection, elapsed) => {
            console.log('Agora Stream: Joined channel successfully:', connection.channelId);
          },
          onUserJoined: (connection, remoteUid) => {
            setViewers((v) => v + 1);
          },
          onUserOffline: (connection, remoteUid, reason) => {
            setViewers((v) => Math.max(0, v - 1));
          },
          onError: (err, msg) => {
            console.warn('Agora Live Stream Broadcaster Error:', err, msg);
          },
          onStreamMessage: (connection, remoteUid, streamId, data, length) => {
            try {
              let str = '';
              for (let i = 0; i < length; i++) {
                str += String.fromCharCode(data[i]);
              }
              const msgObj = JSON.parse(str);
              if (msgObj.type === 'chat') {
                const msg: ChatMessage = {
                  id: Math.random().toString(),
                  sender: msgObj.sender,
                  text: msgObj.text,
                };
                setChatMessages((prev) => [...prev, msg]);
                setTimeout(() => chatRef.current?.scrollToEnd(), 100);
              } else if (msgObj.type === 'gift') {
                const msg: ChatMessage = {
                  id: Math.random().toString(),
                  sender: msgObj.sender,
                  text: `sent a ${msgObj.giftName}!`,
                  isGift: true,
                  emoji: msgObj.giftEmoji,
                };
                setChatMessages((prev) => [...prev, msg]);
                setTotalGifts((g) => g + msgObj.coins);
                setTimeout(() => chatRef.current?.scrollToEnd(), 100);
              }
            } catch (err) {
              console.warn('Broadcaster: onStreamMessage parse error:', err);
            }
          },
        });

        engine.enableAudio();
        engine.enableVideo();
        engine.enableLocalVideo(true);
        engine.muteLocalVideoStream(false);
        engine.muteLocalAudioStream(false);
        engine.startPreview();

        const joinCode = engine.joinChannel(agoraToken, channelName, hostUid, {
          channelProfile: ChannelProfileType.ChannelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.ClientRoleBroadcaster,
          publishMicrophoneTrack: true,
          publishCameraTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        });

        if (joinCode < 0) {
          throw new Error(`Agora Join failed: ${joinCode}`);
        }
      } catch (e: any) {
        Alert.alert('Streaming Server Error', e.message || 'Unable to connect video server.');
        setStep('setup');
      }
    };

    void initAgora();

    return () => {
      isMounted = false;
      // Auto-end stream on unmount
      if (streamIdRef.current) {
        livestreamApi.end(streamIdRef.current).catch(() => {});
      }
      const engine = engineRef.current;
      if (engine) {
        try {
          engine.stopPreview();
          engine.leaveChannel();
          engine.release();
        } catch (e) {
          console.warn('Agora Release Error:', e);
        }
        engineRef.current = null;
      }
    };
  }, [step, agoraToken, channelName, agoraAppId, hostUid]);

  const formatDuration = (s: number) => {
    const m = Math.floor(s / 60);
    const sec = s % 60;
    return `${String(m).padStart(2, '0')}:${String(sec).padStart(2, '0')}`;
  };

  const CATEGORIES = ['General', 'Gaming', 'Music', 'Fitness', 'Talk', 'Art', 'Education'];

  const startStream = async () => {
    if (!title.trim()) return Alert.alert('Add a title', 'Give your stream a title to attract viewers.');
    
    // Check permissions before making api call
    const hasPerms = await requestStreamPermissions();
    if (!hasPerms) return;

    setStarting(true);
    try {
      const { data } = await livestreamApi.start({
        title: title.trim(),
        description: '',
        category,
      });
      setStreamId(data.stream.id);
      setChannelName(data.channel_name);
      setAgoraToken(data.agora_token);
      setAgoraAppId(data.agora_app_id);
      setHostUid(data.uid);
      setStep('live');
      setChatMessages([
        { id: 'sys1', sender: 'System', text: '🎉 Your stream is live! Share the link to get viewers.' },
      ]);
    } catch (e: any) {
      Alert.alert('Could not start stream', e.message || 'Try again.');
    } finally {
      setStarting(false);
    }
  };

  const endStream = () => {
    Alert.alert('End Stream?', 'Are you sure you want to end your live stream?', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'End Stream',
        style: 'destructive',
        onPress: async () => {
          if (streamId) {
            try { await livestreamApi.end(streamId); } catch {}
          }
          navigation.goBack();
        },
      },
    ]);
  };

  const flipCamera = () => {
    engineRef.current?.switchCamera();
  };

  const toggleMute = () => {
    setMuted((prev) => {
      const next = !prev;
      engineRef.current?.muteLocalAudioStream(next);
      return next;
    });
  };

  const toggleCamera = () => {
    setCameraEnabled((prev) => {
      const next = !prev;
      engineRef.current?.muteLocalVideoStream(!next);
      return next;
    });
  };

  const sendChat = () => {
    if (!chatInput.trim()) return;
    const msgText = chatInput.trim();
    
    // Broadcast to other users over Agora Data Stream
    if (engineRef.current && dataStreamId.current !== -1) {
      const payload = JSON.stringify({
        type: 'chat',
        sender: profile.name || 'Host',
        text: msgText,
      });
      const bytes = new Uint8Array(payload.length);
      for (let i = 0; i < payload.length; i++) {
        bytes[i] = payload.charCodeAt(i);
      }
      try {
        engineRef.current.sendStreamMessage(dataStreamId.current, bytes, bytes.length);
      } catch (err) {
        console.warn('Broadcaster send stream message failed:', err);
      }
    }

    const msg: ChatMessage = {
      id: Date.now().toString(),
      sender: profile.name || 'You',
      text: msgText,
    };
    setChatMessages((prev) => [...prev, msg]);
    setChatInput('');
    setTimeout(() => chatRef.current?.scrollToEnd(), 100);
  };

  // --- SETUP SCREEN ---
  if (step === 'setup') {
    return (
      <View style={[styles.root, dark && { backgroundColor: '#0D1020' }, { paddingTop: insets.top }]}>
        <View style={styles.setupHeader}>
          <Pressable style={styles.backBtn} onPress={() => navigation.goBack()}>
            <Ionicons name="arrow-back" size={22} color={dark ? '#F5F7FF' : colors.text} />
          </Pressable>
          <Text style={[styles.setupTitle, dark && { color: '#F5F7FF' }]}>Go Live</Text>
        </View>

        <ScrollView contentContainerStyle={styles.setupBody} showsVerticalScrollIndicator={false}>
          {/* Preview */}
          <LinearGradient
            colors={['#3B3F9A', '#7C3AED']}
            style={styles.setupPreview}
          >
            <Ionicons name="radio" size={52} color="rgba(255,255,255,0.7)" />
            <Text style={styles.setupPreviewName}>{profile.name}</Text>
          </LinearGradient>

          {/* Title input */}
          <View style={styles.inputGroup}>
            <Text style={[styles.inputLabel, dark && { color: '#AAB0C5' }]}>Stream Title *</Text>
            <TextInput
              style={[styles.input, dark && { backgroundColor: '#232A45', color: '#F5F7FF', borderColor: '#333A57' }]}
              value={title}
              onChangeText={setTitle}
              placeholder="What are you streaming today?"
              placeholderTextColor={colors.muted}
              maxLength={100}
            />
          </View>

          {/* Category */}
          <View style={styles.inputGroup}>
            <Text style={[styles.inputLabel, dark && { color: '#AAB0C5' }]}>Category</Text>
            <ScrollView horizontal showsHorizontalScrollIndicator={false} contentContainerStyle={styles.catRow}>
              {CATEGORIES.map((c) => (
                <Pressable
                  key={c}
                  style={[styles.catChip, category === c && styles.catChipActive]}
                  onPress={() => setCategory(c)}
                >
                  <Text style={[styles.catChipText, category === c && styles.catChipTextActive]}>{c}</Text>
                </Pressable>
              ))}
            </ScrollView>
          </View>

          {/* Earn info */}
          <View style={[styles.earnCard, dark && { backgroundColor: '#232A45' }]}>
            <Ionicons name="gift-outline" size={22} color="#F59E0B" />
            <View style={{ flex: 1 }}>
              <Text style={[styles.earnCardTitle, dark && { color: '#F5F7FF' }]}>💰 Earn from your stream</Text>
              <Text style={[styles.earnCardSub, dark && { color: '#AAB0C5' }]}>
                Viewers send virtual gifts. You earn coins minus a small platform fee.
              </Text>
            </View>
          </View>

          <Pressable
            style={[styles.startBtn, starting && { opacity: 0.7 }]}
            onPress={startStream}
            disabled={starting}
          >
            <LinearGradient colors={['#7C3AED', '#5B5CE2']} style={styles.startBtnGrad}>
              <Ionicons name="radio" size={20} color="#fff" />
              <Text style={styles.startBtnText}>{starting ? 'Starting…' : 'Start Live Stream'}</Text>
            </LinearGradient>
          </Pressable>
        </ScrollView>
      </View>
    );
  }

  // --- LIVE SCREEN ---
  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: '#0D1020' }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={styles.liveRoot}>
        
        {/* RtcSurfaceView shows local camera preview */}
        {cameraEnabled ? (
          <RtcSurfaceView
            style={StyleSheet.absoluteFill}
            canvas={{ uid: 0 }}
            zOrderMediaOverlay={true}
            zOrderOnTop={true}
          />
        ) : (
          <LinearGradient
            colors={['#1A0A3A', '#0D1020']}
            style={StyleSheet.absoluteFill}
          />
        )}

        {/* Top bar (Floats over video) */}
        <View style={[styles.liveTopBar, { top: insets.top + 6 }]}>
          <View style={styles.liveBadge}>
            <View style={styles.liveDot} />
            <Text style={styles.liveBadgeText}>LIVE</Text>
          </View>
          <Text style={styles.liveTimer}>{formatDuration(duration)}</Text>
          <View style={styles.liveStats}>
            <Ionicons name="eye" size={14} color="#fff" />
            <Text style={styles.liveStatText}>{viewers}</Text>
            <Ionicons name="gift" size={14} color="#F59E0B" style={{ marginLeft: 8 }} />
            <Text style={styles.liveStatText}>{totalGifts}</Text>
          </View>
          <Pressable style={styles.endBtn} onPress={endStream}>
            <Text style={styles.endBtnText}>End</Text>
          </Pressable>
        </View>

        {/* Float camera controller panel */}
        <View style={[styles.floatingControls, { top: insets.top + 130 }]}>
          <Pressable style={styles.controlCircle} onPress={flipCamera}>
            <Ionicons name="camera-reverse" size={22} color="#fff" />
          </Pressable>
          <Pressable style={[styles.controlCircle, muted && styles.controlCircleActive]} onPress={toggleMute}>
            <Ionicons name={muted ? "mic-off" : "mic"} size={22} color="#fff" />
          </Pressable>
          <Pressable style={[styles.controlCircle, !cameraEnabled && styles.controlCircleActive]} onPress={toggleCamera}>
            <Ionicons name={cameraEnabled ? "videocam" : "videocam-off"} size={22} color="#fff" />
          </Pressable>
        </View>

        {/* Streamer info overlay */}
        <View style={[styles.liveHostRow, { top: insets.top + 70 }]}>
          <View style={styles.liveHostAvatar}>
            <Text style={styles.liveHostInitial}>{(profile.name || '?')[0].toUpperCase()}</Text>
          </View>
          <View>
            <Text style={styles.liveHostName}>{profile.name}</Text>
            <Text style={styles.liveStreamTitle}>{title}</Text>
          </View>
        </View>

        {/* Chat */}
        <FlatList
          ref={chatRef}
          data={chatMessages}
          keyExtractor={(m) => m.id}
          style={styles.chatFlatList}
          contentContainerStyle={styles.chatListContent}
          showsVerticalScrollIndicator={false}
          renderItem={({ item }) => (
            <View style={styles.chatBubble}>
              <Text style={styles.chatSender}>{item.sender}: </Text>
              <Text style={styles.chatText}>{item.isGift ? `${item.emoji} ` : ''}{item.text}</Text>
            </View>
          )}
        />

        {/* Chat input */}
        <View style={[styles.chatInputRow, { paddingBottom: Math.max(insets.bottom, 12) }]}>
          <TextInput
            style={styles.chatInput}
            value={chatInput}
            onChangeText={setChatInput}
            placeholder="Say something..."
            placeholderTextColor="rgba(255,255,255,0.4)"
            onSubmitEditing={sendChat}
            returnKeyType="send"
          />
          <Pressable style={styles.chatSendBtn} onPress={sendChat}>
            <Ionicons name="send" size={18} color="#fff" />
          </Pressable>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  root: { flex: 1, backgroundColor: colors.bg },
  // Setup
  setupHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    paddingHorizontal: 16,
    paddingVertical: 12,
  },
  backBtn: {
    width: 40, height: 40, borderRadius: 20,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center', justifyContent: 'center',
  },
  setupTitle: { fontSize: 20, fontWeight: '900', color: colors.text },
  setupBody: { padding: 20, gap: 20, paddingBottom: 40 },
  setupPreview: {
    width: '100%',
    height: 200,
    borderRadius: 20,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
  },
  setupPreviewName: { color: '#fff', fontSize: 18, fontWeight: '800' },
  inputGroup: { gap: 8 },
  inputLabel: { color: colors.text, fontWeight: '700', fontSize: 14 },
  input: {
    backgroundColor: colors.surface,
    borderWidth: 1,
    borderColor: colors.border,
    borderRadius: 14,
    padding: 14,
    fontSize: 15,
    color: colors.text,
  },
  catRow: { gap: 8 },
  catChip: {
    paddingHorizontal: 14,
    paddingVertical: 8,
    borderRadius: 20,
    backgroundColor: colors.surfaceAlt,
    borderWidth: 1,
    borderColor: colors.border,
  },
  catChipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  catChipText: { color: colors.muted, fontWeight: '700', fontSize: 13 },
  catChipTextActive: { color: '#fff' },
  earnCard: {
    flexDirection: 'row',
    gap: 12,
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 16,
    alignItems: 'flex-start',
  },
  earnCardTitle: { color: colors.text, fontWeight: '800', fontSize: 14 },
  earnCardSub: { color: colors.muted, fontSize: 12, lineHeight: 18, marginTop: 2 },
  startBtn: { borderRadius: 22, overflow: 'hidden', marginTop: 4 },
  startBtnGrad: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    paddingVertical: 16,
    borderRadius: 22,
  },
  startBtnText: { color: '#fff', fontWeight: '900', fontSize: 17 },
  // Live
  liveRoot: { flex: 1, position: 'relative' },
  liveTopBar: {
    position: 'absolute',
    top: 10,
    left: 0,
    right: 0,
    zIndex: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 16,
    paddingVertical: 10,
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  liveBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 5,
    backgroundColor: '#EF4444',
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 10,
  },
  liveDot: { width: 7, height: 7, borderRadius: 3.5, backgroundColor: '#fff' },
  liveBadgeText: { color: '#fff', fontWeight: '800', fontSize: 11 },
  liveTimer: { color: '#fff', fontWeight: '700', fontSize: 14, flex: 1 },
  liveStats: { flexDirection: 'row', alignItems: 'center', gap: 4 },
  liveStatText: { color: '#fff', fontWeight: '700', fontSize: 13 },
  endBtn: {
    backgroundColor: '#EF4444',
    paddingHorizontal: 14,
    paddingVertical: 7,
    borderRadius: 12,
  },
  endBtnText: { color: '#fff', fontWeight: '800', fontSize: 13 },
  floatingControls: {
    position: 'absolute',
    right: 16,
    top: 90,
    gap: 12,
    zIndex: 10,
  },
  controlCircle: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: 'rgba(0,0,0,0.55)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  controlCircleActive: {
    backgroundColor: '#EF4444',
  },
  liveHostRow: {
    position: 'absolute',
    top: 80,
    left: 16,
    zIndex: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  liveHostAvatar: {
    width: 38, height: 38, borderRadius: 19,
    backgroundColor: colors.primary,
    alignItems: 'center', justifyContent: 'center',
  },
  liveHostInitial: { color: '#fff', fontWeight: '900', fontSize: 16 },
  liveHostName: { color: '#fff', fontWeight: '800', fontSize: 14, textShadowColor: '#000', textShadowOffset: { width: 0, height: 1 }, textShadowRadius: 3 },
  liveStreamTitle: { color: 'rgba(255,255,255,0.85)', fontSize: 12, textShadowColor: '#000', textShadowOffset: { width: 0, height: 1 }, textShadowRadius: 3 },
  chatFlatList: {
    height: 180,
    maxHeight: 180,
    alignSelf: 'stretch',
    marginTop: 'auto',
    marginBottom: 8,
  },
  chatListContent: {
    paddingHorizontal: 16,
    paddingBottom: 10,
    gap: 6,
  },
  chatBubble: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    backgroundColor: 'rgba(0,0,0,0.5)',
    alignSelf: 'flex-start',
    borderRadius: 12,
    paddingHorizontal: 10,
    paddingVertical: 6,
    marginBottom: 4,
  },
  chatSender: { color: '#A5B4FC', fontWeight: '800', fontSize: 13 },
  chatText: { color: '#fff', fontSize: 13 },
  giftRow: { paddingHorizontal: 12, gap: 10, paddingVertical: 8, backgroundColor: 'rgba(0,0,0,0.3)', maxHeight: 60 },
  giftItem: { alignItems: 'center', gap: 2 },
  giftEmoji: { fontSize: 24 },
  giftCoins: { color: '#F59E0B', fontSize: 10, fontWeight: '700' },
  chatInputRow: {
    flexDirection: 'row',
    gap: 10,
    paddingHorizontal: 12,
    paddingTop: 8,
    backgroundColor: '#0D1020',
    borderTopWidth: 1,
    borderTopColor: 'rgba(255,255,255,0.08)',
  },
  chatInput: {
    flex: 1,
    backgroundColor: 'rgba(255,255,255,0.1)',
    borderRadius: 22,
    paddingHorizontal: 16,
    paddingVertical: 10,
    color: '#fff',
    fontSize: 14,
  },
  chatSendBtn: {
    width: 42, height: 42, borderRadius: 21,
    backgroundColor: colors.primary,
    alignItems: 'center', justifyContent: 'center',
  },
});

export default GoLiveScreen;
