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

export function CommunityJoinRequestsScreen({ navigation, route }: any) {
  const [requests, setRequests] = useState<any[]>([]);
  const [loadingRequests, setLoadingRequests] = useState(true);
  const [busyRequest, setBusyRequest] = useState('');
  const loadRequests = useCallback(() => {
    setLoadingRequests(true);
    void contentApi
      .communityJoinRequests(route.params.communityId)
      .then(({ data }) => setRequests(data))
      .catch((error) => Alert.alert('Could not load requests', error.message))
      .finally(() => setLoadingRequests(false));
  }, [route.params.communityId]);
  useFocusEffect(loadRequests);
  const respond = async (requestId: string, action: 'accept' | 'reject') => {
    setBusyRequest(`${requestId}:${action}`);
    try {
      await contentApi.respondCommunityJoinRequest(route.params.communityId, requestId, action);
      setRequests((current) => current.filter((item) => item.id !== requestId));
    } catch (error: any) {
      Alert.alert('Could not update request', error.message);
    } finally {
      setBusyRequest('');
    }
  };
  return (
    <Screen>
      <Header
        title="Join requests"
        subtitle="Approve people before they enter this community"
        onBack={() => navigation.goBack()}
      />
      {loadingRequests ? (
        <ChatSkeleton rows={3} />
      ) : requests.length ? (
        requests.map((request) => (
          <Card key={request.id} style={styles.listRow}>
            <Avatar name={request.user_name} size={48} />
            <View style={{ flex: 1 }}>
              <Text style={styles.cardTitle}>{request.user_name}</Text>
              <Text style={styles.smallMuted}>Wants to join your community</Text>
            </View>
            <IconButton icon="close" onPress={() => void respond(request.id, 'reject')} />
            <IconButton
              icon={busyRequest === `${request.id}:accept` ? 'hourglass-outline' : 'checkmark'}
              onPress={() => void respond(request.id, 'accept')}
            />
          </Card>
        ))
      ) : (
        <EmptyState
          icon="checkmark-circle-outline"
          title="No pending requests"
          text="New join requests will appear here."
        />
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

export default CommunityJoinRequestsScreen;
