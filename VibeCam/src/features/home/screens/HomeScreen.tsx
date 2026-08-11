import React, { useCallback, useEffect, useRef, useState } from 'react';
import { useFocusEffect } from '@react-navigation/native';
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
  StyleSheet,
  Text,
  TextInput,
  View,
} from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import {
  Card,
  EmptyState,
  IconButton,
  PersonCard,
  PostCard,
  Screen,
  Section,
  Avatar,
  ui,
  Button,
  resolveImageUrl,
} from '../../../components/ui';
import { PURPOSES } from '../../../constants/data';
import { colors, gradients } from '../../../theme';
import { Post } from '../../../types';
import { useAppStore } from '../../../store/useAppStore';
import { pickStoryImages } from '../../../services/mediaPicker';
import {
  chatApi,
  contentApi,
  matchingApi,
  storyApi,
  uploadAttachment,
  usersApi,
  safetyApi,
  walletApi,
} from '../../../services/api';
import { ChatSkeleton } from '../../../components/ChatSkeleton';
import { styles } from '../../shared-views/styles';

function parseUTCDate(value: string): Date {
  if (!value) return new Date();
  let normalized = value;
  if (!value.endsWith('Z') && !/[+-]\d{2}:\d{2}$/.test(value) && !value.includes('+')) {
    normalized = value.replace(' ', 'T') + 'Z';
  }
  return new Date(normalized);
}

function RecommendedPersonGridCard({ person, onPress }: { person: any; onPress: () => void }) {
  const hasPhoto = !!person.avatarUrl || !!person.avatarUri;
  const photoUrl = resolveImageUrl(person.avatarUrl || person.avatarUri);
  const bgColor = person.avatarColor || '#5B5CE2';
  const initial = (person.name || '?')[0].toUpperCase();

  return (
    <Pressable style={homeCardStyles.gridCard} onPress={onPress}>
      {/* Full-card image or gradient background */}
      {hasPhoto && photoUrl ? (
        <Image source={{ uri: photoUrl }} style={StyleSheet.absoluteFill} resizeMode="cover" />
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
        <View style={homeCardStyles.gridInitialWrapper}>
          <Text style={homeCardStyles.gridInitial}>{initial}</Text>
        </View>
      )}

      {/* Online indicator */}
      {person.online && (
        <View style={homeCardStyles.onlineDot}>
          <View style={homeCardStyles.onlineDotInner} />
        </View>
      )}

      {/* Bottom gradient overlay with user details */}
      <LinearGradient
        colors={['transparent', 'rgba(0,0,0,0.85)']}
        style={homeCardStyles.gridOverlay}
        start={{ x: 0, y: 0 }}
        end={{ x: 0, y: 1 }}
      >
        <Text style={homeCardStyles.gridName} numberOfLines={1}>{person.name}</Text>
        {person.city ? (
          <View style={homeCardStyles.gridDetailRow}>
            <Ionicons name="location-outline" size={11} color="rgba(255,255,255,0.75)" />
            <Text style={homeCardStyles.gridDetailText} numberOfLines={1}>{person.city}</Text>
          </View>
        ) : null}
        {/* Interest tags */}
        <View style={homeCardStyles.gridTags}>
          {(person.interests || []).slice(0, 2).map((tag: string) => (
            <View key={tag} style={homeCardStyles.gridTag}>
              <Text style={homeCardStyles.gridTagText} numberOfLines={1}>{tag}</Text>
            </View>
          ))}
        </View>
      </LinearGradient>
    </Pressable>
  );
}

