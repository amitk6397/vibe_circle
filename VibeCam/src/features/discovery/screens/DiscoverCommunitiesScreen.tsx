import React, { useEffect, useState } from 'react';

import { Alert, Pressable, Switch, Text, View } from 'react-native';

import { Ionicons } from '@expo/vector-icons';

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
  ui,
} from '../../../components/ui';

import { ChatSkeleton } from '../../../components/ChatSkeleton';

import { LANGUAGES, PURPOSES } from '../../../constants/data';

import { colors } from '../../../theme';

import { Purpose } from '../../../types';

import { useAppStore } from '../../../store/useAppStore';

import { chatApi, discoveryApi, safetyApi, usersApi } from '../../../services/api';

import { styles } from '../../shared-views/styles';

export function DiscoverCommunitiesScreen({ navigation }: any) {
  const communities = useAppStore((state) => state.communities).filter(
    (c) => !(c.kind === 'circle' && c.privacy === 'private' && !c.joined && !c.isOwner),
  );
  return (
    <Screen>
      <Header
        title="Communities"
        subtitle="Learn, share, and belong"
        onBack={() => navigation.goBack()}
      />
      <Card style={styles.createCommunityCard}>
        <View style={styles.createCommunityCopy}>
          <View style={styles.createCommunityIcon}>
            <Ionicons name="people" size={24} color={colors.primary} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.cardTitle}>Start your own circle</Text>
            <Text style={styles.smallMuted}>
              Create a focused, welcoming community with clear rules.
            </Text>
          </View>
        </View>
        <Button
          title="Create community"
          icon="add-circle-outline"
          onPress={() => navigation.navigate('CreateCommunity')}
        />
      </Card>
      <Section title="Explore communities" />
      {communities.map((community) => (
        <CommunityCard
          key={community.id}
          community={community}
          onPress={() => navigation.navigate('CommunityDetails', { communityId: community.id })}
        />
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

export default DiscoverCommunitiesScreen;
