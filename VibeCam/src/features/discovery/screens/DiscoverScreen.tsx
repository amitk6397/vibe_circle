import React, { useEffect, useState } from 'react';

import {
  Alert,
  Dimensions,
  FlatList,
  Image,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';

import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';

import {
  Button,
  Card,
  CommunityCard,
  EmptyState,
  Header,
  IconButton,
  PersonCard,
  PersonGridCard,
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
import { environment } from '../../../config/environment';
import { styles as sharedStyles } from '../../shared-views/styles';

const SCREEN_WIDTH = Dimensions.get('window').width;
const CARD_WIDTH = (SCREEN_WIDTH - 20 * 2 - 10) / 2; // 2 columns with gap



const getAbsoluteUri = (uri?: string) => {
  if (!uri) return undefined;
  const trimmed = uri.trim();
  if (!trimmed || trimmed === 'null' || trimmed === 'None') return undefined;
  if (
    trimmed.startsWith('http://') ||
    trimmed.startsWith('https://') ||
    trimmed.startsWith('data:') ||
    trimmed.startsWith('file://') ||
    trimmed.startsWith('content://')
  ) {
    return trimmed;
  }
  const base = environment.apiUrl.split('/api/')[0];
  return `${base}${trimmed.startsWith('/') ? '' : '/'}${trimmed}`;
};

function CommunityGridCard({ community, onPress }: { community: any; onPress: () => void }) {
  // Try to use logoUrl first, then coverUrl, then fallback to colored gradient
  const hasPhoto = !!community.logoUrl || !!community.coverUrl;
  const photoUrl = community.logoUrl || community.coverUrl;
  const bgColor = community.color || '#7C3AED';
  const initial = (community.name || '?')[0].toUpperCase();

  return (
    <Pressable style={styles.gridCard} onPress={onPress}>
      {/* Full-card image or gradient background */}
      {hasPhoto ? (
        <Image source={{ uri: getAbsoluteUri(photoUrl) }} style={StyleSheet.absoluteFill} resizeMode="cover" />
      ) : (
        <LinearGradient
          colors={[bgColor, bgColor + 'AA']}
          style={StyleSheet.absoluteFill}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
        />
      )}

      {/* Initials shown when no photo */}
      {!hasPhoto && (
        <View style={styles.gridInitialWrapper}>
          <Text style={styles.gridInitial}>{initial}</Text>
        </View>
      )}

      {/* Bottom gradient overlay with details */}
      <LinearGradient
        colors={['transparent', 'rgba(0,0,0,0.85)']}
        style={styles.gridOverlay}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
      >
        <Text style={styles.gridName} numberOfLines={1}>{community.name}</Text>
        <View style={styles.gridDetailRow}>
          <Ionicons name="people-outline" size={11} color="rgba(255,255,255,0.7)" />
          <Text style={styles.gridDetailText} numberOfLines={1}>{community.members || 0} members</Text>
        </View>
        <View style={styles.gridTags}>
          <View style={[styles.gridTag, { backgroundColor: 'rgba(255,255,255,0.25)' }]}>
            <Text style={styles.gridTagText} numberOfLines={1}>{community.category}</Text>
          </View>
        </View>
      </LinearGradient>
    </Pressable>
  );
}

export function DiscoverScreen({ navigation }: any) {
  const [query, setQuery] = useState('');
  const [discoverTab, setDiscoverTab] = useState<'people' | 'communities' | 'posts'>('people');
  const [purposeLoading, setPurposeLoading] = useState(false);
  const [purposeError, setPurposeError] = useState('');
  const { selectedPurpose, searchFilters } = useAppStore();
  const blocked = useAppStore((s) => s.blockedUsers);
  const allPeople = useAppStore((s) => s.people);
  const communities = useAppStore((s) => s.communities);
  const posts = useAppStore((s) => s.posts);

  useEffect(() => {
    setPurposeLoading(true);
    setPurposeError('');
    discoveryApi
      .users({
        purpose: searchFilters.purpose || selectedPurpose,
        min_age: searchFilters.minAge,
        max_age: searchFilters.maxAge,
        online_only: searchFilters.onlineOnly,
        gender: searchFilters.gender,
        city: searchFilters.city,
        languages: searchFilters.language,
      })
      .then(({ data }) => {
        useAppStore.setState({
          people: data.map((item, index) => ({
            id: item.id,
            name: item.name,
            age: item.age,
            username: item.username || '',
            bio: item.bio,
            city: item.city,
            languages: item.languages,
            interests: item.interests,
            online: item.is_online,
            avatarUrl: item.avatar_url || null,
            avatarColor: ['#5B5CE2', '#2FB67C', '#FF6B6B', '#8B6BD9'][index % 4],
          })),
        });
      })
      .catch((reason) => setPurposeError(reason.message || 'Recommendations could not load.'))
      .finally(() => setPurposeLoading(false));
  }, [selectedPurpose, searchFilters]);

  const people = allPeople.filter(
    (p) =>
      !blocked.includes(p.id) &&
      `${p.name} ${p.username || ''} ${p.interests.join(' ')}`.toLowerCase().includes(query.toLowerCase()),
  );
  const visibleCommunities = communities
    .filter((c) => !(c.kind === 'circle' && c.privacy === 'private' && !c.joined && !c.isOwner))
    .filter((community) =>
      `${community.name} ${community.category} ${community.description}`
        .toLowerCase()
        .includes(query.toLowerCase()),
    );
  const visiblePosts = posts.filter((post) =>
    `${post.author} ${post.authorUsername || ''} ${post.community} ${post.body}`.toLowerCase().includes(query.toLowerCase()),
  );

  return (
    <Screen scroll={false} edges={['top', 'left', 'right']}>
      <View style={sharedStyles.topRow}>
        <View>
          <Text style={sharedStyles.eyebrow}>DISCOVER</Text>
          <Text style={ui.title}>Find your circle</Text>
        </View>
        <View style={sharedStyles.headerActions}>
          {discoverTab === 'people' ? (
            <IconButton
              icon="options-outline"
              onPress={() => navigation.navigate('SearchFilters')}
            />
          ) : (
            <IconButton
              icon="add"
              onPress={() =>
                navigation.navigate(
                  discoverTab === 'communities' ? 'CreateCommunity' : 'CreatePost',
                )
              }
            />
          )}
        </View>
      </View>
      <ScrollView style={{ flex: 1 }} showsVerticalScrollIndicator={false} contentContainerStyle={{ padding: 18, gap: 16 }}>
        <SearchField value={query} onChangeText={setQuery} placeholder={`Search ${discoverTab}`} />
        <View style={ui.wrap}>
          <Pill
            label="People"
            selected={discoverTab === 'people'}
            onPress={() => setDiscoverTab('people')}
          />
          <Pill
            label="Communities"
            selected={discoverTab === 'communities'}
            onPress={() => setDiscoverTab('communities')}
          />
          <Pill
            label="Posts"
            selected={discoverTab === 'posts'}
            onPress={() => setDiscoverTab('posts')}
          />
        </View>

        {/* People — Photo Grid */}
        {discoverTab === 'people' && (
          <>
            <Section title="People for you" />
            {purposeLoading && <ChatSkeleton rows={2} />}
            {!!purposeError && (
              <EmptyState icon="cloud-offline-outline" title="Unable to load" text={purposeError} />
            )}
            {!purposeLoading && !purposeError && !people.length && (
              <EmptyState title="No people found" text="Try another name or purpose." />
            )}
            {!purposeLoading && !purposeError && people.length > 0 && (
              <FlatList
                data={people}
                keyExtractor={(p) => p.id}
                numColumns={2}
                scrollEnabled={false}
                columnWrapperStyle={styles.gridRow}
                contentContainerStyle={styles.gridContent}
                renderItem={({ item }) => (
                  <PersonGridCard
                    person={item}
                    onPress={() => navigation.navigate('PublicProfile', { personId: item.id })}
                  />
                )}
              />
            )}
          </>
        )}

        {discoverTab === 'communities' && (
          <>
            <Section
              title="Communities"
              action="Create"
              onAction={() => navigation.navigate('CreateCommunity')}
            />
            {!visibleCommunities.length && (
              <EmptyState title="No communities found" text="Try another search or create one." />
            )}
            {visibleCommunities.length > 0 && (
              <FlatList
                data={visibleCommunities}
                keyExtractor={(c) => c.id}
                numColumns={2}
                scrollEnabled={false}
                columnWrapperStyle={styles.gridRow}
                contentContainerStyle={styles.gridContent}
                renderItem={({ item }) => (
                  <CommunityGridCard
                    community={item}
                    onPress={() => navigation.navigate('CommunityDetails', { communityId: item.id })}
                  />
                )}
              />
            )}
          </>
        )}

        {discoverTab === 'posts' && (
          <>
            <Section
              title="Posts"
              action="Create"
              onAction={() => navigation.navigate('CreatePost')}
            />
            {!visiblePosts.length && (
              <EmptyState title="No posts found" text="Try another search or create a post." />
            )}
            {visiblePosts.map((post) => (
              <PostCard
                key={post.id}
                post={post}
                onPress={() => navigation.navigate('PostDetails', { postId: post.id })}
                onAuthorPress={
                  post.authorId
                    ? () => navigation.navigate('PublicProfile', { personId: post.authorId })
                    : undefined
                }
              />
            ))}
          </>
        )}
      </ScrollView>
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

const styles = StyleSheet.create({
  gridRow: { gap: 10 },
  gridContent: { gap: 10, paddingBottom: 10 },
  gridCard: {
    width: CARD_WIDTH,
    aspectRatio: 3 / 4,
    borderRadius: 18,
    overflow: 'hidden',
    backgroundColor: colors.surfaceAlt,
    position: 'relative',
  },
  gridInitialWrapper: {
    ...StyleSheet.absoluteFillObject,
    alignItems: 'center',
    justifyContent: 'center',
  },
  gridInitial: {
    fontSize: 48,
    fontWeight: '900',
    color: 'rgba(255,255,255,0.85)',
  },
  onlineDot: {
    position: 'absolute',
    top: 10,
    right: 10,
    width: 14,
    height: 14,
    borderRadius: 7,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
    zIndex: 2,
  },
  onlineDotInner: {
    width: 9,
    height: 9,
    borderRadius: 4.5,
    backgroundColor: '#22C55E',
  },
  gridOverlay: {
    position: 'absolute',
    bottom: 0,
    left: 0,
    right: 0,
    padding: 10,
    gap: 3,
    zIndex: 1,
  },
  gridName: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '800',
    textShadowColor: 'rgba(0,0,0,0.5)',
    textShadowOffset: { width: 0, height: 1 },
    textShadowRadius: 3,
  },
  gridDetailRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 3,
  },
  gridDetailText: {
    color: 'rgba(255,255,255,0.75)',
    fontSize: 11,
    flex: 1,
  },
  gridTags: {
    flexDirection: 'row',
    gap: 4,
    flexWrap: 'wrap',
    marginTop: 3,
  },
  gridTag: {
    backgroundColor: 'rgba(255,255,255,0.2)',
    borderRadius: 8,
    paddingHorizontal: 7,
    paddingVertical: 2,
  },
  gridTagText: {
    color: '#fff',
    fontSize: 10,
    fontWeight: '600',
  },
});

export default DiscoverScreen;
