import React, { useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, View } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { Avatar, Card, Header, Pill, Screen, SearchField, ui } from '../../../components/ui';
import { colors } from '../../../theme';
import { useCommunityChatViewModel } from '../viewmodels/useCommunityChatViewModel';
import { safetyApi } from '../../../services/api';

export default function CommunityMembersScreen({ navigation, route }: any) {
  const [query, setQuery] = useState('');
  const [filter, setFilter] = useState('All');
  const viewModel = useCommunityChatViewModel(route.params.communityId);
  if (!viewModel.community) {
    return (
      <Screen>
        <Header title="Community members" onBack={() => navigation.goBack()} />
        <Text style={ui.muted}>This community is unavailable.</Text>
      </Screen>
    );
  }
  const community = viewModel.community;
  const members = viewModel.members.filter((member, index) => {
    const matchesQuery = `${member.name} ${member.interests.join(' ')}`
      .toLowerCase()
      .includes(query.toLowerCase());
    const matchesFilter =
      filter === 'All' ||
      (filter === 'Online' && member.online) ||
      (filter === 'Moderators' && index === 0);
    return matchesQuery && matchesFilter;
  });

  return (
    <Screen>
      <Header
        title="Community members"
        subtitle={`${community.members.toLocaleString()} people in ${community.name}`}
        onBack={() => navigation.goBack()}
      />
      <SearchField
        value={query}
        onChangeText={setQuery}
        placeholder="Search members or interests"
      />
      <View style={ui.wrap}>
        {['All', 'Online', 'Moderators'].map((item) => (
          <Pill
            key={item}
            label={item}
            selected={filter === item}
            onPress={() => setFilter(item)}
          />
        ))}
      </View>

      <Card style={styles.summary}>
        <View style={styles.avatarStack}>
          {viewModel.members.slice(0, 3).map((member, index) => (
            <View key={member.id} style={{ marginLeft: index ? -10 : 0, zIndex: 3 - index }}>
              <Avatar name={member.name} color={member.avatarColor} size={38} />
            </View>
          ))}
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.title}>Active community</Text>
          <Text style={ui.muted}>
            {viewModel.members.filter((member) => member.online).length} members online now
          </Text>
        </View>
      </Card>

      {members.map((member, index) => (
        <Card key={member.id} style={styles.memberCard}>
          <Pressable
            style={styles.memberMain}
            onPress={() => navigation.navigate('PublicProfile', { personId: member.id })}
          >
            <Avatar
              name={member.name}
              color={member.avatarColor}
              online={member.online}
              size={50}
            />
            <View style={{ flex: 1, gap: 3 }}>
              <View style={styles.nameRow}>
                <Text style={styles.title}>{member.name}</Text>
                {index === 0 && <Text style={styles.modBadge}>MODERATOR</Text>}
              </View>
              <Text style={ui.muted}>
                @{member.username} · {member.languages.join(', ')}
              </Text>
              <Text style={styles.interests} numberOfLines={1}>
                {member.interests.join(' · ')}
              </Text>
            </View>
          </Pressable>
          <View style={styles.memberActions}>
            <Pressable
              style={styles.actionButton}
              onPress={() =>
                navigation.navigate('NewMessageRequest', { personId: member.id, name: member.name })
              }
            >
              <Ionicons name="chatbubble-outline" size={17} color={colors.primary} />
              <Text style={styles.actionText}>Message</Text>
            </Pressable>
            <Pressable
              style={styles.moreButton}
              onPress={() =>
                Alert.alert(member.name, 'Choose a member action.', [
                  { text: 'Cancel', style: 'cancel' },
                  {
                    text: 'View profile',
                    onPress: () => navigation.navigate('PublicProfile', { personId: member.id }),
                  },
                  {
                    text: 'Report',
                    style: 'destructive',
                    onPress: () =>
                      void safetyApi
                        .report('user', member.id, 'Unsafe community member')
                        .then(() =>
                          Alert.alert('Report submitted', 'Our safety team will review it.'),
                        )
                        .catch((error) => Alert.alert('Report failed', error.message)),
                  },
                ])
              }
            >
              <Ionicons name="ellipsis-horizontal" size={19} color={colors.muted} />
            </Pressable>
          </View>
        </Card>
      ))}
    </Screen>
  );
}

const styles = StyleSheet.create({
  summary: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    backgroundColor: '#F5F6FF',
    borderColor: '#DDE1FF',
  },
  avatarStack: { flexDirection: 'row', paddingLeft: 2 },
  title: { color: colors.text, fontSize: 15, fontWeight: '800' },
  memberCard: { gap: 13 },
  memberMain: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  nameRow: { flexDirection: 'row', alignItems: 'center', flexWrap: 'wrap', gap: 6 },
  modBadge: {
    color: colors.primary,
    fontSize: 8,
    fontWeight: '900',
    backgroundColor: '#E9EAFF',
    borderRadius: 5,
    paddingHorizontal: 6,
    paddingVertical: 3,
  },
  interests: { color: colors.primary, fontSize: 11, fontWeight: '600' },
  memberActions: {
    flexDirection: 'row',
    borderTopWidth: 1,
    borderTopColor: colors.border,
    paddingTop: 11,
    gap: 9,
  },
  actionButton: {
    flex: 1,
    minHeight: 38,
    borderRadius: 12,
    backgroundColor: colors.surfaceAlt,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 7,
  },
  actionText: { color: colors.primary, fontSize: 12, fontWeight: '800' },
  moreButton: {
    width: 42,
    minHeight: 38,
    borderRadius: 12,
    backgroundColor: colors.bg,
    alignItems: 'center',
    justifyContent: 'center',
  },
});
