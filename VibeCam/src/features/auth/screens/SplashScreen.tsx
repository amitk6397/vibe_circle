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

export function SplashScreen({ navigation }: any) {
  const { authenticated, sessionReady } = useAppStore();
  useEffect(() => {
    if (!sessionReady) return;
    const timer = setTimeout(() => navigation.replace(authenticated ? 'Main' : 'Login'), 350);
    return () => clearTimeout(timer);
  }, [authenticated, navigation, sessionReady]);
  return (
    <LinearGradient
      colors={gradients.primary}
      start={{ x: 0, y: 0 }}
      end={{ x: 1, y: 1 }}
      style={styles.splash}
    >
      <View style={styles.logo}>
        <Ionicons name="people" size={47} color="#fff" />
      </View>
      <Text style={styles.brand}>VibeCircle</Text>
      <Text style={styles.tagline}>Talk. Connect. Learn. Belong.</Text>
    </LinearGradient>
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

export default SplashScreen;
