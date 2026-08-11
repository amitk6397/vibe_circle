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

export function PrivateCirclesScreen({ navigation }: any) {
  const allCommunities = useAppStore((state) => state.communities);
  const circles = allCommunities.filter((item) => item.kind === 'circle' && item.joined);
  return (
    <Screen>
      <Header
        title="Private circles"
        subtitle="Small trusted spaces that only members can see"
        onBack={() => navigation.goBack()}
        right={<IconButton icon="add" onPress={() => navigation.navigate('CreateCircle')} />}
      />
      <Button
        title="Circle invitations"
        tone="secondary"
        icon="mail-unread-outline"
        onPress={() => navigation.navigate('CircleInvites')}
      />
      {circles.length ? (
        circles.map((circle) => (
          <CommunityCard
            key={circle.id}
            community={circle}
            onPress={() => navigation.navigate('CommunityDetails', { communityId: circle.id })}
          />
        ))
      ) : (
        <EmptyState
          icon="people-circle-outline"
          title="No private circles yet"
          text="Create an invite-only space for close friends, study partners or support."
          action="Create circle"
          onAction={() => navigation.navigate('CreateCircle')}
        />
      )}
    </Screen>
  );
}

export default PrivateCirclesScreen;
