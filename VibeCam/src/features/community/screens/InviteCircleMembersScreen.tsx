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

import { ProfileScreen } from '../../profile/screens/ProfileScreen';

import { MyCreationsScreen } from '../../profile/screens/MyCreationsScreen';

export function InviteCircleMembersScreen({ navigation, route }: any) {
  const people = useAppStore((state) => state.people);
  const [invited, setInvited] = useState<string[]>([]);
  const [query, setQuery] = useState('');
  const visible = people.filter((person) =>
    `${person.name} ${person.username}`.toLowerCase().includes(query.toLowerCase()),
  );
  return (
    <Screen>
      <Header
        title="Invite trusted people"
        subtitle="They must accept before the circle becomes visible."
        onBack={() => navigation.goBack()}
      />
      <SearchField value={query} onChangeText={setQuery} placeholder="Search people" />
      {visible.map((person) => (
        <Card key={person.id} style={styles.listRow}>
          <Avatar name={person.name} color={person.avatarColor} size={48} />
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>{person.name}</Text>
            <Text style={styles.smallMuted}>@{person.username}</Text>
          </View>
          <Button
            title={invited.includes(person.id) ? 'Invited' : 'Invite'}
            compact
            disabled={invited.includes(person.id)}
            onPress={() =>
              void contentApi
                .inviteToCircle(route.params.communityId, person.id)
                .then(() => setInvited((current) => [...current, person.id]))
                .catch((error) => Alert.alert('Could not invite', error.message))
            }
          />
        </Card>
      ))}
    </Screen>
  );
}

function reportAlert(
  targetType: 'user' | 'post' | 'comment' | 'community' | 'room',
  targetId: string,
  targetLabel: string,
) {
  const submit = (reason: string) => {
    void safetyApi
      .report(targetType, targetId, reason)
      .then(() =>
        Alert.alert('Report submitted', 'Thank you. Our safety team will review your report.'),
      )
      .catch((error) => Alert.alert('Report failed', error.message || 'Please try again.'));
  };
  Alert.alert(
    'Report safely',
    `Choose a reason for reporting ${targetLabel}. Only relevant evidence will be shared with moderators.`,
    [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Spam or scam', onPress: () => submit('Spam or scam') },
      { text: 'Harassment', style: 'destructive', onPress: () => submit('Harassment') },
    ],
  );
}

export default InviteCircleMembersScreen;
