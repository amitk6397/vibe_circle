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
import { navigateFromPush } from '../../../navigation/navigationRef';

export function NotificationsScreen({ navigation }: any) {
  const [items, setItems] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    void notificationsApi
      .list()
      .then(({ data }) => setItems(data))
      .catch((error) => Alert.alert('Notifications unavailable', error.message))
      .finally(() => setLoading(false));
  }, []);
  const removeNotification = (item: any) => {
    Alert.alert('Delete notification?', 'This notification will be removed permanently.', [
      { text: 'Cancel', style: 'cancel' },
      {
        text: 'Delete',
        style: 'destructive',
        onPress: () => {
          setItems((current) => current.filter((entry) => entry.id !== item.id));
          void notificationsApi.remove(item.id).catch((error) => {
            setItems((current) => [item, ...current]);
            Alert.alert('Delete failed', error.message || 'Please try again.');
          });
        },
      },
    ]);
  };
  return (
    <Screen>
      <Header
        title="Notifications"
        onBack={() => navigation.goBack()}
        right={
          <Pressable
            onPress={() => {
              useAppStore.getState().markNotificationsRead();
              setItems((current) => current.map((item) => ({ ...item, is_read: true })));
            }}
          >
            <Text style={styles.link}>Read all</Text>
          </Pressable>
        }
      />
      {items.length ? (
        items.map((item) => (
          <Card
            key={item.id}
            style={[styles.listRow, !item.is_read && { borderColor: colors.primary }]}
            onPress={() => {
              if (!item.is_read) {
                void notificationsApi.markRead(item.id);
                setItems((current) =>
                  current.map((currentItem) =>
                    currentItem.id === item.id ? { ...currentItem, is_read: true } : currentItem,
                  ),
                );
              }
              navigateFromPush({ type: item.type, ...item.data });
            }}
          >
            <View style={styles.notificationIcon}>
              <Ionicons name="notifications" color={colors.primary} size={21} />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>{item.title}</Text>
              <Text style={ui.body}>{item.body}</Text>
              <Text style={styles.smallMuted}>Recent</Text>
            </View>
            <Pressable
              accessibilityRole="button"
              accessibilityLabel="Delete notification"
              onPress={() => removeNotification(item)}
              style={styles.notificationDelete}
            >
              <Ionicons name="trash-outline" size={18} color={colors.danger} />
            </Pressable>
          </Card>
        ))
      ) : loading ? (
        <Text style={ui.muted}>Loading notifications...</Text>
      ) : (
        <EmptyState
          icon="checkmark-circle"
          title="All caught up"
          text="New connection, message, room, and system alerts will appear here."
        />
      )}
    </Screen>
  );
}

export default NotificationsScreen;
