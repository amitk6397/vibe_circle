import React, { useEffect, useState } from 'react';

import { Alert, Image, Pressable, StyleSheet, Switch, Text, View } from 'react-native';

import { Ionicons } from '@expo/vector-icons';

import {
  Avatar,
  Button,
  Card,
  EmptyState,
  Field,
  Header,
  PersonCard,
  Pill,
  Screen,
  ui,
} from '../../../components/ui';

import { ChatSkeleton } from '../../../components/ChatSkeleton';

import { INTERESTS, LANGUAGES } from '../../../constants/data';

import { colors } from '../../../theme';

import { useAppStore } from '../../../store/useAppStore';

import { requiredTextError, usernameError } from '../../../utils/validation';

import { formatFileSize, pickDocument, pickImage } from '../../../services/mediaPicker';

import { LocalAttachment } from '../../../types';

import {
  accountApi,
  appContentApi,
  contentApi,
  matchingApi,
  notificationsApi,
  safetyApi,
  uploadAttachment,
  usersApi,
} from '../../../services/api';

import { tokenStorage } from '../../../services/tokenStorage';

export function MyActivityScreen({ navigation }: any) {
  const [activity, setActivity] = useState<any>(null);
  const [tab, setTab] = useState<'posts' | 'comments' | 'saved'>('posts');
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const load = () => {
    setLoading(true);
    setError('');
    usersApi
      .activity()
      .then(({ data }) => setActivity(data))
      .catch((reason) => setError(reason.message || 'Could not load activity.'))
      .finally(() => setLoading(false));
  };
  useEffect(load, []);
  const items = activity ? activity[tab] : [];
  const openPost = async (postId: string) => {
    try {
      const { data } = await contentApi.details(postId);
      const post = {
        id: data.id,
        author: data.author_name,
        authorId: data.author_id,
        community: data.community_name,
        body: data.body,
        likes: data.like_count,
        comments: data.comment_count,
        anonymous: data.anonymous,
        authorAvatarUrl: data.author_avatar_url,
        liked: data.liked,
        saved: data.saved,
        postType: `${data.type[0].toUpperCase()}${data.type.slice(1)}`,
        pollOptions: data.poll_options,
        pollResults: data.poll_results,
        myVote: data.my_vote,
        createdAt: data.created_at,
        attachment: data.media_url
          ? { id: data.id, kind: 'image', uri: data.media_url, name: 'Post image' }
          : undefined,
      } as any;
      useAppStore.setState((state) => ({
        posts: [post, ...state.posts.filter((item) => item.id !== post.id)],
      }));
      navigation.navigate('PostDetails', { postId });
    } catch (reason: any) {
      Alert.alert('Post unavailable', reason.message || 'This post could not be opened.');
    }
  };
  return (
    <Screen>
      <Header title="My activity" onBack={() => navigation.goBack()} />
      <View style={ui.wrap}>
        <Pill
          label={`Posts ${activity?.counts.posts ?? 0}`}
          selected={tab === 'posts'}
          onPress={() => setTab('posts')}
        />
        <Pill
          label={`Comments ${activity?.counts.comments ?? 0}`}
          selected={tab === 'comments'}
          onPress={() => setTab('comments')}
        />
        <Pill
          label={`Saved ${activity?.counts.saved ?? 0}`}
          selected={tab === 'saved'}
          onPress={() => setTab('saved')}
        />
      </View>
      {loading && <ChatSkeleton />}
      {!!error && (
        <EmptyState
          icon="cloud-offline-outline"
          title="Could not load activity"
          text={error}
          action="Try again"
          onAction={load}
        />
      )}
      {!loading &&
        !error &&
        tab === 'posts' &&
        items.map((x: any) => (
          <Card key={x.id} onPress={() => void openPost(x.id)}>
            <Text style={ui.body}>{x.body}</Text>
            {!!x.media_url && <Image source={{ uri: x.media_url }} style={styles.activityImage} />}
            <Text style={ui.muted}>
              {x.likes} likes · {x.comments} comments
            </Text>
          </Card>
        ))}
      {!loading &&
        !error &&
        tab === 'comments' &&
        items.map((x: any) => (
          <Card key={x.id} onPress={() => x.post && void openPost(x.post_id)}>
            <Text style={styles.activityLabel}>Your comment</Text>
            <Text style={ui.body}>{x.body}</Text>
            {x.post && (
              <View style={styles.activityContext}>
                <Text style={styles.activityLabel}>On {x.post.author_name}'s post</Text>
                <Text style={ui.body} numberOfLines={3}>
                  {x.post.body}
                </Text>
                {!!x.post.media_url && (
                  <Image source={{ uri: x.post.media_url }} style={styles.activityImage} />
                )}
              </View>
            )}
            <Text style={ui.muted}>{new Date(x.created_at).toLocaleString()}</Text>
          </Card>
        ))}
      {!loading &&
        !error &&
        tab === 'saved' &&
        items.map((item: any) => (
          <Card key={item.id} onPress={() => void openPost(item.id)}>
            <Text style={ui.body}>{item.body}</Text>
            {!!item.media_url && (
              <Image source={{ uri: item.media_url }} style={styles.activityImage} />
            )}
            <Text style={ui.muted}>
              {item.likes} likes · {item.comments} comments
            </Text>
          </Card>
        ))}
      {!loading && !error && !items.length && (
        <EmptyState
          icon="file-tray-outline"
          title="No activity yet"
          text={`Your ${tab} will appear here.`}
        />
      )}
    </Screen>
  );
}

