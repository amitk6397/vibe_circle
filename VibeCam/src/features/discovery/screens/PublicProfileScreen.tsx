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

export function PublicProfileScreen({ navigation, route }: any) {
  const storePerson = useAppStore((state) => state.people.find((x) => x.id === route.params.personId));
  const [person, setPerson] = useState<any>(storePerson || null);
  const [loading, setLoading] = useState(!storePerson);
  const [loadError, setLoadError] = useState('');
  const blocked = useAppStore((state) => state.blockedUsers.includes(route.params.personId));
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [action, setAction] = useState<'connect' | 'message' | ''>('');
  const [relationship, setRelationship] = useState<any>(null);

  useEffect(() => {
    let active = true;
    setLoading(true);
    usersApi
      .publicProfile(route.params.personId)
      .then(({ data }) => {
        if (!active) return;
        setPerson({
          id: data.id,
          name: data.name,
          age: data.age,
          username: data.username || '',
          bio: data.bio || '',
          city: data.city,
          languages: data.languages || [],
          interests: data.interests || [],
          online: data.is_online,
          avatarUrl: data.avatar_url,
          avatarColor: '#5B5CE2',
        });
        setLoadError('');
      })
      .catch((err) => {
        if (!active) return;
        if (!storePerson) {
          setLoadError(err.message || 'Could not load profile.');
        }
      })
      .finally(() => {
        if (active) setLoading(false);
      });

    usersApi
      .connections()
      .then(({ data }) => {
        if (!active) return;
        setRelationship(
          data.find(
            (item) =>
              item.requester_id === currentUserId && item.receiver_id === route.params.personId,
          ) || null,
        );
      })
      .catch(() => undefined);

    return () => {
      active = false;
    };
  }, [currentUserId, route.params.personId, storePerson]);

  if (loading && !person) {
    return (
      <Screen>
        <Header title="Profile" onBack={() => navigation.goBack()} />
        <ChatSkeleton />
      </Screen>
    );
  }

  if (loadError || !person) {
    return (
      <Screen>
        <Header title="Profile" onBack={() => navigation.goBack()} />
        <EmptyState title="Profile unavailable" text={loadError || 'This account may no longer be available.'} />
      </Screen>
    );
  }
  const block = () => {
    useAppStore.getState()[blocked ? 'unblockUser' : 'blockUser'](person.id);
    Alert.alert(
      blocked ? 'Unblocked' : 'Blocked',
      blocked
        ? `${person.name} is visible again.`
        : 'They can no longer find, connect, message, or call you.',
    );
  };
  return (
    <Screen>
      <Header
        title="Profile"
        onBack={() => navigation.goBack()}
        right={
          <IconButton
            icon="ellipsis-horizontal"
            onPress={() =>
              Alert.alert(
                'Safety actions',
                'Use the controls below to block or report this profile.',
              )
            }
          />
        }
      />
      <View style={styles.profileHero}>
        <Avatar name={person.name} color={person.avatarColor} online={person.online} size={92} uri={person.avatarUrl || undefined} />
        <Text style={ui.title}>
          {person.name}, {person.age}
        </Text>
        <Text style={styles.handle}>
          @{person.username} · {person.city}
        </Text>
        <View style={styles.trust}>
          <Ionicons name="shield-checkmark" size={17} color={colors.info} />
          <Text style={styles.trustText}>Identity signals reviewed</Text>
        </View>
      </View>
      <Card>
        <Text style={ui.body}>{person.bio}</Text>
      </Card>
      <Text style={ui.h2}>Interests</Text>
      <View style={ui.wrap}>
        {person.interests.map((x: string) => (
          <Pill key={x} label={x} />
        ))}
      </View>
      <Text style={ui.h2}>Languages</Text>
      <View style={ui.wrap}>
        {person.languages.map((x: string) => (
          <Pill key={x} label={x} />
        ))}
      </View>
      {!!person.conversationTopics?.length && (
        <>
          <Text style={ui.h2}>Open to talk about</Text>
          <View style={ui.wrap}>
            {person.conversationTopics.map((topic: string) => (
              <Pill key={topic} label={topic} />
            ))}
          </View>
        </>
      )}
      <Button
        title="View performance & coin rates"
        icon="star-outline"
        onPress={() => navigation.navigate('UserPerformance', { userId: person.id })}
      />
      {!blocked ? (
        <View style={styles.twoButtons}>
          <View style={{ flex: 1 }}>
            <Button
              title={
                relationship?.status === 'accepted'
                  ? 'Unfollow'
                  : relationship?.status === 'pending'
                    ? 'Requested'
                    : 'Follow'
              }
              icon="person-add"
              loading={action === 'connect'}
              onPress={async () => {
                setAction('connect');
                try {
                  if (relationship) {
                    await usersApi.removeConnection(relationship.id);
                    setRelationship(null);
                  } else {
                    const { data } = await usersApi.requestConnection(person.id);
                    setRelationship(data);
                    Alert.alert(
                      data.status === 'accepted' ? 'Following' : 'Request sent',
                      data.status === 'accepted'
                        ? `You are now following ${person.name}.`
                        : `${person.name} can now accept your follow request.`,
                    );
                  }
                } catch (error: any) {
                  Alert.alert('Could not connect', error.message || 'Please try again.');
                } finally {
                  setAction('');
                }
              }}
            />
          </View>
          <View style={{ flex: 1 }}>
            <Button
              title="Message"
              tone="secondary"
              icon="chatbubble"
              loading={action === 'message'}
              onPress={async () => {
                setAction('message');
                try {
                  const { data } = await chatApi.createConversation(person.id);
                  navigation.navigate('PrivateChat', {
                    chatId: data.id,
                    name: person.name,
                    personId: person.id,
                  });
                } catch (error: any) {
                  Alert.alert('Could not start chat', error.message || 'Please try again.');
                } finally {
                  setAction('');
                }
              }}
            />
          </View>
        </View>
      ) : (
        <Card style={styles.blockedNotice}>
          <Ionicons name="ban-outline" size={22} color={colors.danger} />
          <Text style={[ui.muted, { flex: 1 }]}>
            You cannot follow or message each other while this account is blocked.
          </Text>
        </Card>
      )}
      <Button title={blocked ? 'Unblock user' : 'Block user'} tone="danger" onPress={block} />
      <Button
        title="Report profile"
        tone="ghost"
        onPress={() => reportAlert('user', person.id, person.name)}
      />
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

export default PublicProfileScreen;