const homeCardStyles = StyleSheet.create({
  gridCard: {
    width: 150,
    height: 200,
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
    backgroundColor: colors.surface,
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

function storyUploadTime(value: string) {
  const date = parseUTCDate(value);
  const diff = Date.now() - date.getTime();
  const minutes = Math.max(0, Math.floor(diff / 60000));
  if (minutes < 1) return 'Now';
  if (minutes < 60) return `${minutes}m ago`;
  const hours = Math.floor(minutes / 60);
  if (hours < 24) return `${hours}h ago`;
  return date.toLocaleDateString();
}

export function HomeScreen({ navigation }: any) {
  const { profile, posts, people, notifications, loading, apiError, bootstrap, currentUserId } =
    useAppStore();
  const darkMode = useAppStore((state) => state.darkMode);
  const [createMenuOpen, setCreateMenuOpen] = useState(false);
  const [storyRailOpen, setStoryRailOpen] = useState(false);
  const storyRailOpenRef = useRef(false);
  const [storyRailSide, setStoryRailSide] = useState<'left' | 'right'>('left');
  const storyRailSideRef = useRef<'left' | 'right'>('left');
  const storyRailProgress = useRef(new Animated.Value(0)).current;
  const storyRailPanStart = useRef(0);
  const storyHandleDragging = useRef(false);
  const storyHandleX = useRef(new Animated.Value(0)).current;
  const storyHandleY = useRef(new Animated.Value(220)).current;
  const [followRequests, setFollowRequests] = useState<any[]>([]);
  const [unreadChatCount, setUnreadChatCount] = useState(0);
  const [circleInviteCount, setCircleInviteCount] = useState(0);
  const [stories, setStories] = useState<any[]>([]);
  const [activeStoryOwner, setActiveStoryOwner] = useState<string | null>(null);
  const [activeStory, setActiveStory] = useState<number | null>(null);
  const [storyUploading, setStoryUploading] = useState(false);
  const [storyPaused, setStoryPaused] = useState(false);
  const [storyProgress, setStoryProgress] = useState(0);
  const [storyReply, setStoryReply] = useState('');
  const [viewersOpen, setViewersOpen] = useState(false);
  const [reactionBurst, setReactionBurst] = useState('');
  const [coinBalance, setCoinBalance] = useState(0);
  const [dailyRewardOpen, setDailyRewardOpen] = useState(false);
  const [dailyRewardData, setDailyRewardData] = useState<any>(null);
  const reactionScale = useRef(new Animated.Value(0)).current;
  const storyHeld = useRef(false);
  const storySwipeStart = useRef(0);
  const storyGroups = Object.values(
    stories.reduce<Record<string, any>>((groups, story) => {
      groups[story.author_id] ??= {
        authorId: story.author_id,
        authorName: story.author_name,
        avatarUrl: story.author_avatar_url,
        mine: story.mine,
        stories: [],
      };
      groups[story.author_id].stories.push(story);
      return groups;
    }, {}),
  ).sort((first: any, second: any) => Number(second.mine) - Number(first.mine));
  const viewerStories = activeStoryOwner
    ? stories
        .filter((story) => story.author_id === activeStoryOwner)
        .sort(
          (first, second) =>
            new Date(first.created_at).getTime() - new Date(second.created_at).getTime(),
        )
    : [];
  const currentStory = activeStory === null ? null : viewerStories[activeStory];
  const setRailOpen = (open: boolean) => {
    storyRailOpenRef.current = open;
    setStoryRailOpen(open);
    Animated.spring(storyRailProgress, {
      toValue: open ? 1 : 0,
      tension: 72,
      friction: 12,
      useNativeDriver: true,
    }).start();
  };
  const storyRailPan = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: (_, gesture) =>
        Math.abs(gesture.dx) > 4 && Math.abs(gesture.dx) > Math.abs(gesture.dy),
      onPanResponderGrant: () => {
        storyRailProgress.stopAnimation();
        storyRailPanStart.current = storyRailOpenRef.current ? 1 : 0;
      },
      onPanResponderMove: (_, gesture) => {
        const direction = storyRailSideRef.current === 'left' ? 1 : -1;
        const next = storyRailPanStart.current + (gesture.dx * direction) / 102;
        storyRailProgress.setValue(Math.max(0, Math.min(1, next)));
      },
      onPanResponderRelease: (_, gesture) => {
        const direction = storyRailSideRef.current === 'left' ? 1 : -1;
        const moved = (gesture.dx * direction) / 102;
        const velocity = gesture.vx * direction;
        const next = storyRailPanStart.current + moved;
        setRailOpen(velocity > 0.35 || (velocity >= -0.35 && next >= 0.5));
      },
      onPanResponderTerminate: () => setRailOpen(storyRailOpenRef.current),
    }),
  ).current;
  const storyHandlePan = useRef(
    PanResponder.create({
      onMoveShouldSetPanResponder: () => storyHandleDragging.current,
      onPanResponderMove: (_, gesture) => {
        if (!storyHandleDragging.current) return;
        const maxX = Dimensions.get('window').width - 34;
        const maxY = Dimensions.get('window').height - 210;
        storyHandleX.setValue(Math.max(0, Math.min(maxX, gesture.moveX - 17)));
        storyHandleY.setValue(Math.max(56, Math.min(maxY, gesture.moveY - 52)));
      },
      onPanResponderRelease: (_, gesture) => {
        if (!storyHandleDragging.current) return;
        const nextSide = gesture.moveX >= Dimensions.get('window').width / 2 ? 'right' : 'left';
        storyRailSideRef.current = nextSide;
        setStoryRailSide(nextSide);
        storyHandleDragging.current = false;
        Animated.spring(storyHandleX, {
          toValue: nextSide === 'right' ? Dimensions.get('window').width - 34 : 0,
          tension: 90,
          friction: 12,
          useNativeDriver: true,
        }).start();
      },
      onPanResponderTerminate: () => {
        storyHandleDragging.current = false;
      },
    }),
  ).current;
  const loadFollowRequests = useCallback(() => {
    void usersApi
      .connections()
      .then(({ data }) =>
        setFollowRequests(
          data.filter((item) => item.status === 'pending' && item.receiver_id === currentUserId),
        ),
      )
      .catch(() => undefined);
  }, [currentUserId]);
  useFocusEffect(loadFollowRequests);
  const loadHomeActivity = useCallback(() => {
    void Promise.all([chatApi.conversations(), contentApi.circleInvites()])
      .then(([conversationResult, circleResult]) => {
        setUnreadChatCount(
          conversationResult.data.reduce(
            (total: number, item: any) => total + Number(item.unread_count || 0),
            0,
          ),
        );
        setCircleInviteCount(circleResult.data.length);
      })
      .catch(() => undefined);
  }, []);
  useFocusEffect(loadHomeActivity);
  const loadStories = useCallback(() => {
    void storyApi
      .list()
      .then(({ data }) => setStories(data))
      .catch(() => undefined);
  }, []);
  useFocusEffect(loadStories);
  useFocusEffect(
    useCallback(() => {
      void walletApi
        .get()
        .then(({ data }) => setCoinBalance(data.purchased_coins + data.bonus_coins));
    }, []),
  );
  useEffect(() => {
    void walletApi.claimDailyReward()
      .then(({ data }) => {
        setDailyRewardData(data);
        setDailyRewardOpen(true);
        void walletApi.get().then(({ data: w }) => {
          setCoinBalance(w.purchased_coins + w.bonus_coins);
        });
      })
      .catch(() => undefined);
  }, []);
  useEffect(() => {
    if (!currentStory) return;
    if (currentStory && !currentStory.viewed) {
      setStories((current) =>
        current.map((item) => (item.id === currentStory.id ? { ...item, viewed: true } : item)),
      );
      void storyApi.view(currentStory.id);
    }
    setStoryProgress(0);
  }, [currentStory?.id]);
  useEffect(() => {
    if (!currentStory || activeStory === null || storyPaused || viewersOpen) return;
    const currentIndex = activeStory;
    const timer = setInterval(() => {
      setStoryProgress((progress) => {
        if (progress < 0.98) return progress + 0.02;
        if (currentIndex >= viewerStories.length - 1) {
          setActiveStory(null);
          setActiveStoryOwner(null);
        } else setActiveStory((current) => (current === null ? null : current + 1));
        return 0;
      });
    }, 100);
    return () => clearInterval(timer);
  }, [currentStory?.id, viewerStories.length, storyPaused, viewersOpen]);
  const addStory = async (audience = 'public') => {
    const images = await pickStoryImages();
    if (!images.length) return;
    setStoryUploading(true);
    try {
      for (const image of images) {
        const uploaded = await uploadAttachment(image);
        if (uploaded.kind !== 'image') throw new Error('Stories support photos only.');
        const { data } = await storyApi.create(uploaded.url, audience);
        setStories((current) => [data, ...current]);
      }
    } catch (error: any) {
      Alert.alert('Story upload failed', error.message || 'Please try again.');
    } finally {
      setStoryUploading(false);
    }
  };
  const chooseStoryAudience = () =>
    Alert.alert('Story audience', 'Choose who can view this story.', [
      { text: 'Cancel', style: 'cancel' },
      { text: 'Public', onPress: () => void addStory('public') },
      { text: 'Followers', onPress: () => void addStory('followers') },
      { text: 'Close Circle', onPress: () => void addStory('close_circle') },
      { text: 'Paid supporters', onPress: () => void addStory('paid_supporters') },
    ]);
  const openStory = (authorId: string) => {
    const groupStories = stories
      .filter((story) => story.author_id === authorId)
      .sort(
        (first, second) =>
          new Date(first.created_at).getTime() - new Date(second.created_at).getTime(),
      );
    const firstUnseen = groupStories.findIndex((story) => !story.viewed);
    setActiveStoryOwner(authorId);
    setActiveStory(firstUnseen >= 0 ? firstUnseen : 0);
  };
  const reactToStory = async (storyId: string, emoji: string) => {
    setReactionBurst(emoji);
    reactionScale.setValue(0);
    Animated.sequence([
      Animated.spring(reactionScale, { toValue: 1.35, useNativeDriver: true }),
      Animated.timing(reactionScale, { toValue: 1, duration: 130, useNativeDriver: true }),
    ]).start();
    setTimeout(() => setReactionBurst(''), 850);
    try {
      const { data } = await storyApi.react(storyId, emoji);
      setStories((current) =>
        current.map((story) =>
          story.id === storyId ? { ...story, reaction_counts: data.reaction_counts } : story,
        ),
      );
    } catch (error: any) {
      Alert.alert('Reaction failed', error.message || 'Please try again.');
    }
  };
  return (
    <Screen scroll={false} edges={['top', 'left', 'right']}>
      <Animated.View
        {...storyRailPan.panHandlers}
        style={[
          styles.homeMain,
          {
            transform: [
              {
                translateX: storyRailProgress.interpolate({
                  inputRange: [0, 1],
                  outputRange: [0, storyRailSide === 'left' ? 102 : -102],
                }),
              },
            ],
          },
        ]}
      >
        <View style={styles.topRow}>
          <View style={{ flexDirection: 'row', alignItems: 'center', gap: 10 }}>
            <Pressable onPress={() => navigation.navigate('Profile')}>
              {profile.avatarUri && resolveImageUrl(profile.avatarUri) ? (
                <Image source={{ uri: resolveImageUrl(profile.avatarUri)! }} style={{ width: 44, height: 44, borderRadius: 22, backgroundColor: colors.surfaceAlt }} />
              ) : (
                <View style={{ width: 44, height: 44, borderRadius: 22, backgroundColor: colors.primary, alignItems: 'center', justifyContent: 'center' }}>
                  <Text style={{ fontWeight: '800', color: '#fff', fontSize: 16 }}>{profile.name[0].toUpperCase()}</Text>
                </View>
              )}
            </Pressable>
            <View>
              <Text style={styles.eyebrow}>YOUR VIBECIRCLE</Text>
              <Text style={[ui.title, { fontSize: 18, marginTop: -2 }]}>Hi, {profile.name.split(' ')[0]} 👋</Text>
            </View>
          </View>
          <View style={styles.homeHeaderActions}>
            <Pressable
              onPress={() => navigation.navigate('SubscriptionPlans')}
              style={({ pressed }) => [styles.coinHeaderChip, pressed && { opacity: 0.72 }]}
            >
              <LinearGradient colors={gradients.warm} style={styles.coinHeaderIcon}>
                <Ionicons name="logo-bitcoin" size={15} color="#fff" />
              </LinearGradient>
              <Text style={styles.coinHeaderValue}>{coinBalance}</Text>
              <Ionicons name="add-circle" size={16} color={colors.primary} />
            </Pressable>
            <IconButton
              icon="notifications-outline"
              badge={notifications}
              onPress={() => navigation.navigate('Notifications')}
            />
          </View>
        </View>
        <ScrollView style={{ flex: 1 }} showsVerticalScrollIndicator={false} contentContainerStyle={[styles.homeContent, { paddingTop: 12 }]}>
          {!!followRequests.length && (
            <Card
              onPress={() => navigation.navigate('ConnectionRequest')}
              style={styles.joinedBanner}
            >
              <Text style={styles.cardTitle}>
                {followRequests.length} new follow request{followRequests.length > 1 ? 's' : ''}
              </Text>
              <Text style={ui.muted}>
                {followRequests
                  .map(
                    (request) => people.find((person) => person.id === request.requester_id)?.name,
                  )
                  .filter(Boolean)
                  .join(', ')}
              </Text>
            </Card>
          )}

          <Section
            title="Recommended people"
            action="See all"
            onAction={() => navigation.navigate('RecommendedPeople')}
          />
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.recommendedPeopleRow}
          >
            {people.slice(0, 6).map((person) => (
              <View key={person.id} style={styles.recommendedPersonCard}>
                <RecommendedPersonGridCard
                  person={person}
                  onPress={() => navigation.navigate('PublicProfile', { personId: person.id })}
                />
              </View>
            ))}
          </ScrollView>
          <Section
            title="Your feed"
            action="View feed"
            onAction={() => navigation.navigate('CommunityFeed')}
          />
          {loading && !posts.length ? (
            <ChatSkeleton rows={3} />
          ) : posts.some((post) => post.community === 'Discover') ? (
            posts
              .filter((post) => post.community === 'Discover')
              .map((post) => (
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
              ))
          ) : (
            <EmptyState title="No posts yet" text="Join a community and create the first post." />
          )}
          {!!apiError && (
            <Pressable style={styles.inlineError} onPress={() => void bootstrap()}>
              <Ionicons name="cloud-offline-outline" color={colors.danger} />
              <Text style={styles.inlineErrorText}>{apiError} · Tap to retry</Text>
            </Pressable>
          )}
        </ScrollView>
      </Animated.View>
      <Animated.View
        {...storyRailPan.panHandlers}
        style={[
          styles.storyRail,
          storyRailSide === 'right' && styles.storyRailRight,
          darkMode && styles.storyRailDark,
          {
            transform: [
              {
                translateX: storyRailProgress.interpolate({
                  inputRange: [0, 1],
                  outputRange: [storyRailSide === 'left' ? -102 : 102, 0],
                }),
              },
            ],
          },
        ]}
      >
        <Text style={styles.storyRailTitle}>Stories</Text>
        <ScrollView
          showsVerticalScrollIndicator={false}
          contentContainerStyle={styles.storyRailContent}
        >
          {!storyGroups.some((group: any) => group.mine) && (
            <Pressable style={styles.storyItem} onPress={chooseStoryAudience}>
              <View style={[styles.storyRing, styles.addStoryRing]}>
                {storyUploading ? (
                  <ActivityIndicator color={colors.primary} />
                ) : (profile.avatarUri && resolveImageUrl(profile.avatarUri)) ? (
                  <Image source={{ uri: resolveImageUrl(profile.avatarUri)! }} style={styles.storyAvatar} />
                ) : (
                  <Ionicons name="person" size={28} color={colors.muted} />
                )}
                <View style={styles.storyAddBadge}>
                  <Ionicons name="add" size={16} color="#fff" />
                </View>
              </View>
              <Text style={[styles.storyName, darkMode && styles.storyNameDark]} numberOfLines={1}>
                {profile.name.split(' ')[0]} (You)
              </Text>
            </Pressable>
          )}
          {storyGroups.map((group: any) => {
            const cover = group.stories[0];
            const viewed = group.stories.every((story: any) => story.viewed);
            return (
              <Pressable
                key={group.authorId}
                style={styles.storyItem}
                onPress={() => openStory(group.authorId)}
              >
                <View style={[styles.storyRing, viewed && styles.storyViewed]}>
                  <Image
                    source={{
                      uri: resolveImageUrl(group.mine ? profile.avatarUri : group.avatarUrl) || cover.media_url || undefined,
                    }}
                    style={styles.storyAvatar}
                  />
                  {group.mine && (
                    <Pressable
                      style={styles.storyAddBadge}
                      onPress={(event) => {
                        event.stopPropagation();
                        chooseStoryAudience();
                      }}
                    >
                      {storyUploading ? (
                        <ActivityIndicator size="small" color="#fff" />
                      ) : (
                        <Ionicons name="add" size={16} color="#fff" />
                      )}
                    </Pressable>
                  )}
                </View>
                <Text
                  style={[styles.storyName, darkMode && styles.storyNameDark]}
                  numberOfLines={1}
                >
                  {group.mine
                    ? `${profile.name.split(' ')[0]} (You)`
                    : group.authorName || 'Member'}
                </Text>
              </Pressable>
            );
          })}
        </ScrollView>
      </Animated.View>
      {!storyRailOpen && (
        <Animated.View
          {...storyHandlePan.panHandlers}
          style={[
            styles.storyRailHandlePosition,
            { transform: [{ translateX: storyHandleX }, { translateY: storyHandleY }] },
          ]}
        >
          <Pressable
            accessibilityRole="button"
            accessibilityLabel="Open stories. Long press to move this button."
            onPress={() => setRailOpen(true)}
            onLongPress={() => {
              storyHandleDragging.current = true;
            }}
            delayLongPress={280}
            style={({ pressed }) => [
              styles.storyRailHandle,
              {
                width: 24,
                height: 90,
                flexDirection: 'column',
                justifyContent: 'space-between',
                alignItems: 'center',
                paddingVertical: 8,
                paddingHorizontal: 0,
                borderTopRightRadius: storyRailSide === 'left' ? 12 : 0,
                borderBottomRightRadius: storyRailSide === 'left' ? 12 : 0,
                borderTopLeftRadius: storyRailSide === 'right' ? 12 : 0,
                borderBottomLeftRadius: storyRailSide === 'right' ? 12 : 0,
                backgroundColor: 'rgba(214, 51, 132, 0.45)',
                borderColor: 'rgba(255, 255, 255, 0.35)',
                borderWidth: 1.2,
                shadowOffset: storyRailSide === 'left' ? { width: 2, height: 2 } : { width: -2, height: 2 },
              },
              pressed && styles.storyRailHandlePressed,
            ]}
          >
            <Ionicons
              name={storyRailSide === 'left' ? 'chevron-forward' : 'chevron-back'}
              size={12}
              color="#fff"
              style={{ marginTop: 2 }}
            />
            <View style={{
              transform: [{ rotate: '-90deg' }],
              flexDirection: 'row',
              alignItems: 'center',
              gap: 3,
              width: 50,
              height: 20,
              justifyContent: 'center',
            }}>
              <Ionicons
                name="albums-outline"
                size={11}
                color="#fff"
              />
              <Text style={{ color: '#fff', fontSize: 9, fontWeight: '800', letterSpacing: 0.5 }}>
                Story
              </Text>
            </View>
            {!!storyGroups.length ? (
              <View
                style={{
                  width: 6,
                  height: 6,
                  borderRadius: 3,
                  backgroundColor: '#FF6B78',
                  borderWidth: 1,
                  borderColor: '#fff',
                  marginBottom: 2,
                }}
              />
            ) : (
              <View style={{ height: 6 }} />
            )}
          </Pressable>
        </Animated.View>
      )}
      {createMenuOpen && (
        <View style={styles.fabMenu}>
          <Pressable
            style={styles.fabAction}
            onPress={() => {
              setCreateMenuOpen(false);
              navigation.navigate('CreateCommunity');
            }}
          >
            <Text style={styles.fabLabel}>Create community</Text>
            <View style={styles.fabSmallButton}>
              <Ionicons name="people" size={21} color="#fff" />
            </View>
          </Pressable>
          <Pressable
            style={styles.fabAction}
            onPress={() => {
              setCreateMenuOpen(false);
              navigation.navigate('CreatePost');
            }}
          >
            <Text style={styles.fabLabel}>Create post</Text>
            <View style={styles.fabSmallButton}>
              <Ionicons name="create" size={21} color="#fff" />
            </View>
          </Pressable>
        </View>
      )}
      <Pressable
        accessibilityRole="button"
        accessibilityLabel={createMenuOpen ? 'Close create menu' : 'Open create menu'}
        onPress={() => setCreateMenuOpen((open) => !open)}
        style={({ pressed }) => [styles.fab, pressed && { opacity: 0.78 }]}
      >
        <Ionicons name={createMenuOpen ? 'close' : 'add'} size={30} color="#fff" />
      </Pressable>
      <Modal visible={Boolean(currentStory)} animationType="fade" statusBarTranslucent>
        {currentStory && activeStory !== null && (
          <View
            style={styles.storyViewer}
            onTouchStart={(event) => {
              storySwipeStart.current = event.nativeEvent.pageY;
            }}
            onTouchEnd={(event) => {
              if (event.nativeEvent.pageY - storySwipeStart.current > 90) setActiveStory(null);
            }}
          >
            <Image
              source={{ uri: currentStory.media_url }}
              style={styles.storyViewerImage}
              resizeMode="contain"
            />
            <LinearGradient
              pointerEvents="none"
              colors={['rgba(0,0,0,.82)', 'rgba(0,0,0,.35)', 'transparent']}
              style={styles.storyTopShade}
            />
            <LinearGradient
              pointerEvents="none"
              colors={['transparent', 'rgba(0,0,0,.38)', 'rgba(0,0,0,.86)']}
              style={styles.storyBottomShade}
            />
            {!!reactionBurst && (
              <Animated.View
                pointerEvents="none"
                style={[styles.storyReactionBurst, { transform: [{ scale: reactionScale }] }]}
              >
                <Text style={styles.storyReactionBurstText}>{reactionBurst}</Text>
              </Animated.View>
            )}
            <View style={styles.storyProgressRow}>
              {viewerStories.map((story, index) => (
                <View key={story.id} style={styles.storyProgress}>
                  <LinearGradient
                    colors={gradients.primary}
                    start={{ x: 0, y: 0 }}
                    end={{ x: 1, y: 0 }}
                    style={[
                      styles.storyProgressActive,
                      {
                        width:
                          index < activeStory
                            ? '100%'
                            : index === activeStory
                              ? `${storyProgress * 100}%`
                              : '0%',
                      },
                    ]}
                  />
                </View>
              ))}
            </View>
            <View style={styles.storyViewerHeader}>
              {currentStory.author_avatar_url ? (
                <Image
                  source={{ uri: currentStory.author_avatar_url }}
                  style={styles.storyViewerAvatar}
                />
              ) : (
                <View style={styles.storyViewerAvatarFallback}>
                  <Ionicons name="person" size={18} color="#fff" />
                </View>
              )}
              <View style={{ flex: 1 }}>
                <Text style={styles.storyViewerName}>{currentStory.author_name}</Text>
                <Text style={styles.storyViewerTime}>
                  {storyUploadTime(currentStory.created_at)}
                </Text>
              </View>
              {currentStory.mine && (
                <Pressable
                  style={styles.storyHeaderButton}
                  onPress={() =>
                    Alert.alert('Delete story?', 'This photo will be removed immediately.', [
                      { text: 'Cancel', style: 'cancel' },
                      {
                        text: 'Delete',
                        style: 'destructive',
                        onPress: () => {
                          const storyId = currentStory.id;
                          void storyApi
                            .remove(storyId)
                            .then(() => {
                              setStories((current) =>
                                current.filter((story) => story.id !== storyId),
                              );
                              setActiveStory(null);
                            })
                            .catch((error) => Alert.alert('Delete failed', error.message));
                        },
                      },
                    ])
                  }
                >
                  <Ionicons name="trash-outline" size={22} color="#fff" />
                </Pressable>
              )}
              {!currentStory.mine && (
                <Pressable
                  style={styles.storyHeaderButton}
                  onPress={() =>
                    Alert.alert('Report story', 'Why are you reporting this story?', [
                      { text: 'Cancel', style: 'cancel' },
                      {
                        text: 'Spam',
                        onPress: () =>
                          void safetyApi
                            .report('story', currentStory.id, 'Spam or scam')
                            .then(() => Alert.alert('Report submitted'))
                            .catch((error: any) => Alert.alert('Report failed', error.message)),
                      },
                      {
                        text: 'Inappropriate',
                        style: 'destructive',
                        onPress: () =>
                          void safetyApi
                            .report('story', currentStory.id, 'Inappropriate content')
                            .then(() => Alert.alert('Report submitted'))
                            .catch((error: any) => Alert.alert('Report failed', error.message)),
                      },
                    ])
                  }
                >
                  <Ionicons name="ellipsis-horizontal" size={24} color="#fff" />
                </Pressable>
              )}
              <Pressable style={styles.storyHeaderButton} onPress={() => setActiveStory(null)}>
                <Ionicons name="close" size={28} color="#fff" />
              </Pressable>
            </View>
            <Pressable
              style={styles.storyPrevious}
              delayLongPress={150}
              onPressIn={() => setStoryPaused(true)}
              onLongPress={() => {
                storyHeld.current = true;
              }}
              onPressOut={() => setStoryPaused(false)}
              onPress={() => {
                if (storyHeld.current) {
                  storyHeld.current = false;
                  return;
                }
                setActiveStory((current) => Math.max(0, (current || 0) - 1));
              }}
            />
            <Pressable
              style={styles.storyNext}
              delayLongPress={150}
              onPressIn={() => setStoryPaused(true)}
              onLongPress={() => {
                storyHeld.current = true;
              }}
              onPressOut={() => setStoryPaused(false)}
              onPress={() => {
                if (storyHeld.current) {
                  storyHeld.current = false;
                  return;
                }
                if (activeStory >= viewerStories.length - 1) {
                  setActiveStory(null);
                  setActiveStoryOwner(null);
                } else setActiveStory((current) => (current === null ? null : current + 1));
              }}
            />
            {currentStory.mine && (
              <Pressable style={styles.storyViews} onPress={() => setViewersOpen(true)}>
                <Ionicons name="eye-outline" size={18} color="#fff" />
                <Text style={styles.storyViewsText}>{currentStory.view_count || 0} views</Text>
              </Pressable>
            )}
            {!!Object.keys(currentStory.reaction_counts || {}).length && (
              <View style={styles.storyReactionSummary}>
                {Object.entries(currentStory.reaction_counts).map(([emoji, count]) => (
                  <Text key={emoji} style={styles.storyReactionCount}>
                    {emoji} {String(count)}
                  </Text>
                ))}
              </View>
            )}
            {!currentStory.mine && (
              <View style={styles.storyInteractionBar}>
                <TextInput
                  value={storyReply}
                  onChangeText={setStoryReply}
                  onFocus={() => setStoryPaused(true)}
                  onBlur={() => setStoryPaused(false)}
                  placeholder="Reply to story..."
                  placeholderTextColor="rgba(255,255,255,.65)"
                  style={styles.storyReplyInput}
                />
                {!!storyReply.trim() && (
                  <Pressable
                    onPress={() => {
                      const text = storyReply.trim();
                      setStoryReply('');
                      void storyApi
                        .reply(currentStory.id, text)
                        .then(() => Alert.alert('Reply sent'))
                        .catch((error) => Alert.alert('Reply failed', error.message));
                    }}
                  >
                    <Ionicons name="send" size={23} color="#fff" />
                  </Pressable>
                )}
                {['❤️', '😂', '🔥'].map((emoji) => (
                  <Pressable key={emoji} onPress={() => void reactToStory(currentStory.id, emoji)}>
                    <Text style={styles.storyReaction}>{emoji}</Text>
                  </Pressable>
                ))}
              </View>
            )}
            {viewersOpen && currentStory.mine && (
              <View style={styles.storyViewersSheet}>
                <View style={styles.storyViewersHeader}>
                  <Text style={styles.storyViewersTitle}>Viewers</Text>
                  <Pressable onPress={() => setViewersOpen(false)}>
                    <Ionicons name="close" size={25} color={colors.text} />
                  </Pressable>
                </View>
                {currentStory.viewers?.length ? (
                  <ScrollView contentContainerStyle={{ gap: 12 }}>
                    {currentStory.viewers.map((viewer: any) => (
                      <View key={viewer.id} style={styles.storyViewerRow}>
                        <Avatar name={viewer.name} uri={viewer.avatar_url} size={38} />
                        <Text style={styles.cardTitle}>{viewer.name}</Text>
                      </View>
                    ))}
                  </ScrollView>
                ) : (
                  <Text style={ui.muted}>No viewers yet.</Text>
                )}
              </View>
            )}
          </View>
        )}
      </Modal>

      {/* Daily Reward Modal */}
      <Modal
        visible={dailyRewardOpen}
        transparent
        animationType="fade"
        onRequestClose={() => setDailyRewardOpen(false)}
      >
        <View style={{ flex: 1, backgroundColor: 'rgba(0, 0, 0, 0.65)', justifyContent: 'center', alignItems: 'center', padding: 24 }}>
          <View style={{ backgroundColor: colors.surface, width: '100%', maxWidth: 360, borderRadius: 20, padding: 24, alignItems: 'center', gap: 16, elevation: 10 }}>
            <LinearGradient
              colors={['#8B6BD9', '#5B5CE2']}
              style={{ width: 70, height: 70, borderRadius: 35, alignItems: 'center', justifyContent: 'center', marginBottom: 8 }}
            >
              <Ionicons name="gift" size={36} color="#fff" />
            </LinearGradient>

            <Text style={[ui.h2, { textAlign: 'center', color: colors.text, fontSize: 20 }]}>
              Daily Login Rewards 🎁
            </Text>

            {dailyRewardData ? (
              <>
                <Text style={[ui.body, { textAlign: 'center', color: colors.text, fontSize: 14 }]}>
                  Day {dailyRewardData.streak_day} Claimed successfully! You received:
                </Text>
                
                <View style={{ flexDirection: 'row', alignItems: 'center', backgroundColor: colors.surfaceAlt, borderRadius: 12, paddingHorizontal: 16, paddingVertical: 10, gap: 6, marginVertical: 4 }}>
                  <Ionicons name="logo-bitcoin" size={20} color={colors.primary} />
                  <Text style={{ fontSize: 18, fontWeight: '800', color: colors.primary }}>
                    +{dailyRewardData.coins_awarded} Coins
                  </Text>
                </View>

                {/* Day streak visual map */}
                <View style={{ flexDirection: 'row', gap: 6, marginVertical: 8, justifyContent: 'center', width: '100%' }}>
                  {[1, 2, 3, 4, 5, 6, 7].map((day) => {
                    const active = day <= dailyRewardData.streak_day;
                    const rewardAmt = day === 7 ? 50 : day * 5;
                    return (
                      <View key={day} style={{ flex: 1, alignItems: 'center', gap: 4 }}>
                        <View
                          style={{
                            width: 32,
                            height: 32,
                            borderRadius: 16,
                            backgroundColor: active ? colors.primary : '#EBEBEB',
                            alignItems: 'center',
                            justifyContent: 'center'
                          }}
                        >
                          <Text style={{ color: '#fff', fontSize: 10, fontWeight: '800' }}>
                            D{day}
                          </Text>
                        </View>
                        <Text style={{ fontSize: 9, fontWeight: '700', color: active ? colors.primary : colors.muted }}>
                          {rewardAmt}🪙
                        </Text>
                      </View>
                    );
                  })}
                </View>

                <Text style={[ui.muted, { fontSize: 11, textAlign: 'center' }]}>
                  Come back tomorrow to continue your streak! Day 7 gives 50 free coins!
                </Text>
              </>
            ) : (
              <ActivityIndicator size="large" color={colors.primary} />
            )}

            <View style={{ width: '100%', marginTop: 12 }}>
              <Button
                title="Awesome!"
                tone="primary"
                onPress={() => setDailyRewardOpen(false)}
              />
            </View>
          </View>
        </View>
      </Modal>
    </Screen>
  );
}

export default HomeScreen;
