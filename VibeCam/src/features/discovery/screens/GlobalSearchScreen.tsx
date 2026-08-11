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

export function GlobalSearchScreen({ navigation }: any) {
  const [query, setQuery] = useState('');
  const [results, setResults] = useState<any>({ users: [], communities: [], posts: [] });
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  useEffect(() => {
    if (query.trim().length < 2) {
      setResults({ users: [], communities: [], posts: [] });
      return;
    }
    const timer = setTimeout(() => {
      setLoading(true);
      setError('');
      discoveryApi
        .search(query.trim())
        .then(({ data }: any) => setResults(data))
        .catch((reason) => setError(reason.message || 'Search failed.'))
        .finally(() => setLoading(false));
    }, 350);
    return () => clearTimeout(timer);
  }, [query]);
  const hasResults = Object.values(results).some((items: any) => items.length);
  return (
    <Screen>
      <Header title="Search VibeCircle" onBack={() => navigation.goBack()} />
      <SearchField value={query} onChangeText={setQuery} />
      {loading && <ChatSkeleton />}
      {!!error && (
        <EmptyState icon="cloud-offline-outline" title="Search unavailable" text={error} />
      )}
      {!query.trim() ? (
        <EmptyState
          icon="search-outline"
          title="Search everything"
          text="Find people, communities, and posts from live API data."
        />
      ) : !loading && !error && hasResults ? (
        <>
          {results.users.map((item: any) => {
            const person = {
              id: item.id,
              name: item.name,
              age: item.age,
              username: item.username || '',
              bio: item.bio || '',
              city: item.city,
              languages: item.languages || [],
              interests: item.interests || [],
              online: item.is_online,
              avatarColor: colors.primary,
            };
            return (
              <PersonCard
                key={person.id}
                person={person}
                onPress={() => navigation.navigate('PublicProfile', { personId: person.id })}
              />
            );
          })}
          {results.communities.map((item: any) => (
            <CommunityCard
              key={item.id}
              community={{
                id: item.id,
                name: item.name,
                category: item.category,
                description: item.description,
                members: item.member_count,
                color: item.color,
              }}
              onPress={() => navigation.navigate('CommunityDetails', { communityId: item.id })}
            />
          ))}
          {results.posts.map((item: any) => (
            <Card
              key={item.id}
              onPress={() => navigation.navigate('PostDetails', { postId: item.id })}
            >
              <Text style={ui.body}>{item.body}</Text>
            </Card>
          ))}
        </>
      ) : query.trim().length >= 2 && !loading && !error ? (
        <EmptyState title="No results" text="Try a broader interest, language, or name." />
      ) : null}
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

export default GlobalSearchScreen;
