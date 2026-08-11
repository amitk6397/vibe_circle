import React, { useCallback, useEffect, useRef, useState } from 'react';

import { useFocusEffect } from '@react-navigation/native';

import { useSafeAreaInsets } from 'react-native-safe-area-context';

import {
  ActivityIndicator,
  Alert,
  Animated,
  Dimensions,
  Image,
  Modal,
  PanResponder,
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
  matchingApi,
  notificationsApi,
  safetyApi,
  storyApi,
  uploadAttachment,
  usersApi,
} from '../../../services/api';

import { useInboxSync, usePrivateRealtime } from '../../chat/viewmodels/useRealtimeChat';

import { styles } from '../../shared-views/styles';

export function InboxScreen({ navigation }: any) {
  const chats = useAppStore((s) => s.chats);
  const communities = useAppStore((state) => state.communities);
  const joinedIds = useAppStore((state) => state.joinedCommunities);
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [inboxTab, setInboxTab] = useState<'chats' | 'groups'>('chats');
  const { loading, error, refresh } = useInboxSync();

  const [pendingFollowCount, setPendingFollowCount] = useState(0);
  const [pendingMsgCount, setPendingMsgCount] = useState(0);
  const [hasPaid, setHasPaid] = useState(false);
  const [hasArchived, setHasArchived] = useState(false);

  const loadCounts = useCallback(async () => {
    if (!currentUserId) return;
    try {
      // 1. Follow Requests
      const connResult = await usersApi.connections();
      const pendingFollows = (connResult.data || []).filter(
        (item) => item.status === 'pending' && item.receiver_id === currentUserId
      );
      setPendingFollowCount(pendingFollows.length);

      // 2. Message Requests
      const msgResult = await chatApi.messageRequests();
      const pendingMsgs = (msgResult.data || []).filter((x) => x.status === 'pending');
      setPendingMsgCount(pendingMsgs.length);

      // 3. Paid sessions
      const paidResult = await chatApi.conversations('paid');
      setHasPaid((paidResult.data || []).length > 0);

      // 4. Archived
      const archivedResult = await chatApi.conversations('archived');
      setHasArchived((archivedResult.data || []).length > 0);
    } catch {
      // Ignore
    }
  }, [currentUserId]);

  useFocusEffect(
    useCallback(() => {
      void refresh();
      void loadCounts();
    }, [refresh, loadCounts])
  );

  const totalUnreadChats = chats.reduce((s, c) => s + (c.unread || 0), 0);

  return (
    <Screen scroll={false} edges={['top', 'left', 'right']}>
      <View style={styles.topRow}>
        <View>
          <Text style={styles.eyebrow}>YOUR CONVERSATIONS</Text>
          <Text style={ui.title}>Inbox</Text>
        </View>
        <IconButton icon="create-outline" onPress={() => navigation.navigate('DiscoverPeople')} />
      </View>
      <ScrollView style={{ flex: 1 }} showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 18, gap: 16 }}>
        <View style={ui.wrap}>
          <Pill
            label={`Chats${totalUnreadChats > 0 ? ` (${totalUnreadChats})` : ''}`}
            selected={inboxTab === 'chats'}
            onPress={() => setInboxTab('chats')}
          />
          <Pill
            label="Groups"
            selected={inboxTab === 'groups'}
            onPress={() => setInboxTab('groups')}
          />
          <Pill
            label={`Follow Requests${pendingFollowCount > 0 ? ` (${pendingFollowCount})` : ''}`}
            onPress={() => navigation.navigate('ConnectionRequest')}
          />
          <Pill
            label={`Msg Requests${pendingMsgCount > 0 ? ` (${pendingMsgCount})` : ''}`}
            onPress={() => navigation.navigate('MessageRequests')}
          />
          {hasPaid && (
            <Pill
              label="Paid sessions"
              onPress={() => navigation.navigate('PaidSessions')}
            />
          )}
          {hasArchived && (
            <Pill
              label="Archived"
              onPress={() => navigation.navigate('ArchivedChats')}
            />
          )}
        </View>
        {loading && !chats.length && <ChatSkeleton rows={4} />}
        {!!error && (
          <Card>
            <Text style={styles.errorText}>{error}</Text>
            <Button title="Try again" compact tone="secondary" onPress={() => void refresh()} />
          </Card>
        )}
        {inboxTab === 'chats' &&
          chats.map((chat) => (
            <Card
              key={chat.id}
              onPress={() =>
                navigation.navigate('PrivateChat', {
                  chatId: chat.id,
                  name: chat.name,
                  personId: chat.personId,
                  avatarUrl: chat.avatarUrl,
                })
              }
              style={styles.listRow}
            >
              <Avatar name={chat.name} online={chat.online} uri={chat.avatarUrl || undefined} />
              <View style={{ flex: 1 }}>
                <Text style={styles.cardTitle}>{chat.name}</Text>
                <Text style={styles.smallMuted} numberOfLines={1}>
                  {chat.preview}
                </Text>
              </View>
              <View style={{ alignItems: 'flex-end', gap: 7 }}>
                <Text style={styles.time}>{chat.time}</Text>
                {chat.unread > 0 && (
                  <View style={styles.unread}>
                    <Text style={styles.unreadText}>{chat.unread}</Text>
                  </View>
                )}
              </View>
            </Card>
          ))}
        {inboxTab === 'groups' &&
          communities
            .filter((item) => joinedIds.includes(item.id))
            .map((community) => (
              <CommunityCard
                key={community.id}
                community={community}
                onPress={() => navigation.navigate('CommunityChat', { communityId: community.id })}
              />
            ))}
        {inboxTab === 'groups' && !communities.some((item) => joinedIds.includes(item.id)) && (
          <EmptyState
            icon="people-outline"
            title="No group chats"
            text="Join a community to see its group chat here."
          />
        )}
      </ScrollView>
    </Screen>
  );
}

export default InboxScreen;
