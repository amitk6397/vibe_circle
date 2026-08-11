import React, { useEffect, useState } from 'react';

import { Alert, Image, Pressable, StyleSheet, Text, View } from 'react-native';

import { Ionicons } from '@expo/vector-icons';

import { LinearGradient } from 'expo-linear-gradient';

import { Button, Field, Header, Pill, Screen, ui } from '../../../components/ui';

import { colors, gradients } from '../../../theme';

import { INTERESTS, LANGUAGES } from '../../../constants/data';

import { useAppStore } from '../../../store/useAppStore';

import { authApi } from '../../../services/api';

import { pickImage } from '../../../services/mediaPicker';

import { uploadAttachment } from '../../../services/api';

import { LocalAttachment } from '../../../types';

import {
  isEmail,
  passwordError,
  requiredTextError,
  usernameError,
} from '../../../utils/validation';

export function BasicProfileScreen({ navigation }: any) {
  const profile = useAppStore((s) => s.profile);
  const [username, setUsername] = useState(profile.username);
  const [selected, setSelected] = useState(profile.interests);
  const [languages, setLanguages] = useState(profile.languages);
  const [topics, setTopics] = useState(profile.conversationTopics);
  const [dateOfBirth, setDateOfBirth] = useState(profile.dateOfBirth || '');
  const [gender, setGender] = useState(profile.gender || '');
  const [error, setError] = useState('');
  const [avatar, setAvatar] = useState<LocalAttachment | null>(null);
  const [saving, setSaving] = useState(false);
  const toggle = (list: string[], value: string, update: (next: string[]) => void) =>
    update(list.includes(value) ? list.filter((x) => x !== value) : [...list, value]);
  const finish = async () => {
    const message = usernameError(username);
    if (message) return setError(message);
    if (!selected.length || !languages.length)
      return setError('Choose at least one interest and one language.');
    setError('');
    setSaving(true);
    try {
      const uploaded = avatar ? await uploadAttachment(avatar) : null;
      useAppStore.getState().updateProfile({
        username: username.trim(),
        interests: selected,
        languages,
        conversationTopics: topics,
        dateOfBirth: dateOfBirth.trim() || undefined,
        gender: gender.trim() || undefined,
        preferredLanguage: languages[0],
        avatarUri: uploaded?.url,
      });
      navigation.reset({ index: 0, routes: [{ name: 'Main' }] });
    } catch (reason: any) {
      setError(reason.message || 'Could not save your profile.');
    } finally {
      setSaving(false);
    }
  };
  return (
    <Screen>
      <Header title="Make it yours" subtitle="Optional details improve recommendations." />
      <Pressable style={styles.profileAvatar} onPress={async () => setAvatar(await pickImage())}>
        {avatar ? (
          <Image source={{ uri: avatar.uri }} style={styles.profileImage} />
        ) : profile.avatarUri ? (
          <Image source={{ uri: profile.avatarUri }} style={styles.profileImage} />
        ) : (
          <Ionicons name="camera" size={30} color={colors.primary} />
        )}
      </Pressable>
      <Text style={[ui.muted, { textAlign: 'center' }]}>Tap to choose a profile photo</Text>
      <Field
        label="Username"
        value={username}
        onChangeText={setUsername}
        placeholder="unique.username"
      />
      <Text style={ui.h2}>Choose interests</Text>
      <View style={ui.wrap}>
        {INTERESTS.map((x) => (
          <Pill
            key={x}
            label={x}
            selected={selected.includes(x)}
            onPress={() => toggle(selected, x, setSelected)}
          />
        ))}
      </View>
      <Text style={ui.h2}>Languages</Text>
      <View style={ui.wrap}>
        {LANGUAGES.map((x) => (
          <Pill
            key={x}
            label={x}
            selected={languages.includes(x)}
            onPress={() => toggle(languages, x, setLanguages)}
          />
        ))}
      </View>
      <Field
        label="Date of birth (optional)"
        value={dateOfBirth}
        onChangeText={setDateOfBirth}
        placeholder="YYYY-MM-DD"
      />
      <Field
        label="Gender (optional)"
        value={gender}
        onChangeText={setGender}
        placeholder="Your gender"
      />
      <Text style={ui.h2}>Conversation topics</Text>
      <View style={ui.wrap}>
        {[
          'Casual conversation',
          'Career guidance',
          'Study and motivation',
          'Technology',
          'Business',
          'Emotional support',
          'Family matters',
          'Relationship advice',
          'Fitness',
          'Spirituality',
          'Entertainment',
          'Lifestyle',
        ].map((topic) => (
          <Pill
            key={topic}
            label={topic}
            selected={topics.includes(topic)}
            onPress={() => toggle(topics, topic, setTopics)}
          />
        ))}
      </View>
      {!!error && <Text style={styles.error}>{error}</Text>}
      <Button
        title="Open VibeCircle"
        loading={saving}
        disabled={saving}
        onPress={() => void finish()}
      />
    </Screen>
  );
}

const styles = StyleSheet.create({
  splash: { flex: 1, alignItems: 'center', justifyContent: 'center' },
  logo: {
    width: 96,
    height: 96,
    borderRadius: 32,
    backgroundColor: 'rgba(255,255,255,.18)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  brand: { color: '#fff', fontSize: 38, fontWeight: '900', marginTop: 22 },
  tagline: { color: 'rgba(255,255,255,.82)', fontSize: 15, marginTop: 7 },
  heroIcon: {
    width: 128,
    height: 128,
    borderRadius: 42,
    backgroundColor: colors.surfaceAlt,
    alignSelf: 'center',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 35,
  },
  loginLink: { color: colors.primary, textAlign: 'center', fontWeight: '800', paddingVertical: 4 },
  authHero: { gap: 8, marginVertical: 14 },
  smallLogo: {
    width: 56,
    height: 56,
    borderRadius: 18,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginBottom: 8,
  },
  error: { color: colors.danger, backgroundColor: 'rgba(239,68,68,0.12)', padding: 12, borderRadius: 12 },
  legal: { color: colors.muted, fontSize: 11, lineHeight: 17, textAlign: 'center' },
  notice: {
    backgroundColor: colors.surfaceAlt,
    borderRadius: 14,
    padding: 14,
    flexDirection: 'row',
    gap: 10,
  },
  profileAvatar: {
    alignSelf: 'center',
    width: 92,
    height: 92,
    borderRadius: 46,
    backgroundColor: colors.surfaceAlt,
    alignItems: 'center',
    justifyContent: 'center',
    overflow: 'hidden',
  },
  profileImage: { width: '100%', height: '100%' },
  snackbar: {
    position: 'absolute',
    left: 16,
    right: 16,
    bottom: 20,
    backgroundColor: colors.dark,
    borderRadius: 14,
    padding: 14,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 10,
  },
  snackbarText: { color: '#fff', flex: 1, fontWeight: '700', lineHeight: 20 },
});

export default BasicProfileScreen;