function Setting({
  title,
  subtitle,
  value,
  onValueChange,
}: {
  title: string;
  subtitle?: string;
  value: boolean;
  onValueChange: (value: boolean) => void;
}) {
  return (
    <View style={styles.setting}>
      <View style={{ flex: 1 }}>
        <Text style={styles.menuTitle}>{title}</Text>
        {subtitle && <Text style={ui.muted}>{subtitle}</Text>}
      </View>
      <Switch value={value} onValueChange={onValueChange} trackColor={{ true: colors.primary }} />
    </View>
  );
}

function Menu({
  title,
  icon,
  onPress = () => {},
}: {
  title: string;
  icon: string;
  onPress?: () => void;
}) {
  return (
    <Pressable onPress={onPress} style={styles.setting}>
      <Ionicons name={icon as any} size={21} color={colors.primary} />
      <Text style={[styles.menuTitle, { flex: 1 }]}>{title}</Text>
      <Ionicons name="chevron-forward" color={colors.muted} />
    </Pressable>
  );
}

function CallControl({ icon, label, onPress, danger, active }: any) {
  return (
    <Pressable onPress={onPress} style={{ alignItems: 'center', gap: 7 }}>
      <View
        style={[
          styles.callControl,
          danger && { backgroundColor: colors.danger },
          active && !danger && { backgroundColor: colors.success },
        ]}
      >
        <Ionicons name={icon} size={24} color="#fff" />
      </View>
      <Text style={styles.callControlText}>{label}</Text>
    </Pressable>
  );
}

function Stat({ value, label }: { value: number; label: string }) {
  return (
    <View style={styles.stat}>
      <Text style={styles.statValue}>{value}</Text>
      <Text style={ui.muted}>{label}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  actionRow: { gap: 10 },
  communityColor: { width: 38, height: 38, borderRadius: 19 },
  communityColorSelected: { borderWidth: 4, borderColor: '#fff', elevation: 4 },
  communityCoverPreview: {
    width: '100%',
    height: 150,
    borderRadius: 18,
    backgroundColor: colors.surfaceAlt,
  },
  actions: { flexDirection: 'row', gap: 10, marginTop: 12, marginBottom: 18 },
  stars: { flexDirection: 'row', justifyContent: 'center', gap: 8, marginVertical: 24 },
  media: {
    minHeight: 250,
    borderRadius: 22,
    borderWidth: 2,
    borderStyle: 'dashed',
    borderColor: '#CFD3E2',
    alignItems: 'center',
    justifyContent: 'center',
    padding: 30,
    gap: 12,
  },
  mediaPreviewCard: { alignItems: 'center', gap: 10 },
  mediaPreviewImage: {
    width: '100%',
    height: 340,
    borderRadius: 18,
    backgroundColor: colors.border,
  },
  documentPreview: {
    width: '100%',
    height: 220,
    borderRadius: 18,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  center: { textAlign: 'center' },
  profile: { alignItems: 'center', gap: 8, paddingVertical: 18 },
  setting: {
    minHeight: 62,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 12,
    borderBottomWidth: 1,
    borderBottomColor: colors.border,
  },
  menuTitle: { color: colors.text, fontSize: 15, fontWeight: '700' },
  supportArticle: { gap: 16, padding: 20 },
  supportIcon: {
    width: 58,
    height: 58,
    borderRadius: 18,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
  },
  supportBody: { color: colors.text, fontSize: 16, lineHeight: 26 },
  row: { flexDirection: 'row', alignItems: 'center', gap: 12 },
  activityLabel: { color: colors.primary, fontSize: 12, fontWeight: '800' },
  activityContext: {
    gap: 8,
    padding: 12,
    borderRadius: 14,
    backgroundColor: colors.surfaceAlt,
  },
  activityImage: {
    width: '100%',
    height: 180,
    borderRadius: 14,
    backgroundColor: colors.border,
  },
  stats: { flexDirection: 'row', gap: 10 },
  stat: {
    flex: 1,
    alignItems: 'center',
    padding: 16,
    backgroundColor: colors.surface,
    borderRadius: 16,
    borderWidth: 1,
    borderColor: colors.border,
  },
  statValue: { color: colors.text, fontSize: 24, fontWeight: '900' },
  call: { flex: 1, backgroundColor: '#101326', padding: 22, justifyContent: 'space-between' },
  callBack: {
    marginTop: 28,
    width: 46,
    height: 46,
    borderRadius: 23,
    backgroundColor: 'rgba(255,255,255,.12)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  callPerson: { alignItems: 'center', gap: 12 },
  callName: { color: '#fff', fontSize: 28, fontWeight: '900' },
  callStatus: { color: '#AEB3CA' },
  callControls: { flexDirection: 'row', justifyContent: 'space-around', alignItems: 'center' },
  callControl: {
    width: 58,
    height: 58,
    borderRadius: 29,
    backgroundColor: '#34384F',
    alignItems: 'center',
    justifyContent: 'center',
  },
  callControlText: { color: '#D9DCEC', fontSize: 11 },
  callSafety: { color: '#8F95AC', fontSize: 11, textAlign: 'center', marginBottom: 12 },
  error: { color: colors.danger, backgroundColor: '#FFF0F2', padding: 12, borderRadius: 12 },
});

export default MyActivityScreen;
