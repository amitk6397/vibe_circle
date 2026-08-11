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

export function CreateCircleScreen({ navigation }: any) {
  const [name, setName] = useState('');
  const [description, setDescription] = useState('');
  const [maxMembers, setMaxMembers] = useState('12');
  const [creating, setCreating] = useState(false);
  const createCommunity = useAppStore((state) => state.createCommunity);
  const validLimit = Number(maxMembers) >= 2 && Number(maxMembers) <= 50;
  return (
    <Screen>
      <Header
        title="Create private circle"
        subtitle="A small invite-only space for people you trust."
        onBack={() => navigation.goBack()}
      />
      <Field label="Circle name" value={name} onChangeText={setName} placeholder="Close friends" />
      <Field
        label="Description"
        value={description}
        onChangeText={setDescription}
        multiline
        placeholder="What will your circle share?"
      />
      <Field
        label="Member limit"
        value={maxMembers}
        onChangeText={setMaxMembers}
        keyboardType="number-pad"
        error={!validLimit ? 'Choose 2 to 50 members' : undefined}
      />
      <Card>
        <View style={styles.row}>
          <Ionicons name="lock-closed" size={22} color={colors.primary} />
          <View style={{ flex: 1 }}>
            <Text style={styles.menuTitle}>Invite-only privacy</Text>
            <Text style={ui.muted}>Only invited members can find, open or join this circle.</Text>
          </View>
        </View>
      </Card>
      <Button
        title="Create circle"
        loading={creating}
        disabled={name.trim().length < 3 || description.trim().length < 10 || !validLimit}
        onPress={async () => {
          setCreating(true);
          try {
            const communityId = await createCommunity({
              name: name.trim(),
              description: description.trim(),
              category: 'Private circle',
              privacy: 'private',
              kind: 'circle',
              maxMembers: Number(maxMembers),
              rules: ['Respect privacy', 'Ask before sharing outside the circle', 'Be kind'],
              color: '#6C63E8',
            });
            navigation.replace('CommunityDetails', { communityId });
          } catch (error: any) {
            Alert.alert('Could not create circle', error.message);
          } finally {
            setCreating(false);
          }
        }}
      />
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
  error: { color: colors.danger, backgroundColor: '#FFF0F2', padding: 12, borderRadius: 12 },
});

export default CreateCircleScreen;
