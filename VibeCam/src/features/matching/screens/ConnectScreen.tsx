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

export function ConnectScreen({ navigation }: any) {
  const selected = useAppStore((s) => s.selectedPurpose);
  const vibeStatus = useAppStore((state) => state.profile.vibeStatus);
  return (
    <Screen>
      <View style={styles.connectHero}>
        <View style={styles.connectIcon}>
          <Ionicons name="radio" size={46} color="#fff" />
        </View>
        <Text style={[ui.title, { textAlign: 'center' }]}>Instant Connect</Text>
        <Text style={[ui.body, styles.centerText]}>
          Both people accept before a private conversation starts. You stay in control.
        </Text>
      </View>
      <Card>
        <Text style={styles.eyebrow}>CURRENT PURPOSE</Text>
        <Text style={ui.h2}>{selected}</Text>
        <Text style={styles.smallMuted}>English · Ages 18–35 · Available now</Text>
      </Card>

      <Button
        title="Set up a connection"
        icon="options"
        onPress={() => navigation.navigate('ConnectSetup')}
      />
      <View style={styles.safety}>
        <Ionicons name="shield-checkmark" size={22} color={colors.success} />
        <Text style={[styles.smallMuted, { flex: 1 }]}>
          Blocked and restricted accounts are excluded. Private conversation content is never used
          for relevant suggestions.
        </Text>
      </View>
    </Screen>
  );
}

export default ConnectScreen;
