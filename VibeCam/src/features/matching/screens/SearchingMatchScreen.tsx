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

export function SearchingMatchScreen({ navigation, route }: any) {
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [seconds, setSeconds] = useState(0);
  const [matchId, setMatchId] = useState(route.params.matchId || '');
  const [searchState, setSearchState] = useState<'searching' | 'expired' | 'error'>('searching');
  useEffect(() => {
    const clock = setInterval(() => setSeconds((x) => x + 1), 1000);
    let active = true;
    const openFound = (data: any) => {
      if (!active || !data?.other_user_id || !['found', 'waiting'].includes(data.status)) return;
      navigation.replace('MatchFound', {
        matchId: data.id,
        personId: data.other_user_id,
        anonymous: data.anonymous,
        score: data.score,
        reasons: data.reasons || [],
        purpose: data.purpose,
        language: data.language,
        sessionMinutes: data.session_minutes || 10,
        alreadyAccepted: data.accepted_by?.includes(currentUserId),
      });
    };
    const poll = async () => {
      try {
        const { data } = await matchingApi.status();
        if (!active || !data) return;
        setMatchId(data.id);
        if (data.status === 'expired') setSearchState('expired');
        else openFound(data);
      } catch {
        if (active) setSearchState('error');
      }
    };
    void matchingApi
      .start({
        purpose: route.params.purpose,
        language: route.params.language,
        min_age: route.params.minAge,
        max_age: route.params.maxAge,
        anonymous: route.params.anonymous,
        session_minutes: route.params.sessionMinutes,
      })
      .then(({ data }) => {
        if (!active) return;
        setMatchId(data.id);
        openFound(data);
      })
      .catch(() => active && setSearchState('error'));
    const polling = setInterval(() => void poll(), 2000);
    return () => {
      active = false;
      clearInterval(clock);
      clearInterval(polling);
    };
  }, [navigation, route.params]);
  return (
    <Screen scroll={false} style={{ padding: 22 }}>
      <View style={styles.searching}>
        <View style={styles.radar}>
          <View style={styles.radarInner}>
            <Ionicons name="search" size={40} color="#fff" />
          </View>
        </View>
        <Text style={[ui.title, { textAlign: 'center' }]}>
          {searchState === 'expired'
            ? 'No relevant person is available yet'
            : searchState === 'error'
              ? 'Search temporarily unavailable'
              : 'Finding the right vibe...'}
        </Text>
        <Text style={[ui.body, styles.centerText]}>
          Looking for {route.params.purpose} ·{' '}
          {route.params.anonymous ? 'Anonymous' : 'Social profile'}
        </Text>
        <Pill label={`${seconds}s`} selected />
        {searchState !== 'searching' && (
          <Button
            title="Try again"
            onPress={() => navigation.replace('SearchingMatch', route.params)}
          />
        )}
        <Button
          title="Cancel search"
          tone="secondary"
          onPress={() => {
            if (matchId) void matchingApi.action(matchId, 'cancel').catch(() => undefined);
            navigation.goBack();
          }}
        />
      </View>
    </Screen>
  );
}

export default SearchingMatchScreen;
