import React, { useCallback, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Animated,
  Pressable,
  ScrollView,
  Share,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Header, Screen } from '../../../components/ui';
import { colors } from '../../../theme';
import { authApi } from '../../../services/api';

type ReferralInfo = {
  referralCode: string;
  totalReferrals: number;
  totalCoinsEarned?: number;
  totalEarned?: number;
  rewardPerReferral: number;
  inviteeBonus: number;
};

const HOW_IT_WORKS = [
  { emoji: '🔗', title: 'Share Your Code', desc: 'Send your unique referral code to friends.' },
  { emoji: '👤', title: 'Friend Joins', desc: 'They sign up and get a welcome coin bonus too!' },
  { emoji: '🪙', title: 'You Earn Coins', desc: 'Coins are instantly credited to your wallet.' },
];

export function ReferralScreen({ navigation }: any) {
  const [info, setInfo] = useState<ReferralInfo | null>(null);
  const [loading, setLoading] = useState(true);
  const [copied, setCopied] = useState(false);
  const pulseAnim = React.useRef(new Animated.Value(1)).current;

  const loadInfo = useCallback(async () => {
    try {
      const { data } = await authApi.getReferralInfo();
      setInfo(data as any);
    } catch {
      // ignore
    } finally {
      setLoading(false);
    }
  }, []);

  useFocusEffect(useCallback(() => {
    setLoading(true);
    void loadInfo();
  }, [loadInfo]));

  const pulseCopyBtn = () => {
    Animated.sequence([
      Animated.timing(pulseAnim, { toValue: 0.93, duration: 80, useNativeDriver: true }),
      Animated.timing(pulseAnim, { toValue: 1, duration: 80, useNativeDriver: true }),
    ]).start();
  };

  const copyCode = async () => {
    if (!info) return;
    pulseCopyBtn();
    try {
      // Use standard react-native Share sheet as a fallback (which contains a native 'Copy' button on Android/iOS)
      await Share.share({
        message: info.referralCode,
      });
      setCopied(true);
      setTimeout(() => setCopied(false), 2500);
    } catch {
      Alert.alert('Referral Code', info.referralCode);
    }
  };

  const shareCode = async () => {
    if (!info) return;
    try {
      await Share.share({
        message: `🎉 Join me on VibeCam! Use my referral code **${info.referralCode}** when signing up and get ${info.inviteeBonus} bonus coins for free! Download the app now.`,
        title: 'Join VibeCam & Get Free Coins!',
      });
    } catch {
      // cancelled
    }
  };

  const totalEarned = info
    ? (info.totalCoinsEarned ?? info.totalEarned ?? 0)
    : 0;

  return (
    <Screen scroll={false} noPadding>
      <Header title="Refer & Earn" onBack={() => navigation.goBack()} />

      {loading ? (
        <View style={styles.loadingState}>
          <ActivityIndicator size="large" color={colors.primary} />
        </View>
      ) : (
        <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.content}>
          {/* Hero card */}
          <LinearGradient
            colors={['#5B5CE2', '#7C3AED']}
            style={styles.heroCard}
            start={{ x: 0, y: 0 }}
            end={{ x: 1, y: 1 }}
          >
            {/* Decorative circles */}
            <View style={styles.deco1} />
            <View style={styles.deco2} />

            <Ionicons name="gift" size={40} color="rgba(255,255,255,0.9)" />
            <Text style={styles.heroTitle}>Invite Friends,{'\n'}Earn Coins!</Text>
            <Text style={styles.heroSub}>
              You earn <Text style={styles.heroAccent}>{info?.rewardPerReferral ?? 50} coins</Text> for each friend who joins.
              {'\n'}They get <Text style={styles.heroAccent}>{info?.inviteeBonus ?? 20} free coins</Text> too!
            </Text>
          </LinearGradient>

          {/* Referral code */}
          <View style={styles.codeSection}>
            <Text style={styles.codeSectionLabel}>YOUR REFERRAL CODE</Text>
            <Animated.View style={[styles.codeCard, { transform: [{ scale: pulseAnim }] }]}>
              <Text style={styles.codeText}>{info?.referralCode || '••••••••'}</Text>
              <Pressable
                style={[styles.copyBtn, copied && styles.copyBtnSuccess]}
                onPress={copyCode}
              >
                <Ionicons
                  name={copied ? 'checkmark' : 'copy-outline'}
                  size={18}
                  color={copied ? '#fff' : colors.primary}
                />
                <Text style={[styles.copyBtnText, copied && { color: '#fff' }]}>
                  {copied ? 'Copied!' : 'Copy'}
                </Text>
              </Pressable>
            </Animated.View>

            <Pressable style={styles.shareBtn} onPress={shareCode}>
              <LinearGradient
                colors={['#5B5CE2', '#7C3AED']}
                style={styles.shareBtnGrad}
                start={{ x: 0, y: 0 }}
                end={{ x: 1, y: 0 }}
              >
                <Ionicons name="share-social" size={18} color="#fff" />
                <Text style={styles.shareBtnText}>Share with Friends</Text>
              </LinearGradient>
            </Pressable>
          </View>

          {/* Stats row */}
          <View style={styles.statsRow}>
            <View style={styles.statCard}>
              <LinearGradient colors={['#EEF2FF', '#DDD6FE']} style={styles.statIconBg}>
                <Ionicons name="people" size={22} color={colors.primary} />
              </LinearGradient>
              <Text style={styles.statValue}>{info?.totalReferrals ?? 0}</Text>
              <Text style={styles.statLabel}>Friends{'\n'}Invited</Text>
            </View>
            <View style={[styles.statCard, { borderColor: '#F59E0B', borderWidth: 1 }]}>
              <LinearGradient colors={['#FEF3C7', '#FDE68A']} style={styles.statIconBg}>
                <Ionicons name="wallet" size={22} color="#D97706" />
              </LinearGradient>
              <Text style={[styles.statValue, { color: '#D97706' }]}>{totalEarned}</Text>
              <Text style={styles.statLabel}>Coins{'\n'}Earned</Text>
            </View>
            <View style={styles.statCard}>
              <LinearGradient colors={['#ECFDF5', '#A7F3D0']} style={styles.statIconBg}>
                <Ionicons name="star" size={22} color="#059669" />
              </LinearGradient>
              <Text style={[styles.statValue, { color: '#059669' }]}>{info?.rewardPerReferral ?? 50}</Text>
              <Text style={styles.statLabel}>Per{'\n'}Referral</Text>
            </View>
          </View>

          {/* How it works */}
          <Text style={styles.sectionTitle}>How it works</Text>
          {HOW_IT_WORKS.map((step, idx) => (
            <View key={idx} style={styles.howStep}>
              <View style={styles.howStepNum}>
                <Text style={styles.howStepNumText}>{idx + 1}</Text>
              </View>
              <Text style={styles.howStepEmoji}>{step.emoji}</Text>
              <View style={{ flex: 1 }}>
                <Text style={styles.howStepTitle}>{step.title}</Text>
                <Text style={styles.howStepDesc}>{step.desc}</Text>
              </View>
            </View>
          ))}

          {/* Terms */}
          <Text style={styles.terms}>
            Coins are credited instantly upon your referral's successful signup. Referral bonuses are subject to VibeCam's fair usage policy.
          </Text>
        </ScrollView>
      )}
    </Screen>
  );
}

