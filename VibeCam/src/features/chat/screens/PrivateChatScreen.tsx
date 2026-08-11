import React, { useCallback, useEffect, useRef, useState } from 'react';

import { useFocusEffect } from '@react-navigation/native';

import { useSafeAreaInsets } from 'react-native-safe-area-context';

import {
  ActivityIndicator,
  Alert,
  Animated,
  Dimensions,
  Image,
  Keyboard,
  KeyboardAvoidingView,
  Modal,
  PanResponder,
  Platform,
  Pressable,
  ScrollView,
  Switch,
  Text,
  TextInput,
  View,
} from 'react-native';

import { Ionicons } from '@expo/vector-icons';

import { LinearGradient } from 'expo-linear-gradient';

import {
  Avatar,
  Button,
  Card,
  CommunityCard,
  EmptyState,
  Field,
  Header,
  IconButton,
  PersonCard,
  Pill,
  PostCard,
  Screen,
  SearchField,
  Section,
  ShareModal,
  ui,
} from '../../../components/ui';

import { ChatSkeleton } from '../../../components/ChatSkeleton';

import { LANGUAGES, PURPOSES } from '../../../constants/data';

import { colors } from '../../../theme';

import { LocalAttachment, Post, Purpose } from '../../../types';

import { useAppStore } from '../../../store/useAppStore';

import {
  formatFileSize,
  pickDocument,
  pickImage,
  pickStoryImages,
} from '../../../services/mediaPicker';

import {
  chatApi,
  contentApi,
  discoveryApi,
  earningsApi,
  matchingApi,
  safetyApi,
  storyApi,
  uploadAttachment,
  usersApi,
  walletApi,
} from '../../../services/api';

import { useInboxSync, usePrivateRealtime } from '../../chat/viewmodels/useRealtimeChat';
import { callApi } from '../services/callApi';

import { styles } from '../../shared-views/styles';
import { ConversationLimit } from '../../conversation/models/ConversationAccess';
import { UserWallet } from '../../commerce/models/Commerce';

const confirmedChats: Record<string, boolean> = {};

