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

export function VerifyEmailScreen({ navigation, route }: any) {
  const [code, setCode] = useState('');
  const [sending, setSending] = useState(false);
  const [verifying, setVerifying] = useState(false);
  const [snackbar, setSnackbar] = useState('');
  const [error, setError] = useState('');
  const [cooldown, setCooldown] = useState(0);
  const showSnackbar = (message: string) => {
    setSnackbar(message);
    setTimeout(() => setSnackbar(''), 10_000);
  };
  const sendOtp = async () => {
    setSending(true);
    setError('');
    try {
      const { data } = await authApi.requestVerification();
      showSnackbar(`Your verification OTP is ${data.otp}. It expires in 10 minutes.`);
      setCooldown(30);
    } catch (reason: any) {
      setError(reason.message || 'Could not send OTP.');
    } finally {
      setSending(false);
    }
  };
  useEffect(() => {
    void sendOtp();
  }, []);
  useEffect(() => {
    if (!cooldown) return;
    const timer = setInterval(() => setCooldown((value) => Math.max(0, value - 1)), 1000);
    return () => clearInterval(timer);
  }, [cooldown > 0]);
  const verify = async () => {
    setVerifying(true);
    setError('');
    try {
      await authApi.verifyEmail(code);
      navigation.replace('BasicProfile');
    } catch (reason: any) {
      setError(reason.message || 'OTP is invalid or expired.');
    } finally {
      setVerifying(false);
    }
  };
  return (
    <Screen>
      <Header
        title="Verify email"
        subtitle={`We sent a code to ${route.params?.email || 'your email'}`}
        onBack={() => navigation.goBack()}
      />
      <View style={styles.heroIcon}>
        <Ionicons name="mail" size={54} color={colors.primary} />
      </View>
      <Field
        label="6-digit code"
        value={code}
        onChangeText={setCode}
        keyboardType="number-pad"
        placeholder="123456"
      />
      <Button
        title="Verify and continue"
        loading={verifying}
        disabled={code.length !== 6 || verifying}
        onPress={() => void verify()}
      />
      <Button
        title={cooldown ? `Resend OTP in ${cooldown}s` : 'Resend OTP'}
        tone="ghost"
        loading={sending}
        disabled={sending || cooldown > 0}
        onPress={() => void sendOtp()}
      />
      {!!error && <Text style={styles.error}>{error}</Text>}
      {!!snackbar && (
        <View style={styles.snackbar}>
          <Ionicons name="key-outline" size={20} color="#fff" />
          <Text style={styles.snackbarText}>{snackbar}</Text>
        </View>
      )}
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

export default VerifyEmailScreen;
