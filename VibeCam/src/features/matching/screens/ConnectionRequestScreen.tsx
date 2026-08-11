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

export function ConnectionRequestScreen({ navigation }: any) {
  const people = useAppStore((state) => state.people);
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [requests, setRequests] = useState<any[]>([]);
  const [requesters, setRequesters] = useState<Record<string, any>>({});
  const [loading, setLoading] = useState(true);
  const [busyAction, setBusyAction] = useState('');
  const [error, setError] = useState('');
  const load = () => {
    setLoading(true);
    setError('');
    usersApi
      .connections()
      .then(async ({ data }) => {
        const pending = data.filter(
          (item) => item.status === 'pending' && item.receiver_id === currentUserId,
        );
        setRequests(pending);
        // Fetch any requesters not in local store
        const missing = pending
          .map((r) => r.requester_id)
          .filter((id) => !people.find((p) => p.id === id));
        if (missing.length) {
          const fetched: Record<string, any> = {};
          await Promise.allSettled(
            missing.map((id) =>
              usersApi.publicProfile(id).then(({ data: u }) => {
                fetched[u.id] = u;
              }),
            ),
          );
          setRequesters((prev) => ({ ...prev, ...fetched }));
        }
      })
      .catch((reason) => setError(reason.message || 'Could not load requests.'))
      .finally(() => setLoading(false));
  };
  useEffect(load, [currentUserId]);
  const respond = async (request: any, action: 'accept' | 'reject') => {
    setBusyAction(`${request.id}:${action}`);
    try {
      await usersApi.connectionAction(request.id, action);
      setRequests((items) => items.filter((item) => item.id !== request.id));
      if (action === 'accept') {
        await notificationsApi.markAllRead();
        useAppStore.setState({ notifications: 0 });
      }
    } catch (reason: any) {
      Alert.alert('Could not update request', reason.message || 'Please try again.');
    } finally {
      setBusyAction('');
    }
  };
  return (
    <Screen>
      <Header
        title="Follow requests"
        subtitle="People who want to follow you"
        onBack={() => navigation.goBack()}
      />
      {loading && <ChatSkeleton />}
      {!!error && (
        <EmptyState
          icon="cloud-offline-outline"
          title="Could not load requests"
          text={error}
          action="Try again"
          onAction={load}
        />
      )}
      {!loading && !error && !requests.length && (
        <EmptyState
          icon="people-outline"
          title="No pending requests"
          text="New follow requests will appear here."
        />
      )}
      {requests.map((request) => {
        const person =
          people.find((item) => item.id === request.requester_id) ||
          requesters[request.requester_id];
        return (
          <View key={request.id}>
            {person ? (
              <PersonCard
                person={person}
                onPress={() => navigation.navigate('PublicProfile', { personId: person.id })}
              />
            ) : (
              <Card style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}>
                <Avatar name="?" size={44} />
                <Text style={ui.body}>Loading profile...</Text>
              </Card>
            )}
            <View style={styles.actions}>
              <View style={{ flex: 1 }}>
                <Button
                  title="Reject"
                  tone="secondary"
                  loading={busyAction === `${request.id}:reject`}
                  disabled={Boolean(busyAction)}
                  onPress={() => void respond(request, 'reject')}
                />
              </View>
              <View style={{ flex: 1 }}>
                <Button
                  title="Accept"
                  loading={busyAction === `${request.id}:accept`}
                  disabled={Boolean(busyAction)}
                  onPress={() => void respond(request, 'accept')}
                />
              </View>
            </View>
          </View>
        );
      })}
    </Screen>
  );
}

function SettingsSupportScreen({ navigation }: any) {
  const dark = useAppStore((state) => state.darkMode);
  const [push, setPush] = useState(true);
  const [articles, setArticles] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  useEffect(() => {
    appContentApi
      .support()
      .then(({ data }) => setArticles(data))
      .catch((error) => Alert.alert('Support unavailable', error.message))
      .finally(() => setLoading(false));
  }, []);
  return (
    <Screen>
      <Header title="Settings & support" onBack={() => navigation.goBack()} />
      <Setting
        title="Dark theme"
        value={dark}
        onValueChange={(value) => useAppStore.getState().setDarkMode(value)}
      />
      <Setting title="Push notifications" value={push} onValueChange={setPush} />
      {loading && <ChatSkeleton />}
      {articles.map((article) => (
        <Menu
          key={article.id}
          title={article.title}
          icon={article.icon}
          onPress={() =>
            navigation.navigate('SupportArticle', {
              title: article.title,
              body: article.body,
              icon: article.icon,
            })
          }
        />
      ))}
      <Text style={[ui.muted, styles.center]}>VibeCircle 1.0 · Talk. Connect. Learn. Belong.</Text>
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
  error: { color: colors.danger, backgroundColor: 'rgba(239,68,68,0.12)', padding: 12, borderRadius: 12 },
});

export default ConnectionRequestScreen;
