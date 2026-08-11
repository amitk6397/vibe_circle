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

export function PrivacySettingsScreen({ navigation }: any) {
  const audienceValues = [
    'Everyone',
    'Followers',
    'Following',
    'Approved connections',
    'Nobody',
  ] as const;
  type Audience = (typeof audienceValues)[number];
  const [audiences, setAudiences] = useState<
    Record<
      'follow' | 'message' | 'call' | 'story' | 'comment' | 'mention' | 'onlineStatus',
      Audience
    >
  >({
    follow: 'Everyone',
    message: 'Everyone',
    call: 'Approved connections',
    story: 'Everyone',
    comment: 'Everyone',
    mention: 'Followers',
    onlineStatus: 'Everyone',
  });
  const [settings, setSettings] = useState({
    online: true,
    receipts: true,
    calls: false,
    discover: true,
    anonymous: true,
  });
  const toggle = (key: keyof typeof settings) =>
    setSettings((current) => {
      const next = { ...current, [key]: !current[key] };
      const apiValues = {
        showOnline: next.online,
        readReceipts: next.receipts,
        allowCalls: next.calls,
        profileVisibility: next.discover ? 'Everyone' : 'Nobody',
      };
      void usersApi
        .updatePrivacy(apiValues)
        .catch((error) => Alert.alert('Could not save privacy setting', error.message));
      return next;
    });
  return (
    <Screen>
      <Header
        title="Privacy settings"
        subtitle="Choose what others can see and do."
        onBack={() => navigation.goBack()}
      />
      <Setting
        title="Show online status"
        value={settings.online}
        onValueChange={() => toggle('online')}
      />
      <Setting
        title="Read receipts"
        value={settings.receipts}
        onValueChange={() => toggle('receipts')}
      />
      <Setting
        title="Allow calls from connections"
        value={settings.calls}
        onValueChange={() => toggle('calls')}
      />
      <Setting
        title="Appear in discovery"
        value={settings.discover}
        onValueChange={() => toggle('discover')}
      />
      <Text style={ui.h2}>Audience controls</Text>
      {(
        [
          ['follow', 'Who can follow me'],
          ['message', 'Who can message me'],
          ['call', 'Who can call me'],
          ['story', 'Who can view my stories'],
          ['comment', 'Who can comment on my posts'],
          ['mention', 'Who can mention me'],
          ['onlineStatus', 'Who can see my online status'],
        ] as const
      ).map(([key, label]) => (
        <View key={key} style={{ marginBottom: 14 }}>
          <Text style={styles.menuTitle}>{label}</Text>
          <View style={ui.wrap}>
            {audienceValues.map((value) => (
              <Pill
                key={value}
                label={value}
                selected={audiences[key] === value}
                onPress={() => {
                  setAudiences((current) => ({ ...current, [key]: value }));
                  void usersApi
                    .updatePrivacy({ [key]: value })
                    .catch((error) => Alert.alert('Could not save privacy setting', error.message));
                }}
              />
            ))}
          </View>
        </View>
      ))}
      <Setting
        title="Allow anonymous conversations"
        value={settings.anonymous}
        onValueChange={() => toggle('anonymous')}
      />
      <Card>
        <Text style={ui.h2}>Always private</Text>
        <Text style={ui.muted}>
          Email, password, exact birth date, device tokens, and private conversation content are
          never public.
        </Text>
      </Card>
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

export default PrivacySettingsScreen;
