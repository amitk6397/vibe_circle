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

export function CommunityDetailsScreen({ navigation, route }: any) {
  const communities = useAppStore((state) => state.communities);
  const posts = useAppStore((state) => state.posts);
  const community = communities.find((x) => x.id === route.params.communityId);
  const joined = useAppStore((state) => state.joinedCommunities.includes(route.params.communityId));
  const [shareOpen, setShareOpen] = useState(false);
  const [feedFilter, setFeedFilter] = useState<'Latest' | 'Popular' | 'Unanswered' | 'Polls'>(
    'Latest',
  );
  const [subStatus, setSubStatus] = useState<any>(null);
  useEffect(() => {
    let active = true;
    contentApi.communitySubscriptionStatus(route.params.communityId)
      .then(({ data }) => {
        if (active) setSubStatus(data);
      })
      .catch(() => undefined);
    return () => {
      active = false;
    };
  }, [route.params.communityId]);
  useEffect(() => {
    let active = true;
    contentApi
      .posts(route.params.communityId)
      .then(({ data }) => {
        if (!active) return;
        const communityName =
          communities.find((item) => item.id === route.params.communityId)?.name || '';
        const mapped: Post[] = data.map((item: any) => ({
          id: item.id,
          author: item.author_name,
          authorId: item.author_id,
          mine: item.mine,
          community: item.community_name,
          body: item.body,
          likes: item.like_count,
          comments: item.comment_count,
          anonymous: item.anonymous,
          authorAvatarUrl: item.author_avatar_url,
          liked: item.liked,
          saved: item.saved,
          postType: `${item.type[0].toUpperCase()}${item.type.slice(1)}` as Post['postType'],
          pollOptions: item.poll_options,
          pollResults: item.poll_results,
          myVote: item.my_vote,
          createdAt: item.created_at,
          visibility: item.visibility,
          coinPrice: item.coin_price,
          locked: item.locked,
          attachment: item.media_url
            ? { id: item.id, kind: 'image', uri: item.media_url, name: 'Post image' }
            : undefined,
          tipCount: item.tip_count,
          tipTotal: item.tip_total,
          isBoosted: item.is_boosted,
          boostedUntil: item.boosted_until,
          boostCost: item.boost_cost,
          bountyAmount: item.bounty_amount,
          bountyStatus: item.bounty_status,
          bountyWinnerCommentId: item.bounty_winner_comment_id,
        }));
        useAppStore.setState((state) => ({
          posts: [...state.posts.filter((post) => post.community !== communityName), ...mapped],
        }));
      })
      .catch(() => undefined);
    return () => {
      active = false;
    };
  }, [communities, route.params.communityId]);
  if (!community)
    return (
      <Screen>
        <Header title="Community" onBack={() => navigation.goBack()} />
        <EmptyState title="Community unavailable" text="Refresh and try again." />
      </Screen>
    );
  return (
    <Screen>
      <Header
        title="Community"
        onBack={() => navigation.goBack()}
        right={
          <View style={{ flexDirection: 'row', gap: 8 }}>
            <IconButton icon="share-social-outline" onPress={() => setShareOpen(true)} />
            <IconButton
              icon="ellipsis-horizontal"
              onPress={() => reportAlert('community', community.id, community.name)}
            />
          </View>
        }
      />
      <View style={[styles.communityCover, { backgroundColor: community.color }]}>
        {community.coverUrl && (
          <Image source={{ uri: community.coverUrl }} style={styles.communityCoverImage} />
        )}
        {community.logoUrl ? (
          <Image source={{ uri: community.logoUrl }} style={styles.communityLogo} />
        ) : (
          <Ionicons name="people" size={45} color="#fff" />
        )}
        <Text style={styles.coverTitle}>{community.name}</Text>
        {community.kind === 'circle' && (
          <View style={styles.circlePrivacyBadge}>
            <Ionicons name="lock-closed" size={13} color="#fff" />
            <Text style={styles.circlePrivacyText}>PRIVATE CIRCLE</Text>
          </View>
        )}
        <Text style={styles.coverText}>
          {community.members.toLocaleString()} members · {community.category}
        </Text>
      </View>
      {community.kind !== 'circle' && ['private', 'premium'].includes(community.privacy || '') && (
        <Card>
          <Text style={ui.h2}>VIP Premium Community</Text>
          {subStatus ? (
            subStatus.isSubscribed ? (
              <Text style={[ui.body, { color: colors.success }]}>
                🔓 Active VIP Access! Expires: {subStatus.expiresAt ? new Date(subStatus.expiresAt).toLocaleDateString() : 'Lifetime'}
              </Text>
            ) : (
              <Text style={ui.body}>
                Unlock VIP group for {subStatus.premiumPrice || community.premiumPrice || 0} coins for {subStatus.renewalDays} days.
              </Text>
            )
          ) : (
            <Text style={ui.body}>
              Unlock VIP group for {community.premiumPrice || 0} coins.
            </Text>
          )}
        </Card>
      )}
      <Text style={ui.body}>{community.description}</Text>
      {!!community.tags?.length && (
        <View style={ui.wrap}>
          {community.tags.map((tag) => (
            <Pill key={tag} label={`#${tag}`} />
          ))}
        </View>
      )}
      {(community.location || community.language) && (
        <Text style={styles.smallMuted}>
          {[community.location, community.language].filter(Boolean).join(' · ')}
        </Text>
      )}
      {joined ? (
        <>
          <Card style={styles.joinedBanner}>
            <View style={styles.joinedTitleRow}>
              <View style={styles.joinedCheck}>
                <Ionicons name="checkmark" size={18} color="#fff" />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.cardTitle}>You're a community member</Text>
                <Text style={styles.smallMuted}>
                  Join the group chat, meet members, or share a post.
                </Text>
              </View>
            </View>
            <View style={styles.communityActionGrid}>
              <Pressable
                style={styles.communityAction}
                onPress={() => navigation.navigate('CommunityChat', { communityId: community.id })}
              >
                <View style={[styles.communityActionIcon, { backgroundColor: '#E8E9FF' }]}>
                  <Ionicons name="chatbubbles" size={22} color={colors.primary} />
                </View>
                <Text style={styles.communityActionTitle}>Group chat</Text>
                <Text style={styles.communityActionText}>Message everyone</Text>
              </Pressable>
              <Pressable
                style={styles.communityAction}
                onPress={() =>
                  navigation.navigate('CommunityMembers', { communityId: community.id })
                }
              >
                <View style={[styles.communityActionIcon, { backgroundColor: '#E8F8F2' }]}>
                  <Ionicons name="people" size={22} color={colors.success} />
                </View>
                <Text style={styles.communityActionTitle}>Members</Text>
                <Text style={styles.communityActionText}>Find people</Text>
              </Pressable>
              {community.isOwner && (
                <Pressable
                  style={styles.communityAction}
                  onPress={() =>
                    navigation.navigate('CommunityJoinRequests', { communityId: community.id })
                  }
                >
                  <View style={[styles.communityActionIcon, { backgroundColor: '#FFF3DD' }]}>
                    <Ionicons name="person-add" size={22} color="#D88712" />
                  </View>
                  <Text style={styles.communityActionTitle}>Join requests</Text>
                  <Text style={styles.communityActionText}>Review access</Text>
                </Pressable>
              )}
              {community.isOwner && community.kind === 'circle' && (
                <Pressable
                  style={styles.communityAction}
                  onPress={() =>
                    navigation.navigate('InviteCircleMembers', { communityId: community.id })
                  }
                >
                  <View style={[styles.communityActionIcon, { backgroundColor: '#F0ECFF' }]}>
                    <Ionicons name="person-add" size={22} color={colors.primary} />
                  </View>
                  <Text style={styles.communityActionTitle}>Invite people</Text>
                  <Text style={styles.communityActionText}>
                    {community.members}/{community.maxMembers || 50} members
                  </Text>
                </Pressable>
              )}
            </View>
          </Card>
          <Button
            title="Create a post here"
            icon="create"
            onPress={() => navigation.navigate('CreatePost', { communityId: community.id })}
          />
        </>
      ) : (
        <Button
          title={
            community.joinPending
              ? 'Request pending'
              : community.privacy === 'private'
                ? community.kind === 'circle'
                  ? 'Invite only'
                  : subStatus?.isSubscribed
                    ? 'Join community (VIP Unlocked)'
                    : `Unlock for ${community.premiumPrice || 0} coins`
                : community.privacy === 'request'
                  ? 'Request to join'
                  : community.privacy === 'premium'
                    ? subStatus?.isSubscribed
                      ? 'Join community (VIP Unlocked)'
                      : `Unlock for ${community.premiumPrice || 0} coins`
                    : 'Join community'
          }
          icon="person-add-outline"
          disabled={
            community.joinPending ||
            (community.privacy === 'private' && community.kind === 'circle')
          }
          onPress={() => {
            const isPremium = community.privacy === 'private' || community.privacy === 'premium';
            if (isPremium && (community.premiumPrice ?? 0) > 0 && !subStatus?.isSubscribed) {
              Alert.alert(
                'Join VIP Community 💎',
                `Join this VIP group for ${community.premiumPrice} coins/month?`,
                [
                  { text: 'Cancel', style: 'cancel' },
                  {
                    text: 'Confirm & Pay',
                    onPress: () => {
                      void useAppStore
                        .getState()
                        .toggleCommunity(community.id)
                        .then(() => {
                          // Refresh subscription status
                          contentApi.communitySubscriptionStatus(community.id)
                            .then(({ data }) => setSubStatus(data))
                            .catch(() => undefined);
                        })
                        .catch((error) => Alert.alert('Could not join', error.message));
                    },
                  },
                ],
              );
            } else {
              void useAppStore
                .getState()
                .toggleCommunity(community.id)
                .catch((error) => Alert.alert('Could not join', error.message));
            }
          }}
        />
      )}
      <Card>
        <Text style={ui.h2}>Community rules</Text>
        {(community.rules?.length
          ? community.rules
          : ['Be kind and stay on topic', 'No spam', 'Report unsafe content']
        ).map((x, i) => (
          <View key={x} style={styles.rule}>
            <Text style={styles.ruleNumber}>{i + 1}</Text>
            <Text style={[ui.body, { flex: 1 }]}>{x}</Text>
          </View>
        ))}
      </Card>
      <Section title="Community posts" />
      <View style={ui.wrap}>
        {(['Latest', 'Popular', 'Unanswered', 'Polls'] as const).map((item) => (
          <Pill
            key={item}
            label={item}
            selected={feedFilter === item}
            onPress={() => setFeedFilter(item)}
          />
        ))}
      </View>
      {posts
        .filter((post) => post.community === community.name)
        .filter((post) =>
          feedFilter === 'Unanswered'
            ? post.comments === 0
            : feedFilter === 'Polls'
              ? post.postType === 'Poll'
              : true,
        )
        .sort((first, second) => {
          if (feedFilter === 'Popular') {
            return second.likes + second.comments - first.likes - first.comments;
          }
          const isBoosted = (p: Post) => {
            if (!p.isBoosted || !p.boostedUntil) return false;
            return new Date(p.boostedUntil).getTime() > Date.now();
          };
          const firstBoosted = isBoosted(first);
          const secondBoosted = isBoosted(second);
          if (firstBoosted && !secondBoosted) return -1;
          if (!firstBoosted && secondBoosted) return 1;
          return new Date(second.createdAt || 0).getTime() - new Date(first.createdAt || 0).getTime();
        })
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
        ))}
      {joined &&
        (community.isOwner ? (
          <Button
            title={community.kind === 'circle' ? 'Delete private circle' : 'Delete community'}
            tone="danger"
            onPress={() =>
              Alert.alert(
                community.kind === 'circle' ? 'Delete circle?' : 'Delete community?',
                'This will delete everything and cannot be undone.',
                [
                  { text: 'Cancel', style: 'cancel' },
                  {
                    text: 'Delete',
                    style: 'destructive',
                    onPress: () =>
                      useAppStore
                        .getState()
                        .deleteCommunity(community.id)
                        .then(() => {
                          Alert.alert('Success', 'Deleted successfully.');
                          navigation.goBack();
                        })
                        .catch((err) => Alert.alert('Error', err.message)),
                  },
                ],
              )
            }
          />
        ) : (
          <Button
            title="Leave community"
            tone="danger"
            onPress={() =>
              Alert.alert('Leave community?', 'You will lose access to its group chat.', [
                { text: 'Cancel', style: 'cancel' },
                {
                  text: 'Leave',
                  style: 'destructive',
                  onPress: () => useAppStore.getState().toggleCommunity(community.id),
                },
              ])
            }
          />
        ))}
      <ShareModal
        visible={shareOpen}
        onClose={() => setShareOpen(false)}
        targetId={community.id}
        type="community"
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

export default CommunityDetailsScreen;
