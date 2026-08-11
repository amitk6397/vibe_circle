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

export function RegisterScreen({ navigation }: any) {
  const [form, setForm] = useState({ name: '', age: '', email: '', password: '', referralCode: '' });
  const [error, setError] = useState('');
  const [avatar, setAvatar] = useState<LocalAttachment | null>(null);
  const set = (key: keyof typeof form) => (value: string) => setForm({ ...form, [key]: value });
  const loading = useAppStore((state) => state.loading);
  const submit = async () => {
    const age = Number(form.age);
    const nameMessage = requiredTextError(form.name, 'Name');
    if (nameMessage) return setError(nameMessage);
    if (!isEmail(form.email)) return setError('Enter a valid email address.');
    const passwordMessage = passwordError(form.password);
    if (passwordMessage) return setError(passwordMessage);
    if (!Number.isFinite(age) || age < 18)
      return setError('VibeCircle is currently available only for people aged 18+.');
    setError('');
    try {
      let avatar_url: string | null = null;
      if (avatar) {
        const uploaded = await uploadAttachment(avatar);
        avatar_url = uploaded?.url || null;
      }
      await useAppStore.getState().register({
        name: form.name.trim(),
        age,
        email: form.email.trim().toLowerCase(),
        password: form.password,
        avatar_url,
        referral_code: form.referralCode.trim() ? form.referralCode.trim().toUpperCase() : undefined,
      });
      navigation.navigate('VerifyEmail', { email: form.email });
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unable to create account.');
    }
  };
  return (
    <Screen>
      <Header
        title="Create account"
        subtitle="Only four details to begin."
        onBack={() => navigation.goBack()}
      />
      <Pressable style={[styles.profileAvatar, { marginBottom: 15 }]} onPress={async () => setAvatar(await pickImage())}>
        {avatar ? (
          <Image source={{ uri: avatar.uri }} style={styles.profileImage} />
        ) : (
          <Ionicons name="camera" size={30} color={colors.primary} />
        )}
      </Pressable>
      <Text style={[ui.muted, { textAlign: 'center', marginBottom: 20 }]}>Tap to choose a profile photo</Text>
      <Field label="Name" value={form.name} onChangeText={set('name')} placeholder="Your name" />
      <Field
        label="Age"
        value={form.age}
        onChangeText={set('age')}
        keyboardType="number-pad"
        placeholder="18 or older"
      />
      <Field
        label="Email"
        value={form.email}
        onChangeText={set('email')}
        keyboardType="email-address"
        placeholder="Private email"
      />
      <Field
        label="Password"
        value={form.password}
        onChangeText={set('password')}
        secureTextEntry
        placeholder="At least 8 characters"
      />
      <Field
        label="Referral Code"
        value={form.referralCode}
        onChangeText={set('referralCode')}
        placeholder="8-character code (Optional)"
        autoCapitalize="characters"
      />
      {!!error && <Text style={styles.error}>{error}</Text>}
      <View style={styles.notice}>
        <Ionicons name="lock-closed" size={20} color={colors.success} />
        <Text style={[ui.muted, { flex: 1 }]}>
          Your email, password, and exact date of birth are never shown on your profile.
        </Text>
      </View>
      <Button title="Continue" loading={loading} disabled={loading} onPress={() => void submit()} />
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
  error: { color: colors.danger, backgroundColor: '#FFF0F2', padding: 12, borderRadius: 12 },
  legal: { color: colors.muted, fontSize: 11, lineHeight: 17, textAlign: 'center' },
  notice: {
    backgroundColor: '#EBFAF4',
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

export default RegisterScreen;
