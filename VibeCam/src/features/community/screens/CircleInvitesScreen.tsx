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

export function CircleInvitesScreen({ navigation }: any) {
  const [invites, setInvites] = useState<any[]>([]);
  const [loadingInvites, setLoadingInvites] = useState(true);
  const loadInvites = useCallback(() => {
    setLoadingInvites(true);
    void contentApi
      .circleInvites()
      .then(({ data }) => setInvites(data))
      .catch((error) => Alert.alert('Could not load invitations', error.message))
      .finally(() => setLoadingInvites(false));
  }, []);
  useFocusEffect(loadInvites);
  const respond = async (invite: any, action: 'accept' | 'reject') => {
    try {
      const { data } = await contentApi.respondCircleInvite(invite.id, action);
      setInvites((current) => current.filter((item) => item.id !== invite.id));
      if (action === 'accept') {
        await useAppStore.getState().bootstrap();
        navigation.navigate('CommunityDetails', { communityId: data.community_id });
      }
    } catch (error: any) {
      Alert.alert('Could not update invitation', error.message);
    }
  };
  return (
    <Screen>
      <Header title="Circle invitations" onBack={() => navigation.goBack()} />
      {loadingInvites ? (
        <ChatSkeleton rows={3} />
      ) : invites.length ? (
        invites.map((invite) => (
          <Card key={invite.id}>
            <Text style={ui.h2}>{invite.community_name}</Text>
            <Text style={styles.smallMuted}>
              {invite.inviter_name} invited you to a private circle.
            </Text>
            <View style={styles.twoButtons}>
              <View style={{ flex: 1 }}>
                <Button
                  title="Decline"
                  tone="secondary"
                  onPress={() => void respond(invite, 'reject')}
                />
              </View>
              <View style={{ flex: 1 }}>
                <Button title="Accept" onPress={() => void respond(invite, 'accept')} />
              </View>
            </View>
          </Card>
        ))
      ) : (
        <EmptyState title="No invitations" text="Private circle invitations will appear here." />
      )}
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

export default CircleInvitesScreen;
