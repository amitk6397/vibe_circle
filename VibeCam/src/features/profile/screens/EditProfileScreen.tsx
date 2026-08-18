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

export function EditProfileScreen({ navigation }: any) {
  const profile = useAppStore((s) => s.profile);
  const [form, setForm] = useState(profile);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const set = (key: keyof typeof form) => (value: string) => setForm({ ...form, [key]: value });
  
  const save = async () => {
    const message = requiredTextError(form.name, 'Name') || usernameError(form.username);
    if (message) return setError(message);
    if (form.bio.trim().length > 240) return setError('Bio must be 240 characters or less.');
    setError('');
    setSaving(true);
    try {
      let avatarUri = form.avatarUri;
      if (avatarUri && (avatarUri.startsWith('file://') || avatarUri.startsWith('content://'))) {
        const uploaded = await uploadAttachment({
          id: 'avatar',
          kind: 'image',
          uri: avatarUri,
          name: 'avatar.jpg',
          mimeType: 'image/jpeg',
          size: 0,
        });
        avatarUri = uploaded.url;
      }
      useAppStore.getState().updateProfile({
        ...form,
        name: form.name.trim(),
        username: form.username.trim(),
        bio: form.bio.trim(),
        city: form.city.trim(),
        avatarUri,
      });
      navigation.goBack();
    } catch (err: any) {
      setError(err.message || 'Failed to upload photo.');
    } finally {
      setSaving(false);
    }
  };
  return (
    <Screen>
      <Header
        title="Edit profile"
        subtitle="Email remains private."
        onBack={() => navigation.goBack()}
      />
      <View style={styles.profile}>
        <Avatar name={form.name} uri={form.avatarUri} size={90} />
        <Button
          title="Change photo"
          compact
          tone="secondary"
          onPress={async () => {
            const image = await pickImage(true);
            if (image) setForm({ ...form, avatarUri: image.uri });
          }}
        />
        {form.avatarUri && (
          <Button
            title="Remove photo"
            compact
            tone="ghost"
            onPress={() => setForm({ ...form, avatarUri: undefined })}
          />
        )}
      </View>
      <Field label="Name" value={form.name} onChangeText={set('name')} />
      <Field label="Username" value={form.username} onChangeText={set('username')} />
      <Field label="Bio" value={form.bio} onChangeText={set('bio')} multiline />
      <Text style={ui.muted}>{form.bio.length}/240 characters</Text>
      <Field label="City (optional)" value={form.city} onChangeText={set('city')} />
      {!!error && <Text style={styles.error}>{error}</Text>}
      <Button title={saving ? "Saving changes..." : "Save changes"} disabled={saving} onPress={save} />
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

export default EditProfileScreen;