const styles = StyleSheet.create({
  loadingState: { flex: 1, alignItems: 'center', justifyContent: 'center', paddingTop: 60 },
  content: { paddingVertical: 12, paddingHorizontal: 0, gap: 18, paddingBottom: 32 },
  heroCard: {
    borderRadius: 0,
    paddingVertical: 24,
    paddingHorizontal: 16,
    alignItems: 'center',
    gap: 12,
    overflow: 'hidden',
    position: 'relative',
  },
  deco1: {
    position: 'absolute',
    width: 160,
    height: 160,
    borderRadius: 80,
    backgroundColor: 'rgba(255,255,255,0.07)',
    top: -40,
    right: -40,
  },
  deco2: {
    position: 'absolute',
    width: 120,
    height: 120,
    borderRadius: 60,
    backgroundColor: 'rgba(255,255,255,0.05)',
    bottom: -30,
    left: -30,
  },
  heroTitle: { color: '#fff', fontSize: 24, fontWeight: '900', textAlign: 'center', lineHeight: 30 },
  heroSub: { color: 'rgba(255,255,255,0.85)', textAlign: 'center', fontSize: 14, lineHeight: 21 },
  heroAccent: { color: '#FDE68A', fontWeight: '900' },
  codeSection: { gap: 12, marginHorizontal: 12 },
  codeSectionLabel: {
    fontSize: 11,
    fontWeight: '800',
    color: colors.muted,
    letterSpacing: 1.5,
    textTransform: 'uppercase',
  },
  codeCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: colors.surface,
    borderRadius: 18,
    borderWidth: 2,
    borderColor: colors.border,
    padding: 16,
    gap: 12,
  },
  codeText: {
    flex: 1,
    fontSize: 26,
    fontWeight: '900',
    color: colors.primary,
    letterSpacing: 5,
  },
  copyBtn: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.surfaceAlt,
    borderRadius: 12,
    paddingHorizontal: 14,
    paddingVertical: 9,
  },
  copyBtnSuccess: { backgroundColor: colors.primary },
  copyBtnText: { color: colors.primary, fontWeight: '800', fontSize: 13 },
  shareBtn: { borderRadius: 18, overflow: 'hidden' },
  shareBtnGrad: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 10,
    paddingVertical: 15,
    borderRadius: 18,
  },
  shareBtnText: { color: '#fff', fontWeight: '900', fontSize: 16 },
  statsRow: { flexDirection: 'row', gap: 10, marginHorizontal: 12 },
  statCard: {
    flex: 1,
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.surface,
    borderRadius: 18,
    padding: 14,
    borderWidth: 1,
    borderColor: colors.border,
  },
  statIconBg: {
    width: 46,
    height: 46,
    borderRadius: 23,
    alignItems: 'center',
    justifyContent: 'center',
  },
  statValue: { fontSize: 22, fontWeight: '900', color: colors.text },
  statLabel: { color: colors.muted, fontSize: 11, fontWeight: '600', textAlign: 'center', lineHeight: 16 },
  sectionTitle: { fontSize: 17, fontWeight: '900', color: colors.text, marginHorizontal: 12 },
  howStep: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 14,
    backgroundColor: colors.surface,
    borderRadius: 16,
    padding: 14,
    borderWidth: 1,
    borderColor: colors.border,
    marginHorizontal: 12,
  },
  howStepNum: {
    width: 28,
    height: 28,
    borderRadius: 14,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
  },
  howStepNumText: { color: '#fff', fontWeight: '900', fontSize: 13 },
  howStepEmoji: { fontSize: 24 },
  howStepTitle: { color: colors.text, fontWeight: '800', fontSize: 14 },
  howStepDesc: { color: colors.muted, fontSize: 12, lineHeight: 18, marginTop: 2 },
  terms: {
    color: colors.muted,
    fontSize: 11,
    lineHeight: 17,
    textAlign: 'center',
    paddingHorizontal: 8,
    marginHorizontal: 12,
  },
});

export default ReferralScreen;
