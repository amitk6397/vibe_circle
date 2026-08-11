import React, { useEffect, useRef, useState } from 'react';
import {
  Alert,
  FlatList,
  KeyboardAvoidingView,
  Platform,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  View,
  Image,
  ActivityIndicator,
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

export function WatchStreamScreen({ navigation, route }: any) {
  const { streamId, title } = route.params as { streamId: string; title: string };
  const insets = useSafeAreaInsets();
  const profile = useAppStore((s) => s.profile);

  const [stream, setStream] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [agoraToken, setAgoraToken] = useState('');
  const [channelName, setChannelName] = useState('');
  const [agoraAppId, setAgoraAppId] = useState('');
  const [hostUid, setHostUid] = useState(0);
  
  const [chatMessages, setChatMessages] = useState<ChatMessage[]>([]);
  const [chatInput, setChatInput] = useState('');
  const [sendingGift, setSendingGift] = useState<string | null>(null);
  const chatRef = useRef<FlatList>(null);

  // Agora states
  const engineRef = useRef<IRtcEngine | null>(null);
  const dataStreamId = useRef<number>(-1);
  const [joined, setJoined] = useState(false);

  useEffect(() => {
    joinStream();
    return () => {
      // Leave stream on unmount
      if (streamId) {
        livestreamApi.leave(streamId).catch(() => {});
      }
    };
  }, []);

  // Agora Integration Effect
  useEffect(() => {
    if (!agoraToken || !channelName || !agoraAppId) return;

    let isMounted = true;
    const initAgora = async () => {
      try {
        const engine = createAgoraRtcEngine();
        engineRef.current = engine;

        const initCode = engine.initialize({ appId: agoraAppId });
        if (initCode < 0) throw new Error(`Agora init failed: ${initCode}`);

        // Set channel profile and client role explicitly
        engine.setChannelProfile(ChannelProfileType.ChannelProfileLiveBroadcasting);
        engine.setClientRole(ClientRoleType.ClientRoleAudience);

        // Create RTC Data Stream for real-time chat & gifts
        const streamCode = engine.createDataStream({ syncWithAudio: false, ordered: false });
        if (streamCode >= 0) {
          dataStreamId.current = streamCode;
        }

        engine.registerEventHandler({
          onJoinChannelSuccess: (connection, elapsed) => {
            console.log('Agora Viewer: Joined channel successfully:', connection.channelId);
            if (isMounted) setJoined(true);
          },
          onUserOffline: (connection, remoteUid, reason) => {
            // Broadcaster went offline
            Alert.alert('Stream Ended', 'The broadcaster has ended the stream.', [
              { text: 'Go Back', onPress: () => navigation.goBack() }
            ]);
          },
          onError: (err, msg) => {
            console.warn('Agora Viewer Error:', err, msg);
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
                if (stream) {
                  setStream((prev: any) => ({
                    ...prev,
                    total_gifts_received: (prev?.total_gifts_received || 0) + msgObj.coins,
                  }));
                }
                setTimeout(() => chatRef.current?.scrollToEnd(), 100);
              }
            } catch (err) {
              console.warn('Viewer: onStreamMessage parse error:', err);
            }
          },
        });

        engine.enableVideo();

        // Join as audience (role=2)
        const joinCode = engine.joinChannel(agoraToken, channelName, 0, {
          channelProfile: ChannelProfileType.ChannelProfileLiveBroadcasting,
          clientRoleType: ClientRoleType.ClientRoleAudience,
          publishMicrophoneTrack: false,
          publishCameraTrack: false,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        });

        if (joinCode < 0) {
          throw new Error(`Agora Viewer Join failed: ${joinCode}`);
        }
      } catch (e: any) {
        console.warn('Agora Viewer initialization failed:', e);
      }
    };

    void initAgora();

    return () => {
      isMounted = false;
      const engine = engineRef.current;
      if (engine) {
        try {
          engine.leaveChannel();
          engine.release();
        } catch (e) {
          console.warn('Agora Release Error:', e);
        }
        engineRef.current = null;
      }
    };
  }, [agoraToken, channelName, agoraAppId]);

  const joinStream = async () => {
    try {
      const { data } = await livestreamApi.join(streamId);
      setStream(data.stream);
      setAgoraToken(data.agora_token);
      setChannelName(data.channel_name);
      setAgoraAppId(data.agora_app_id);
      setHostUid(data.stream.host_uid || data.uid);
      setChatMessages([
        { id: 'sys1', sender: 'System', text: `👋 You joined ${data.stream.title}` },
      ]);
    } catch (e: any) {
      Alert.alert('Cannot join stream', e.message || 'Stream may have ended.', [
        { text: 'Go back', onPress: () => navigation.goBack() },
      ]);
    } finally {
      setLoading(false);
    }
  };

  const sendGift = async (gift: typeof GIFT_OPTIONS[0]) => {
    setSendingGift(gift.name);
    try {
      await livestreamApi.sendGift(streamId, {
        gift_name: gift.name,
        gift_emoji: gift.emoji,
        coins: gift.coins,
      });

      // Update local gift total badge in the UI
      if (stream) {
        setStream((prev: any) => ({
          ...prev,
          total_gifts_received: (prev.total_gifts_received || 0) + gift.coins,
        }));
      }

      // Broadcast gift to the host and other viewers over Agora Data Stream
      if (engineRef.current && dataStreamId.current !== -1) {
        const payload = JSON.stringify({
          type: 'gift',
          sender: profile.name || 'Viewer',
          giftName: gift.name,
          giftEmoji: gift.emoji,
          coins: gift.coins,
        });
        const bytes = new Uint8Array(payload.length);
        for (let i = 0; i < payload.length; i++) {
          bytes[i] = payload.charCodeAt(i);
        }
        try {
          engineRef.current.sendStreamMessage(dataStreamId.current, bytes, bytes.length);
        } catch (err) {
          console.warn('Viewer send stream gift failed:', err);
        }
      }

      const msg: ChatMessage = {
        id: Date.now().toString(),
        sender: profile.name || 'You',
        text: `sent a ${gift.name}!`,
        isGift: true,
        emoji: gift.emoji,
      };
      setChatMessages((prev) => [...prev, msg]);
      setTimeout(() => chatRef.current?.scrollToEnd(), 100);
    } catch (e: any) {
      Alert.alert('Gift failed', e.message || 'Not enough coins or stream ended.');
    } finally {
      setSendingGift(null);
    }
  };

  const sendChat = () => {
    if (!chatInput.trim()) return;
    const msgText = chatInput.trim();

    // Broadcast chat to host and other viewers over Agora Data Stream
    if (engineRef.current && dataStreamId.current !== -1) {
      const payload = JSON.stringify({
        type: 'chat',
        sender: profile.name || 'Viewer',
        text: msgText,
      });
      const bytes = new Uint8Array(payload.length);
      for (let i = 0; i < payload.length; i++) {
        bytes[i] = payload.charCodeAt(i);
      }
      try {
        engineRef.current.sendStreamMessage(dataStreamId.current, bytes, bytes.length);
      } catch (err) {
        console.warn('Viewer send stream message failed:', err);
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

  if (loading) {
    return (
      <View style={styles.loadingRoot}>
        <ActivityIndicator size="large" color={colors.primary} />
        <Text style={styles.loadingText}>Joining stream…</Text>
      </View>
    );
  }

  return (
    <KeyboardAvoidingView
      style={{ flex: 1, backgroundColor: '#0D1020' }}
      behavior={Platform.OS === 'ios' ? 'padding' : undefined}
    >
      <View style={styles.root}>
        
        {/* Background Stream Video */}
        {joined && hostUid ? (
          <RtcSurfaceView
            style={StyleSheet.absoluteFill}
            canvas={{ uid: hostUid }}
            zOrderMediaOverlay={true}
          />
        ) : (
          <LinearGradient
            colors={['#1A0A3A', '#0A0D1A']}
            style={StyleSheet.absoluteFill}
          >
            <View style={styles.placeholderContainer}>
              <ActivityIndicator size="large" color="#fff" />
              <Text style={styles.placeholderText}>Connecting to stream...</Text>
            </View>
          </LinearGradient>
        )}

        {/* Top bar (Floats over video) */}
        <View style={[styles.topBar, { top: insets.top + 6 }]}>
          <Pressable style={styles.backBtn} onPress={() => navigation.goBack()}>
            <Ionicons name="arrow-back" size={20} color="#fff" />
          </Pressable>
          {stream && (
            <View style={styles.liveBadge}>
              <View style={styles.liveDot} />
              <Text style={styles.liveBadgeText}>LIVE</Text>
            </View>
          )}
          <View style={styles.viewerBadge}>
            <Ionicons name="eye" size={13} color="#fff" />
            <Text style={styles.viewerText}>{stream?.current_viewers ?? 0}</Text>
          </View>
        </View>

        {/* Host info (Floats over video) */}
        {stream && (
          <View style={[styles.hostRow, { top: insets.top + 60 }]}>
            <View style={styles.hostAvatar}>
              {stream.host?.avatar_url ? (
                <Image source={{ uri: stream.host.avatar_url }} style={styles.hostAvatarImg} />
              ) : (
                <Text style={styles.hostInitial}>
                  {(stream.host?.name || '?')[0].toUpperCase()}
                </Text>
              )}
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.hostName}>{stream.host?.name}</Text>
              <Text style={styles.streamTitle} numberOfLines={1}>{stream.title}</Text>
            </View>
            <View style={styles.giftTotalBadge}>
              <Ionicons name="gift" size={13} color="#F59E0B" />
              <Text style={styles.giftTotalText}>{stream.total_gifts_received ?? 0}</Text>
            </View>
          </View>
        )}

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
              <Text style={styles.chatText}>
                {item.isGift ? `${item.emoji} ` : ''}{item.text}
              </Text>
            </View>
          )}
        />

        {/* Gift options (Floats over video) */}
        <ScrollView
          horizontal
          showsHorizontalScrollIndicator={false}
          contentContainerStyle={styles.giftRow}
        >
          {GIFT_OPTIONS.map((g) => (
            <Pressable
              key={g.name}
              style={[styles.giftBtn, sendingGift === g.name && { opacity: 0.5 }]}
              onPress={() => sendGift(g)}
              disabled={!!sendingGift}
            >
              <Text style={styles.giftEmoji}>{g.emoji}</Text>
              <Text style={styles.giftName}>{g.name}</Text>
              <Text style={styles.giftCoins}>{g.coins}🪙</Text>
            </Pressable>
          ))}
        </ScrollView>

        {/* Chat input (Docked at bottom) */}
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
          <Pressable style={styles.sendBtn} onPress={sendChat}>
            <Ionicons name="send" size={18} color="#fff" />
          </Pressable>
        </View>
      </View>
    </KeyboardAvoidingView>
  );
}

