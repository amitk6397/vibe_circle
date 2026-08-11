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

export function LoginScreen({ navigation }: any) {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const loading = useAppStore((state) => state.loading);
  const submit = async () => {
    if (!isEmail(email)) return setError('Enter a valid email address.');
    const message = passwordError(password);
    if (message) return setError(message);
    setError('');
    try {
      await useAppStore.getState().login(email.trim().toLowerCase(), password);
      navigation.reset({ index: 0, routes: [{ name: 'Main' }] });
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Unable to log in.');
    }
  };
  return (
    <Screen>
      <Header title="Welcome back" subtitle="Your circle is waiting." />
      <View style={styles.authHero}>
        <View style={styles.smallLogo}>
          <Ionicons name="people" size={30} color="#fff" />
        </View>
        <Text style={ui.title}>Log in to VibeCircle</Text>
        <Text style={ui.muted}>Your email stays private and is never displayed publicly.</Text>
      </View>
      <Field
        label="Email"
        value={email}
        onChangeText={setEmail}
        keyboardType="email-address"
        placeholder="you@example.com"
      />
      <Field
        label="Password"
        value={password}
        onChangeText={setPassword}
        secureTextEntry
        placeholder="At least 8 characters"
      />
      {!!error && <Text style={styles.error}>{error}</Text>}
      <Pressable onPress={() => navigation.navigate('ForgotPassword')}>
        <Text style={[styles.loginLink, { textAlign: 'right' }]}>Forgot password?</Text>
      </Pressable>
      <Button title="Log in" loading={loading} disabled={loading} onPress={() => void submit()} />
      <Button
        title="Create a new account"
        tone="secondary"
        onPress={() => navigation.navigate('Register')}
      />
      <Text style={styles.legal}>
        By continuing, you agree to the Terms, Privacy Policy, and 18+ Community Rules.
      </Text>
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

export default LoginScreen;
