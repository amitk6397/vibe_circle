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

export function PostDetailsScreen({ navigation, route }: any) {
  const post = useAppStore((s) => s.posts.find((x) => x.id === route.params.postId));
  const allComments = useAppStore((state) => state.comments);
  const comments = allComments.filter((item) => item.postId === route.params.postId);
  const [comment, setComment] = useState('');
  const [replyTo, setReplyTo] = useState<any>(null);
  const [commentBusy, setCommentBusy] = useState(false);
  const [commentsLoading, setCommentsLoading] = useState(true);
  const [commentsError, setCommentsError] = useState('');
  useEffect(() => {
    let active = true;
    contentApi
      .comments(route.params.postId)
      .then(({ data }) => {
        if (!active) return;
        useAppStore.setState((state) => ({
          comments: [
            ...state.comments.filter((item) => item.postId !== route.params.postId),
            ...data.map((item: any) => ({
              id: item.id,
              postId: item.post_id,
              author: item.author_name || 'Member',
              authorUsername: item.author_username || undefined,
              authorId: item.author_id,
              body: item.body,
              time: new Date(item.created_at).toLocaleString(),
              parentId: item.parent_id || undefined,
              likes: item.like_count,
              liked: item.liked,
              mine: item.mine,
            })),
          ],
        }));
      })
      .catch((error) => active && setCommentsError(error.message || 'Could not load comments.'))
      .finally(() => active && setCommentsLoading(false));
    return () => {
      active = false;
    };
  }, [route.params.postId]);
  if (!post)
    return (
      <Screen>
        <Header title="Post" onBack={() => navigation.goBack()} />
        <EmptyState
          title="Post unavailable"
          text="It may have been removed by its author or a moderator."
        />
      </Screen>
    );
  return (
    <Screen>
      <Header
        title="Discussion"
        onBack={() => navigation.goBack()}
        right={
          <IconButton
            icon="ellipsis-horizontal"
            onPress={() => reportAlert('post', post.id, 'this post')}
          />
        }
      />
      <PostCard post={post} />
      <Section title="Comments" />
      {commentsLoading && <ChatSkeleton />}
      {!!commentsError && (
        <EmptyState
          icon="cloud-offline-outline"
          title="Could not load comments"
          text={commentsError}
        />
      )}
      {!commentsLoading && !commentsError && comments.length ? (
        comments.map((item) => (
          <Card key={item.id} style={item.parentId ? { marginLeft: 28 } : undefined}>
            <View style={{ flexDirection: 'row', alignItems: 'center', gap: 6, marginBottom: 2 }}>
              <Text style={styles.cardTitle}>{item.author}</Text>
              {item.authorUsername && (
                <Text style={{ fontSize: 11, color: colors.accent, fontWeight: '600' }}>
                  @{item.authorUsername}
                </Text>
              )}
            </View>
            <Text style={ui.body}>{item.body}</Text>
            <Text style={styles.time}>{item.time}</Text>
            <View style={styles.listRow}>
              <Pressable
                onPress={async () => {
                  const { data } = await contentApi.toggleCommentLike(item.id);
                  useAppStore.setState((state) => ({
                    comments: state.comments.map((value) =>
                      value.id === item.id
                        ? { ...value, liked: data.liked, likes: data.like_count }
                        : value,
                    ),
                  }));
                }}
                style={({ pressed }) => [
                  { flexDirection: 'row', alignItems: 'center', gap: 5 },
                  pressed && { opacity: 0.45 },
                ]}
              >
                <Ionicons
                  name={item.liked ? 'heart' : 'heart-outline'}
                  color={item.liked ? colors.accent : colors.muted}
                />
                <Text style={styles.time}>{item.likes || 0}</Text>
              </Pressable>
              <Pressable
                onPress={() => setReplyTo(item)}
                style={({ pressed }) => [
                  { flexDirection: 'row', alignItems: 'center', gap: 5 },
                  pressed && { opacity: 0.45 },
                ]}
              >
                <Text style={styles.link}>Reply</Text>
              </Pressable>
              {item.mine && (
                <Pressable
                  onPress={() =>
                    Alert.alert('Delete comment?', 'This cannot be undone.', [
                      { text: 'Cancel', style: 'cancel' },
                      {
                        text: 'Delete',
                        style: 'destructive',
                        onPress: () =>
                          void contentApi.deleteComment(item.id).then(() =>
                            useAppStore.setState((state) => ({
                              comments: state.comments.filter((value) => value.id !== item.id),
                            })),
                          ),
                      },
                    ])
                  }
                >
                  <Text style={[styles.link, { color: colors.danger }]}>Delete</Text>
                </Pressable>
              )}
              {post.mine && post.bountyStatus === 'open' && (item as any).authorId !== post.authorId && (
                <Pressable
                  onPress={() =>
                    Alert.alert(
                      'Award Bounty? 🏆',
                      `Do you want to award the ${post.bountyAmount} coins bounty to ${item.author}?`,
                      [
                        { text: 'Cancel', style: 'cancel' },
                        {
                          text: 'Award',
                          onPress: async () => {
                            try {
                              const { data } = await contentApi.awardBounty(post.id, item.id);
                              useAppStore.setState((state) => ({
                                posts: state.posts.map((p) =>
                                  p.id === post.id
                                    ? {
                                        ...p,
                                        bountyStatus: data.status,
                                        bountyWinnerCommentId: data.bounty_winner_comment_id,
                                      }
                                    : p,
                                ),
                              }));
                              Alert.alert('Bounty Awarded! 🏆', `${item.author} has won the bounty.`);
                            } catch (error: any) {
                              Alert.alert('Award failed', error.message || 'Please try again.');
                            }
                          },
                        },
                      ],
                    )
                  }
                >
                  <Text style={[styles.link, { color: '#E65100', fontWeight: '800' }]}>Award Bounty 🏆</Text>
                </Pressable>
              )}
            </View>
          </Card>
        ))
      ) : !commentsLoading && !commentsError ? (
        <EmptyState
          icon="chatbubble-outline"
          title="No comments yet"
          text="Start a respectful discussion."
        />
      ) : null}
      <Field
        label={replyTo ? `Replying to ${replyTo.author}` : 'Add a respectful comment'}
        value={comment}
        onChangeText={setComment}
        multiline
        placeholder="Write your reply..."
      />
      <Button
        title={replyTo ? 'Post reply' : 'Post comment'}
        loading={commentBusy}
        disabled={!comment.trim() || commentBusy}
        onPress={async () => {
          setCommentBusy(true);
          try {
            const { data } = await contentApi.addComment(post.id, comment.trim(), replyTo?.id);
            useAppStore.setState((state) => ({
              comments: [
                ...state.comments,
                {
                  id: data.id,
                  postId: post.id,
                  author: state.profile.name,
                  authorUsername: state.profile.username,
                  body: data.body,
                  time: 'Just now',
                  parentId: data.parent_id,
                  likes: 0,
                  liked: false,
                  mine: true,
                },
              ],
            }));
            setComment('');
            setReplyTo(null);
          } catch (error: any) {
            Alert.alert('Could not post comment', error.message);
          } finally {
            setCommentBusy(false);
          }
        }}
      />
      {replyTo && <Button title="Cancel reply" tone="ghost" onPress={() => setReplyTo(null)} />}
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

export default PostDetailsScreen;