const styles = StyleSheet.create({
  loadingRoot: { flex: 1, backgroundColor: '#0D1020', alignItems: 'center', justifyContent: 'center', gap: 16 },
  loadingText: { color: '#fff', fontSize: 15 },
  root: { flex: 1, position: 'relative' },
  placeholderContainer: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 12,
  },
  placeholderText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '700',
  },
  topBar: {
    position: 'absolute',
    top: 10,
    left: 0,
    right: 0,
    zIndex: 10,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
    paddingHorizontal: 14,
    paddingVertical: 10,
    backgroundColor: 'rgba(0,0,0,0.3)',
  },
  backBtn: {
    width: 38, height: 38, borderRadius: 19,
    backgroundColor: 'rgba(0,0,0,0.4)',
    alignItems: 'center', justifyContent: 'center',
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
  liveDot: { width: 6, height: 6, borderRadius: 3, backgroundColor: '#fff' },
  liveBadgeText: { color: '#fff', fontWeight: '800', fontSize: 10 },
  viewerBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: 'rgba(0,0,0,0.4)',
    paddingHorizontal: 9,
    paddingVertical: 4,
    borderRadius: 10,
  },
  viewerText: { color: '#fff', fontWeight: '700', fontSize: 12 },
  hostRow: {
    position: 'absolute',
    top: 80,
    left: 14,
    right: 14,
    zIndex: 8,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  hostAvatar: {
    width: 40, height: 40, borderRadius: 20,
    backgroundColor: colors.primary,
    alignItems: 'center', justifyContent: 'center',
    overflow: 'hidden',
  },
  hostAvatarImg: { width: '100%', height: '100%' },
  hostInitial: { color: '#fff', fontWeight: '900', fontSize: 16 },
  hostName: { color: '#fff', fontWeight: '800', fontSize: 14, textShadowColor: '#000', textShadowOffset: { width: 0, height: 1 }, textShadowRadius: 3 },
  streamTitle: { color: 'rgba(255,255,255,0.85)', fontSize: 12, textShadowColor: '#000', textShadowOffset: { width: 0, height: 1 }, textShadowRadius: 3 },
  giftTotalBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    backgroundColor: 'rgba(245,158,11,0.6)',
    paddingHorizontal: 9,
    paddingVertical: 5,
    borderRadius: 10,
  },
  giftTotalText: { color: '#fff', fontWeight: '800', fontSize: 13 },
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
  chatSender: { color: '#A5B4FC', fontWeight: '800', fontSize: 12 },
  chatText: { color: '#fff', fontSize: 12 },
  giftRow: { paddingHorizontal: 12, gap: 8, paddingVertical: 8, backgroundColor: 'rgba(0,0,0,0.3)', maxHeight: 72 },
  giftBtn: { alignItems: 'center', gap: 2, backgroundColor: 'rgba(0,0,0,0.5)', borderRadius: 14, padding: 10, minWidth: 64 },
  giftEmoji: { fontSize: 26 },
  giftName: { color: '#fff', fontSize: 10, fontWeight: '700' },
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
  sendBtn: {
    width: 42, height: 42, borderRadius: 21,
    backgroundColor: colors.primary,
    alignItems: 'center', justifyContent: 'center',
  },
});

export default WatchStreamScreen;
