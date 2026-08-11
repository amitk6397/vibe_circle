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

export function MyCommunitiesScreen({ navigation }: any) {
  const allCommunities = useAppStore((state) => state.communities);
  const communities = allCommunities.filter((item) => item.isOwner);
  return (
    <Screen>
      <Header
        title="My communities"
        subtitle="Communities created and managed by you"
        onBack={() => navigation.goBack()}
        right={<IconButton icon="add" onPress={() => navigation.navigate('CreateCommunity')} />}
      />
      {communities.length ? (
        communities.map((community) => (
          <CommunityCard
            key={community.id}
            community={community}
            onPress={() => navigation.navigate('CommunityDetails', { communityId: community.id })}
          />
        ))
      ) : (
        <EmptyState
          icon="people-circle-outline"
          title="No community created yet"
          text="Create your first community and bring people together."
          action="Create community"
          onAction={() => navigation.navigate('CreateCommunity')}
        />
      )}
    </Screen>
  );
}

export default MyCommunitiesScreen;
