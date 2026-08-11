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

export function ConnectSetupScreen({ navigation }: any) {
  const store = useAppStore();
  const [purpose, setPurpose] = useState(store.selectedPurpose);
  const [anonymous, setAnonymous] = useState(store.anonymousMode);
  const [language, setLanguage] = useState('English');
  const [ageRange, setAgeRange] = useState('18-35');
  const [sessionMinutes, setSessionMinutes] = useState<10 | 20>(10);
  const ageRangeValid = /^\s*(1[89]|[2-9]\d)\s*-\s*(1[89]|[2-9]\d)\s*$/.test(ageRange);
  return (
    <Screen>
      <Header
        title="Set up your connection"
        subtitle="Choose what feels right today."
        onBack={() => navigation.goBack()}
      />
      <Text style={ui.h2}>I want to...</Text>
      <View style={ui.wrap}>
        {PURPOSES.map((x) => (
          <Pill
            key={x.name}
            label={x.name}
            selected={purpose === x.name}
            onPress={() => setPurpose(x.name)}
            color={x.color}
          />
        ))}
      </View>
      <Text style={ui.h2}>Conversation language</Text>
      <View style={ui.wrap}>
        {LANGUAGES.slice(0, 5).map((x) => (
          <Pill key={x} label={x} selected={language === x} onPress={() => setLanguage(x)} />
        ))}
      </View>
      <Field
        label="Preferred age range"
        value={ageRange}
        onChangeText={setAgeRange}
        placeholder="18-35"
        keyboardType="numbers-and-punctuation"
        error={!ageRangeValid ? 'Use a range like 18-35' : undefined}
      />
      <Card style={styles.listRow}>
        <View style={{ flex: 1 }}>
          <Text style={styles.cardTitle}>Anonymous mode</Text>
          <Text style={styles.smallMuted}>Hide your social profile during this conversation.</Text>
        </View>
        <Switch
          value={anonymous}
          onValueChange={setAnonymous}
          trackColor={{ true: colors.primary }}
        />
      </Card>
      <Text style={ui.h2}>Conversation length</Text>
      <View style={ui.wrap}>
        <Pill
          label="10-minute Connect"
          selected={sessionMinutes === 10}
          onPress={() => setSessionMinutes(10)}
        />
        <Pill
          label="20 minutes"
          selected={sessionMinutes === 20}
          onPress={() => setSessionMinutes(20)}
        />
      </View>
      <Text style={styles.smallMuted}>
        A focused session ends automatically. You can follow each other afterwards.
      </Text>
      <Button
        title="Find someone to talk with"
        icon="search"
        disabled={!ageRangeValid}
        onPress={() => {
          const [, minimum, maximum] = ageRange.match(/(\d+)\s*-\s*(\d+)/) || [];
          store.selectPurpose(purpose);
          store.setAnonymousMode(anonymous);
          navigation.navigate('SearchingMatch', {
            purpose,
            anonymous,
            language,
            minAge: Number(minimum),
            maxAge: Number(maximum),
            sessionMinutes,
          });
        }}
      />
    </Screen>
  );
}

export default ConnectSetupScreen;
