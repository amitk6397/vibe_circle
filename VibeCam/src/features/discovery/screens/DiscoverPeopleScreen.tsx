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

export function DiscoverPeopleScreen({ navigation }: any) {
  const blocked = useAppStore((s) => s.blockedUsers);
  const people = useAppStore((s) => s.people);
  return (
    <Screen>
      <Header
        title="Discover people"
        subtitle="Purpose and interest-based suggestions"
        onBack={() => navigation.goBack()}
        right={<IconButton icon="options" onPress={() => navigation.navigate('SearchFilters')} />}
      />
      {people
        .filter((x) => !blocked.includes(x.id))
        .map((person) => (
          <PersonCard
            key={person.id}
            person={person}
            onPress={() => navigation.navigate('PublicProfile', { personId: person.id })}
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

export default DiscoverPeopleScreen;