export function PrivateChatScreen({ navigation, route }: any) {
  const { messages, sendMessage } = useAppStore();
  const blocked = useAppStore((state) =>
    route.params.personId ? state.blockedUsers.includes(route.params.personId) : false,
  );
  const [text, setText] = useState('');
  const [attachment, setAttachment] = useState<LocalAttachment | null>(null);
  const [replyTo, setReplyTo] = useState<any>(null);
  const [sessionSeconds, setSessionSeconds] = useState<number | null>(null);
  const [chatLimit, setChatLimit] = useState<ConversationLimit | null>(null);
  const sessionEnded = useRef(false);
  const hasConfirmedDeduction = useRef(false);
  const chatScrollRef = useRef<ScrollView>(null);
  const realtime = usePrivateRealtime(route.params.chatId);
  const list = messages.filter((x) => x.chatId === route.params.chatId);
  const latestMessageId = list[list.length - 1]?.id;
  const scrollToLatestMessage = useCallback((animated = false) => {
    requestAnimationFrame(() => chatScrollRef.current?.scrollToEnd({ animated }));
  }, []);

  const [wallet, setWallet] = useState<UserWallet | null>(null);

  const refreshLimits = useCallback(() => {
    void chatApi
      .limits(route.params.chatId)
      .then(({ data }) => setChatLimit(data))
      .catch(() => setChatLimit(null));
  }, [route.params.chatId]);

  const refreshWallet = useCallback(() => {
    void walletApi.get()
      .then(({ data }: any) => setWallet(data))
      .catch(() => setWallet(null));
  }, []);

  useEffect(() => {
    refreshLimits();
    refreshWallet();
  }, [refreshLimits, refreshWallet]);

  const accessExpired = sessionSeconds === 0;
  const balance = wallet ? (wallet.purchased_coins + wallet.bonus_coins) : null;
  const hasBalance = balance === null || balance > 0;
  const canSend = !accessExpired && hasBalance;
  const showPurchasePrompt = (reason = 'Your chat or call access has ended.') =>
    Alert.alert(
      'Continue the conversation',
      `${reason} Keep enough coins available for paid chat and call minutes.`,
      [
        { text: 'Not now', style: 'cancel' },
        {
          text: 'Plans & coins',
          onPress: () => navigation.navigate('SubscriptionPlans', { source: 'chat_limit' }),
        },
        { text: 'Dashboard', onPress: () => navigation.navigate('Wallet') },
      ],
    );
  // Limits loaded during wallet and limits combined useEffect
  useEffect(() => {
    if (!realtime.loading) scrollToLatestMessage(false);
  }, [latestMessageId, realtime.loading, scrollToLatestMessage]);
  useEffect(() => {
    const keyboardSubscription = Keyboard.addListener('keyboardDidShow', () =>
      scrollToLatestMessage(true),
    );
    return () => keyboardSubscription.remove();
  }, [scrollToLatestMessage]);
  useEffect(() => {
    if (!route.params.sessionEndsAt) return;
    const update = () => {
      const remaining = Math.max(
        0,
        Math.ceil((new Date(route.params.sessionEndsAt).getTime() - Date.now()) / 1000),
      );
      setSessionSeconds(remaining);
      if (remaining === 0 && !sessionEnded.current) {
        sessionEnded.current = true;
        Alert.alert('Chat time complete', 'Your paid conversation has ended.', [
          {
            text: 'Leave feedback',
            onPress: () =>
              route.params.matchId
                ? navigation.replace('SessionFeedback', {
                    matchId: route.params.matchId,
                    personId: route.params.personId,
                  })
                : navigation.replace('SessionRating', {
                    sessionId: route.params.chatId,
                    userId: route.params.personId,
                    sessionType: 'chat',
                  }),
          },
        ]);
      }
    };
    update();
    const timer = setInterval(update, 1000);
    return () => clearInterval(timer);
  }, [navigation, route.params.matchId, route.params.personId, route.params.sessionEndsAt]);
  const requestCall = async (type: 'audio' | 'video') => {
    if (!route.params.personId) return Alert.alert('Call unavailable', 'User details are missing.');
    if (!canSend) {
      showPurchasePrompt('Your access limit is complete.');
      return;
    }
    try {
      const [{ data: profile }, { data: config }] = await Promise.all([
        earningsApi.profile(route.params.personId),
        callApi.config(),
      ]);
      const rate = type === 'audio' ? profile.audioPricePerMinute : profile.videoPricePerMinute;
      Alert.alert(
        `${type === 'audio' ? 'Audio' : 'Video'} call`,
        'Choose a duration and coin amount.',
        [
          { text: 'Cancel', style: 'cancel' },
          ...config.durationOptions.map((minutes) => ({
            text: `${minutes} min · up to ${rate * minutes} coins`,
            onPress: () =>
              void callApi
                .requestPaid(route.params.personId, type, minutes)
                .then(({ data }) =>
                  navigation.navigate(type === 'audio' ? 'AudioCall' : 'VideoCall', {
                    name: route.params.name,
                    callId: data.id,
                    chatId: route.params.chatId,
                    personId: route.params.personId,
                  }),
                )
                .catch((error) =>
                  showPurchasePrompt(error.message || 'You need an active plan and enough coins.'),
                ),
          })),
        ],
      );
    } catch (error: any) {
      showPurchasePrompt(error.message || 'You need an active plan and enough coins.');
    }
  };

  const doSend = async () => {
    try {
      await sendMessage(
        route.params.chatId,
        text,
        attachment || undefined,
        replyTo || undefined,
      );
      realtime.sendTyping(false);
      setText('');
      setAttachment(null);
      setReplyTo(null);
      setTimeout(() => {
        refreshLimits();
        refreshWallet();
      }, 500);
    } catch (err: any) {
      Alert.alert('Send failed', err.message || 'Could not send message.');
    }
  };

  const handleSend = () => {
    if (!text.trim() && !attachment) return;
    if (!canSend) {
      showPurchasePrompt('Your access limit is complete.');
      return;
    }

    const interval = chatLimit?.chatMessageDeductionInterval || 0;
    const cost = chatLimit?.chatCoinsPerMessage || 0;
    const count = chatLimit?.conversationMessageUsed || 0;

    const isThreshold = interval > 0 && cost > 0 && (count + 1) % interval === 0;
    const chatId = route.params.chatId;

    if (isThreshold) {
      const currentBal = balance || 0;
      if (currentBal < cost) {
        Alert.alert(
          'Out of coins! 🪙',
          `This message costs ${cost} coins, but your balance is only ${currentBal} coins. Please buy more coins to send.`,
          [
            { text: 'Buy Coins', onPress: () => navigation.navigate('SubscriptionPlans') },
            { text: 'Cancel', style: 'cancel' }
          ]
        );
        return;
      }

      if (!confirmedChats[chatId]) {
        Alert.alert(
          'Confirm Coin Deduction 🪙',
          `Sending this message will deduct ${cost} coins. Do you want to proceed?`,
          [
            { text: 'Cancel', style: 'cancel' },
            {
              text: 'Proceed',
              onPress: () => {
                confirmedChats[chatId] = true;
                void doSend();
              }
            }
          ]
        );
      } else {
        void doSend();
      }
    } else {
      void doSend();
    }
  };

  return (
    <Screen scroll={false}>
      <KeyboardAvoidingView
        style={{ flex: 1 }}
        behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
        keyboardVerticalOffset={0}
      >
        <View style={styles.chatHeader}>
          <IconButton icon="arrow-back" onPress={() => navigation.goBack()} />
          <Avatar name={route.params.name} online size={42} uri={route.params.avatarUrl || route.params.avatarUri} />
          <Pressable
            style={{ flex: 1 }}
            onPress={() => navigation.navigate('ChatInfo', route.params)}
          >
            <Text style={styles.cardTitle}>{route.params.name}</Text>
            <Text style={styles.onlineText}>
              {realtime.typing
                ? 'Typing...'
                : realtime.connected
                  ? realtime.online
                    ? 'Online · live'
                    : 'Connected · live'
                  : 'Reconnecting...'}
            </Text>
          </Pressable>
          <IconButton icon="call-outline" onPress={() => void requestCall('audio')} />
          <IconButton icon="videocam-outline" onPress={() => void requestCall('video')} />
          {route.params.matchId && (
            <IconButton
              icon="stop-circle-outline"
              onPress={() =>
                Alert.alert('End this Connect session?', 'You can leave private feedback next.', [
                  { text: 'Continue chat', style: 'cancel' },
                  {
                    text: 'End session',
                    style: 'destructive',
                    onPress: () =>
                      navigation.replace('SessionFeedback', {
                        matchId: route.params.matchId,
                        personId: route.params.personId,
                      }),
                  },
                ])
              }
            />
          )}
        </View>
        {sessionSeconds !== null && (
          <View style={styles.connectTimer}>
            <Ionicons name="timer-outline" size={18} color={colors.primary} />
            <Text style={styles.connectTimerText}>
              {String(Math.floor(sessionSeconds / 60)).padStart(2, '0')}:
              {String(sessionSeconds % 60).padStart(2, '0')} focused Connect
            </Text>
          </View>
        )}
        {chatLimit && chatLimit.chatCoinsPerMessage && chatLimit.chatCoinsPerMessage > 0 ? (
          <LinearGradient
            colors={['#FFF9E6', '#FFF0D0']}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 0 }}
            style={{
              flexDirection: 'row',
              alignItems: 'center',
              justifyContent: 'space-between',
              paddingVertical: 10,
              paddingHorizontal: 16,
              borderBottomWidth: 1,
              borderBottomColor: '#FFE0B2',
            }}
          >
            <View style={{ flexDirection: 'row', alignItems: 'center', flex: 1, marginRight: 8 }}>
              <View style={{
                backgroundColor: '#FF9800',
                borderRadius: 12,
                width: 28,
                height: 28,
                alignItems: 'center',
                justifyContent: 'center',
                marginRight: 10
              }}>
                <Ionicons name="logo-bitcoin" size={16} color="#fff" />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={{ fontSize: 13, fontWeight: '800', color: '#E65100' }}>
                  Paid Chat Active 🪙
                </Text>
                <Text style={{ fontSize: 11, color: '#F57C00', fontWeight: '600', marginTop: 1 }}>
                  Costs {chatLimit.chatCoinsPerMessage} coins every {chatLimit.chatMessageDeductionInterval} messages
                </Text>
              </View>
            </View>
            <View style={{
              backgroundColor: '#FFE0B2',
              borderRadius: 20,
              paddingHorizontal: 10,
              paddingVertical: 4,
              flexDirection: 'row',
              alignItems: 'center',
              gap: 4
            }}>
              <Text style={{ fontSize: 11, fontWeight: '800', color: '#E65100' }}>
                {balance !== null ? `${balance} 🪙` : '...'}
              </Text>
            </View>
          </LinearGradient>
        ) : null}
        <ScrollView
          ref={chatScrollRef}
          style={styles.chatBody}
          contentContainerStyle={styles.chatBodyContent}
          keyboardShouldPersistTaps="handled"
          onContentSizeChange={() => scrollToLatestMessage(false)}
          onLayout={() => scrollToLatestMessage(false)}
        >
          <View style={styles.chatNotice}>
            <Ionicons name="shield-checkmark" color={colors.success} />
            <Text style={styles.smallMuted}>
              Be respectful. Block and report are always available.
            </Text>
          </View>
          {chatLimit && (
            <Pressable
              onPress={() => navigation.navigate('SubscriptionPlans', { source: 'chat_limit' })}
              style={styles.chatNotice}
            >
              <Ionicons name="sparkles-outline" color={colors.primary} />
              <Text style={styles.smallMuted}>
                {chatLimit.subscriptionActive
                  ? 'Subscription active · this paid chat is available'
                  : 'Keep enough coins available for paid chat minutes'}
              </Text>
            </Pressable>
          )}
          {accessExpired && (
            <LinearGradient colors={['#FFF0F6', '#F3EFFF']} style={styles.accessGate}>
              <View style={styles.accessGateIcon}>
                <Ionicons name="lock-closed" size={22} color="#fff" />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.accessGateTitle}>Your chat time is complete</Text>
                <Text style={styles.accessGateText}>
                  Start another paid chat session to continue.
                </Text>
              </View>
              <Pressable
                onPress={() => navigation.navigate('SubscriptionPlans', { source: 'chat_limit' })}
                style={styles.accessGateButton}
              >
                <Text style={styles.accessGateButtonText}>View options</Text>
                <Ionicons name="arrow-forward" size={14} color="#fff" />
              </Pressable>
            </LinearGradient>
          )}
          {!!realtime.error && !!list.length && (
            <Pressable style={styles.inlineError} onPress={() => void realtime.retry()}>
              <Ionicons name="cloud-offline-outline" color={colors.danger} />
              <Text style={styles.inlineErrorText}>{realtime.error} · Tap to retry</Text>
            </Pressable>
          )}
          {realtime.loading && !list.length ? (
            <ChatSkeleton />
          ) : realtime.error && !list.length ? (
            <EmptyState
              icon="cloud-offline-outline"
              title="Messages could not load"
              text={realtime.error}
              action="Try again"
              onAction={() => void realtime.retry()}
            />
          ) : list.length ? (
            <>
              <Button
                title={realtime.loadingOlder ? 'Loading...' : 'Load older messages'}
                compact
                tone="ghost"
                onPress={() => void realtime.loadOlder()}
              />
              {list.map((message) => (
                <Pressable
                  key={message.id}
                  style={[styles.bubble, message.mine ? styles.mine : styles.theirs]}
                  onLongPress={() =>
                    Alert.alert('Message actions', 'Choose an action.', [
                      { text: 'Reply', onPress: () => setReplyTo(message) },
                      {
                        text: 'React',
                        onPress: () =>
                          Alert.alert(
                            'React',
                            undefined,
                            ['❤️', '😂', '🔥', '👍'].map((emoji) => ({
                              text: emoji,
                              onPress: () =>
                                void chatApi.react(message.id, emoji).then(({ data }) =>
                                  useAppStore.setState((state) => ({
                                    messages: state.messages.map((item) =>
                                      item.id === message.id
                                        ? { ...item, reactions: data.reactions }
                                        : item,
                                    ),
                                  })),
                                ),
                            })),
                          ),
                      },
                      ...(message.mine
                        ? [
                            {
                              text: 'Delete',
                              style: 'destructive' as const,
                              onPress: () =>
                                void chatApi.deleteMessage(message.id).then(() =>
                                  useAppStore.setState((state) => ({
                                    messages: state.messages.map((item) =>
                                      item.id === message.id
                                        ? {
                                            ...item,
                                            text: '',
                                            attachment: undefined,
                                            deleted: true,
                                          }
                                        : item,
                                    ),
                                  })),
                                ),
                            },
                          ]
                        : []),
                      { text: 'Cancel', style: 'cancel' },
                    ])
                  }
                >
                  {message.replyToId && (
                    <View style={styles.replyQuote}>
                      <Text style={styles.smallMuted}>Reply to a previous message</Text>
                    </View>
                  )}
                  {message.attachment && (
                    <Pressable
                      onPress={() =>
                        navigation.navigate('MediaPreview', { attachment: message.attachment })
                      }
                      style={styles.messageAttachment}
                    >
                      {message.attachment.kind === 'image' ? (
                        <Image
                          source={{ uri: message.attachment.uri }}
                          style={styles.messageImage}
                        />
                      ) : (
                        <View style={styles.fileAttachment}>
                          <Ionicons
                            name="document-text"
                            size={25}
                            color={message.mine ? '#fff' : colors.primary}
                          />
                          <View style={{ flex: 1 }}>
                            <Text
                              style={[styles.fileName, message.mine && { color: '#fff' }]}
                              numberOfLines={1}
                            >
                              {message.attachment.name}
                            </Text>
                            <Text
                              style={[
                                styles.bubbleTime,
                                message.mine && { color: 'rgba(255,255,255,.72)' },
                              ]}
                            >
                              {formatFileSize(message.attachment.size)}
                            </Text>
                          </View>
                        </View>
                      )}
                    </Pressable>
                  )}
                  {message.deleted ? (
                    <Text style={[styles.smallMuted, message.mine && { color: '#fff' }]}>
                      This message was deleted
                    </Text>
                  ) : (
                    !!message.text && (
                      <Text style={[ui.body, message.mine && { color: '#fff' }]}>
                        {message.text}
                      </Text>
                    )
                  )}
                  {!!Object.keys(message.reactions || {}).length && (
                    <Text style={styles.messageReactions}>
                      {Object.values(message.reactions || {}).join(' ')}
                    </Text>
                  )}
                  {!!message.safetyFlags?.length && (
                    <Text style={styles.smallMuted}>
                      ⚠ This message may contain a{' '}
                      {message.safetyFlags.join(' or ').replaceAll('_', ' ')}. Share personal
                      information carefully.
                    </Text>
                  )}
                  <Text
                    style={[styles.bubbleTime, message.mine && { color: 'rgba(255,255,255,.72)' }]}
                  >
                    {message.time}
                    {message.mine ? ` · ${message.status || 'sent'}` : ''}
                  </Text>
                </Pressable>
              ))}
            </>
          ) : (
            <EmptyState
              icon="chatbubble"
              title="Start the conversation"
              text="Say hello and mention why you wanted to connect."
            />
          )}
          {realtime.typing && (
            <Text style={styles.typingText}>{route.params.name} is typing...</Text>
          )}
        </ScrollView>
        {attachment && (
          <View style={styles.pendingAttachment}>
            {attachment.kind === 'image' ? (
              <Image source={{ uri: attachment.uri }} style={styles.pendingImage} />
            ) : (
              <Ionicons name="document-text" size={28} color={colors.primary} />
            )}
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle} numberOfLines={1}>
                {attachment.name}
              </Text>
              <Text style={styles.smallMuted}>
                {formatFileSize(attachment.size)} · Ready to send
              </Text>
            </View>
            <IconButton icon="close" onPress={() => setAttachment(null)} />
          </View>
        )}
        {replyTo && (
          <View style={styles.pendingReply}>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>
                Replying to {replyTo.mine ? 'your message' : route.params.name}
              </Text>
              <Text style={styles.smallMuted} numberOfLines={1}>
                {replyTo.text || replyTo.attachment?.name}
              </Text>
            </View>
            <IconButton icon="close" onPress={() => setReplyTo(null)} />
          </View>
        )}
        {blocked ? (
          <View style={styles.blockedComposer}>
            <Ionicons name="ban-outline" size={20} color={colors.danger} />
            <Text style={styles.smallMuted}>
              Messaging is unavailable while this user is blocked.
            </Text>
          </View>
        ) : (
          <View style={styles.composer}>
            <IconButton
              icon="add"
              onPress={() =>
                Alert.alert('Add attachment', 'Choose what you want to send.', [
                  { text: 'Cancel', style: 'cancel' },
                  { text: 'Photo', onPress: async () => setAttachment(await pickImage()) },
                  { text: 'File', onPress: async () => setAttachment(await pickDocument()) },
                ])
              }
            />
            <TextInput
              value={text}
              onChangeText={(value) => {
                setText(value);
                realtime.sendTyping(Boolean(value.trim()));
              }}
              placeholder="Write a message..."
              placeholderTextColor={colors.muted}
              multiline
              style={styles.composerInput}
            />
            <Pressable
              onPress={handleSend}
              disabled={!text.trim() && !attachment}
              style={[
                styles.send,
                ((!text.trim() && !attachment) || !canSend) && { opacity: 0.45 },
              ]}
            >
              <Ionicons name="send" size={20} color="#fff" />
            </Pressable>
          </View>
        )}
      </KeyboardAvoidingView>
    </Screen>
  );
}

export default PrivateChatScreen;
