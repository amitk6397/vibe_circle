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

export function MatchFoundScreen({ navigation, route }: any) {
  const person = useAppStore((state) => state.people.find((x) => x.id === route.params.personId));
  const [waitingForOther, setWaitingForOther] = useState(Boolean(route.params.alreadyAccepted));
  const [accepting, setAccepting] = useState(false);
  useEffect(() => {
    const polling = setInterval(() => {
      void matchingApi.status().then(({ data }) => {
        if (waitingForOther && data?.status === 'accepted' && data.conversation_id) {
          clearInterval(polling);
          navigation.replace('PrivateChat', {
            chatId: data.conversation_id,
            name: route.params.anonymous
              ? 'Anonymous listener'
              : person?.name || 'Suggested person',
            personId: route.params.personId,
            matchId: route.params.matchId,
            anonymous: route.params.anonymous,
            sessionEndsAt: data.session_ends_at,
          });
        } else if (['rejected', 'skipped', 'expired', 'cancelled'].includes(data?.status)) {
          clearInterval(polling);
          Alert.alert('Connection ended', 'The other person did not accept this conversation.');
          navigation.replace('ConnectSetup');
        }
      });
    }, 1500);
    return () => clearInterval(polling);
  }, [navigation, person?.name, route.params.anonymous, route.params.personId, waitingForOther]);
  if (!person)
    return (
      <Screen>
        <Header title="Suggested connection" onBack={() => navigation.goBack()} />
        <EmptyState
          title="Connection unavailable"
          text="This suggestion expired. Start a new search."
        />
      </Screen>
    );
  return (
    <Screen>
      <Header
        title="Suggested connection"
        subtitle="You both choose whether to connect"
        onBack={() => navigation.goBack()}
      />
      <View style={styles.profileHero}>
        <Avatar
          name={route.params.anonymous ? 'Anonymous listener' : person.name}
          color={person.avatarColor}
          size={105}
          online
        />
        <Text style={ui.title}>{route.params.anonymous ? 'Safe listener' : person.name}</Text>
        <Text style={styles.handle}>
          Recommended for you · {route.params.language} ·{' '}
          {person.online ? 'Online now' : 'Recently active'}
        </Text>
        <Text style={[styles.handle, { display: 'none' }]}>
          Suggested connection · English · {person.online ? 'Online now' : 'Recently active'}
        </Text>
      </View>
      <Card>
        <Text style={styles.eyebrow}>WHY THIS PERSON IS RELEVANT</Text>
        <View style={ui.wrap}>
          {(route.params.reasons || []).map((reason: string, index: number) => (
            <Pill key={`${reason}-${index}`} label={reason} selected={index === 0} />
          ))}
        </View>
        <Text style={[ui.body, { marginTop: 12 }]}>
          {route.params.anonymous
            ? 'Profile details stay hidden until you choose otherwise.'
            : person.bio}
        </Text>
      </Card>
      <Card>
        <Text style={styles.eyebrow}>CONVERSATION STARTER</Text>
        <Text style={ui.body}>
          {route.params.purpose === 'Learn'
            ? 'What are you learning or curious about right now?'
            : route.params.purpose === 'Advice'
              ? 'What would you like another perspective on?'
              : route.params.purpose === 'Friends'
                ? 'What do you enjoy doing in your free time?'
                : 'How has your day been so far?'}
        </Text>
      </Card>
      <Button
        title={waitingForOther ? 'Waiting for the other person...' : 'Accept connection'}
        icon="checkmark"
        loading={accepting}
        disabled={waitingForOther}
        onPress={() => {
          if (!route.params.matchId) return;
          setAccepting(true);
          void matchingApi
            .action(route.params.matchId, 'accept')
            .then(({ data }) => {
              if (data.status === 'accepted' && data.conversation_id)
                navigation.replace('PrivateChat', {
                  chatId: data.conversation_id,
                  name: route.params.anonymous ? 'Anonymous listener' : person.name,
                  personId: person.id,
                  matchId: route.params.matchId,
                  anonymous: route.params.anonymous,
                  sessionEndsAt: data.session_ends_at,
                });
              else setWaitingForOther(true);
            })
            .catch((error) => Alert.alert('Could not accept connection', error.message))
            .finally(() => setAccepting(false));
        }}
      />
      <Button
        title="Skip safely"
        tone="secondary"
        onPress={() => {
          if (route.params.matchId)
            void matchingApi.action(route.params.matchId, 'skip').catch(() => undefined);
          navigation.replace('ConnectSetup');
        }}
      />
    </Screen>
  );
}

export default MatchFoundScreen;
