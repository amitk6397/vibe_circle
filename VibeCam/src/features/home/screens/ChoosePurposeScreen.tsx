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

export function ChoosePurposeScreen({ navigation }: any) {
  const selected = useAppStore((s) => s.selectedPurpose);
  return (
    <Screen>
      <Header
        title="Choose your purpose"
        subtitle="You can change this anytime."
        onBack={() => navigation.goBack()}
      />
      <View style={{ gap: 10 }}>
        {PURPOSES.map((item) => (
          <Card
            key={item.name}
            onPress={() => useAppStore.getState().selectPurpose(item.name)}
            style={[
              styles.listRow,
              selected === item.name && { borderColor: item.color, borderWidth: 2 },
            ]}
          >
            <View style={[styles.purposeIcon, { backgroundColor: item.color }]}>
              <Ionicons name={item.icon as any} size={21} color="#fff" />
            </View>
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>{item.name}</Text>
              <Text style={styles.smallMuted}>{item.subtitle}</Text>
            </View>
            {selected === item.name && (
              <Ionicons name="checkmark-circle" size={24} color={item.color} />
            )}
          </Card>
        ))}
      </View>
      <Button
        title="Show my recommendations"
        onPress={() => navigation.replace('Main', { screen: 'Discover' })}
      />
    </Screen>
  );
}

export default ChoosePurposeScreen;
