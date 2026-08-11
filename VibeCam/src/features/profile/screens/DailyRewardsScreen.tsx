import React, { useCallback, useEffect, useState } from 'react';
import {
  ActivityIndicator,
  Alert,
  Animated,
  Pressable,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Header, Screen } from '../../../components/ui';
import { colors } from '../../../theme';
import { walletApi } from '../../../services/api';

const DAY_EMOJIS = ['🌱', '⭐', '💫', '🔥', '💎', '🏆', '👑'];

function formatCountdown(nextClaimAt: string): string {
  const now = Date.now();
  const next = new Date(nextClaimAt).getTime();
  const diff = Math.max(0, next - now);
  const hours = Math.floor(diff / 3600000);
  const mins = Math.floor((diff % 3600000) / 60000);
  const secs = Math.floor((diff % 60000) / 1000);
  return `${String(hours).padStart(2, '0')}:${String(mins).padStart(2, '0')}:${String(secs).padStart(2, '0')}`;
}

export function DailyRewardsScreen({ navigation }: any) {
  const [status, setStatus] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [claiming, setClaiming] = useState(false);
  const [countdown, setCountdown] = useState('');
  const celebScale = React.useRef(new Animated.Value(0)).current;
  const [showCelebration, setShowCelebration] = useState(false);

  const loadStatus = useCallback(async () => {
    try {
      const { data } = await walletApi.dailyRewardStatus();
      setStatus(data);
    } catch {
      /* ignore */
    } finally {
      setLoading(false);
    }
  }, []);

  useFocusEffect(useCallback(() => {
    setLoading(true);
    void loadStatus();
  }, [loadStatus]));

  useEffect(() => {
    if (!status?.nextClaimAt) return;
    const tick = () => setCountdown(formatCountdown(status.nextClaimAt));
    tick();
    const t = setInterval(tick, 1000);
    return () => clearInterval(t);
  }, [status?.nextClaimAt]);

  const claimReward = async () => {
    if (claiming) return;
    setClaiming(true);
    try {
      const { data } = await walletApi.claimDailyReward();
      setShowCelebration(true);
      celebScale.setValue(0);
      Animated.sequence([
        Animated.spring(celebScale, { toValue: 1.2, friction: 4, useNativeDriver: true }),
        Animated.timing(celebScale, { toValue: 1, duration: 180, useNativeDriver: true }),
      ]).start();
      setTimeout(() => setShowCelebration(false), 2200);
      Alert.alert(
        `🎉 Day ${data.streakDay} Reward Claimed!`,
        `You earned ${data.coinsAwarded} coins!\nCome back tomorrow for ${data.nextRewardCoins} coins.`,
      );
      await loadStatus();
    } catch (err: any) {
      const msg = err?.response?.data?.detail || err?.message || 'Could not claim reward.';
      if (msg.includes('already_claimed') || msg.includes('already claimed')) {
        Alert.alert('Already claimed! ✅', 'Come back tomorrow for your next reward.');
      } else {
        Alert.alert('Claim failed', msg);
      }
    } finally {
      setClaiming(false);
    }
  };

  const schedule: number[] = status?.schedule || [5, 10, 15, 20, 30, 40, 50];
  const streakDay: number = status?.streakDay || 0;
  const alreadyClaimed: boolean = status?.alreadyClaimedToday || false;
  const todayReward = schedule[Math.min(streakDay, schedule.length - 1)] || 5;
  const nextReward = schedule[Math.min(streakDay + (alreadyClaimed ? 1 : 0), schedule.length - 1)] || 5;

  return (
    <Screen scroll={false} style={{ paddingHorizontal: 12 }}>
      <Header title="Daily Login Rewards" onBack={() => navigation.goBack()} />

      <ScrollView showsVerticalScrollIndicator={false} contentContainerStyle={styles.scroll}>
        {/* Hero streak banner */}
        <LinearGradient
          colors={['#7C3AED', '#4F46E5']}
          start={{ x: 0, y: 0 }}
          end={{ x: 1, y: 1 }}
          style={styles.heroBanner}
        >
          <View style={styles.heroTop}>
            <View>
              <Text style={styles.heroLabel}>CURRENT STREAK</Text>
              <View style={styles.streakBadge}>
                <Text style={styles.streakFire}>🔥</Text>
                <Text style={styles.streakNum}>{streakDay}</Text>
                <Text style={styles.streakDays}> day{streakDay !== 1 ? 's' : ''}</Text>
              </View>
            </View>
            <View style={styles.nextRewardPreview}>
              <Text style={styles.nextRewardLabel}>NEXT REWARD</Text>
              <Text style={styles.nextRewardValue}>🪙 {nextReward} coins</Text>
            </View>
          </View>

          <Text style={styles.heroSub}>
            {alreadyClaimed
              ? "Today's reward has been claimed! 🎉"
              : "Claim today's reward to keep your streak alive!"}
          </Text>

          {loading ? (
            <ActivityIndicator color="#fff" style={{ marginTop: 12 }} />
          ) : (
            <Pressable
              onPress={() => void claimReward()}
              disabled={alreadyClaimed || claiming}
              style={[styles.claimBtn, (alreadyClaimed || claiming) && styles.claimBtnDisabled]}
            >
              {claiming ? (
                <ActivityIndicator color="#7C3AED" />
              ) : alreadyClaimed ? (
                <>
                  <Ionicons name="checkmark-circle" size={18} color="rgba(255,255,255,0.8)" />
                  <Text style={styles.claimBtnText}>Reward Claimed ✓</Text>
                </>
              ) : (
                <>
                  <Ionicons name="gift-outline" size={18} color="#7C3AED" />
                  <Text style={[styles.claimBtnText, { color: '#7C3AED' }]}>
                    Claim {todayReward} Coins Now!
                  </Text>
                </>
              )}
            </Pressable>
          )}

          {alreadyClaimed && status?.nextClaimAt && (
            <View style={styles.countdownRow}>
              <Ionicons name="time-outline" size={14} color="rgba(255,255,255,0.7)" />
              <Text style={styles.countdownText}>Next reward available in {countdown}</Text>
            </View>
          )}
        </LinearGradient>

        {/* Celebration overlay */}
        {showCelebration && (
          <Animated.View style={[styles.celebration, { transform: [{ scale: celebScale }] }]}>
            <Text style={styles.celebrationEmoji}>🎉</Text>
            <Text style={styles.celebrationText}>Reward Claimed!</Text>
          </Animated.View>
        )}

        {/* 7-Day Grid */}
        <View style={styles.gridSection}>
          <Text style={styles.sectionTitle}>Weekly Reward Schedule</Text>
          <Text style={styles.sectionSub}>Login every day to maximize your coins!</Text>
          <View style={styles.grid}>
            {schedule.slice(0, 7).map((coins, index) => {
              const dayNum = index + 1;
              const isClaimed = alreadyClaimed ? dayNum <= streakDay : dayNum < streakDay;
              const isToday = alreadyClaimed
                ? dayNum === streakDay && dayNum === streakDay
                : dayNum === streakDay + 1;
              return (
                <View
                  key={dayNum}
                  style={[
                    styles.dayCard,
                    isClaimed && styles.dayCardClaimed,
                    isToday && !alreadyClaimed && styles.dayCardToday,
                    alreadyClaimed && dayNum === streakDay && styles.dayCardClaimed,
                  ]}
                >
                  {isClaimed || (alreadyClaimed && dayNum === streakDay) ? (
                    <Ionicons name="checkmark-circle" size={22} color="#10B981" />
                  ) : isToday && !alreadyClaimed ? (
                    <Ionicons name="gift" size={22} color="#7C3AED" />
                  ) : (
                    <Text style={styles.dayEmoji}>{DAY_EMOJIS[index] || '⭐'}</Text>
                  )}
                  <Text style={[styles.dayLabel, isClaimed && styles.dayLabelClaimed]}>
                    Day {dayNum}
                  </Text>
                  <View style={styles.dayCoins}>
                    <Text style={styles.coinIcon}>🪙</Text>
                    <Text style={[styles.coinCount, isClaimed && styles.coinCountClaimed, isToday && !alreadyClaimed && styles.coinCountToday]}>
                      {coins}
                    </Text>
                  </View>
                  {isToday && !alreadyClaimed && (
                    <View style={styles.todayTag}>
                      <Text style={styles.todayTagText}>TODAY</Text>
                    </View>
                  )}
                  {dayNum === 7 && (
                    <View style={styles.maxTag}>
                      <Text style={styles.maxTagText}>MAX</Text>
                    </View>
                  )}
                </View>
              );
            })}
          </View>
        </View>

        {/* Streak tips */}
        <View style={styles.tipsCard}>
          <Text style={styles.tipsTitle}>How it works</Text>
          <View style={styles.tipRow}>
            <Ionicons name="flash" size={16} color={colors.primary} />
            <Text style={styles.tipText}>Login every day to maintain your streak</Text>
          </View>
          <View style={styles.tipRow}>
            <Ionicons name="trophy-outline" size={16} color="#E65100" />
            <Text style={styles.tipText}>Day 7 gives maximum {schedule[6] || 50} coins!</Text>
          </View>
          <View style={styles.tipRow}>
            <Ionicons name="alert-circle-outline" size={16} color={colors.danger} />
            <Text style={styles.tipText}>Missing a day resets your streak to Day 1</Text>
          </View>
          <View style={styles.tipRow}>
            <Ionicons name="infinite-outline" size={16} color={colors.success} />
            <Text style={styles.tipText}>
              After Day 7, keep earning {schedule[6] || 50} coins/day!
            </Text>
          </View>
        </View>

        {/* Admin note */}
        <View style={styles.adminNote}>
          <Ionicons name="shield-checkmark-outline" size={13} color={colors.muted} />
          <Text style={styles.adminNoteText}>
            Reward amounts are configured by the app admin and may update periodically.
          </Text>
        </View>
      </ScrollView>
    </Screen>
  );
}

const styles = StyleSheet.create({
  scroll: { paddingBottom: 40, gap: 0 },
  heroBanner: {
    borderRadius: 22,
    padding: 22,
    marginBottom: 22,
    gap: 14,
  },
  heroTop: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    justifyContent: 'space-between',
    marginTop: 20
  },
  heroLabel: {
    color: 'rgba(255,255,255,0.65)',
    fontSize: 10,
    fontWeight: '800',
    letterSpacing: 1.2,
  },
  streakBadge: { flexDirection: 'row', alignItems: 'flex-end', marginTop: 4 },
  streakFire: { fontSize: 26, marginRight: 4 },
  streakNum: { color: '#fff', fontSize: 36, fontWeight: '900', lineHeight: 42 },
  streakDays: {
    color: 'rgba(255,255,255,0.75)',
    fontSize: 14,
    fontWeight: '600',
    marginBottom: 6,
  },
  nextRewardPreview: { alignItems: 'flex-end' },
  nextRewardLabel: {
    color: 'rgba(255,255,255,0.65)',
    fontSize: 9,
    fontWeight: '800',
    letterSpacing: 1,
  },
  nextRewardValue: { color: '#fff', fontSize: 16, fontWeight: '900', marginTop: 2 },
  heroSub: { color: 'rgba(255,255,255,0.85)', fontSize: 13, fontWeight: '500', lineHeight: 18 },
  claimBtn: {
    backgroundColor: colors.primary,
    borderRadius: 14,
    paddingVertical: 15,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    shadowColor: '#000',
    shadowOpacity: 0.15,
    shadowRadius: 6,
    elevation: 3,
  },
  claimBtnDisabled: { opacity: 0.55, backgroundColor: 'rgba(255,255,255,0.22)' },
  claimBtnText: { fontSize: 15, fontWeight: '800', color: '#fff' },
  countdownRow: { flexDirection: 'row', alignItems: 'center', gap: 5 },
  countdownText: { color: 'rgba(255,255,255,0.65)', fontSize: 12, fontWeight: '600' },
  celebration: {
    alignSelf: 'center',
    backgroundColor: 'rgba(245,158,11,0.18)',
    borderRadius: 18,
    paddingHorizontal: 24,
    paddingVertical: 14,
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
    marginBottom: 16,
    shadowColor: '#000',
    shadowOpacity: 0.12,
    shadowRadius: 6,
    elevation: 4,
  },
  celebrationEmoji: { fontSize: 24 },
  celebrationText: { fontSize: 16, fontWeight: '900', color: colors.warning },
  gridSection: { marginBottom: 20 },
  sectionTitle: { color: colors.text, fontSize: 17, fontWeight: '800', marginBottom: 4 },
  sectionSub: { color: colors.muted, fontSize: 12, marginBottom: 14 },
  grid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, justifyContent: 'flex-start' },
  dayCard: {
    width: '30%',
    backgroundColor: colors.surface,
    borderRadius: 16,
    borderWidth: 1.5,
    borderColor: colors.border,
    paddingVertical: 14,
    paddingHorizontal: 8,
    alignItems: 'center',
    gap: 5,
    position: 'relative',
    overflow: 'hidden',
  },
  dayCardClaimed: {
    backgroundColor: 'rgba(16,185,129,0.12)',
    borderColor: '#10B981',
  },
  dayCardToday: {
    backgroundColor: 'rgba(124,58,237,0.15)',
    borderColor: '#7C3AED',
    borderWidth: 2,
  },
  dayEmoji: { fontSize: 22 },
  dayLabel: { color: colors.muted, fontSize: 10, fontWeight: '700' },
  dayLabelClaimed: { color: '#059669' },
  dayCoins: { flexDirection: 'row', alignItems: 'center', gap: 2 },
  coinIcon: { fontSize: 11 },
  coinCount: { color: colors.text, fontSize: 15, fontWeight: '900' },
  coinCountClaimed: { color: '#059669' },
  coinCountToday: { color: '#7C3AED' },
  todayTag: {
    position: 'absolute',
    top: 0,
    right: 0,
    backgroundColor: '#7C3AED',
    borderBottomLeftRadius: 8,
    paddingHorizontal: 5,
    paddingVertical: 2,
  },
  todayTagText: { color: '#fff', fontSize: 7, fontWeight: '900', letterSpacing: 0.5 },
  maxTag: {
    position: 'absolute',
    top: 0,
    left: 0,
    backgroundColor: '#E65100',
    borderBottomRightRadius: 8,
    paddingHorizontal: 5,
    paddingVertical: 2,
  },
  maxTagText: { color: '#fff', fontSize: 7, fontWeight: '900', letterSpacing: 0.5 },
  tipsCard: {
    backgroundColor: colors.surface,
    borderRadius: 18,
    borderWidth: 1,
    borderColor: colors.border,
    padding: 18,
    gap: 12,
    marginBottom: 16,
  },
  tipsTitle: { color: colors.text, fontSize: 15, fontWeight: '800', marginBottom: 4 },
  tipRow: { flexDirection: 'row', alignItems: 'flex-start', gap: 10 },
  tipText: { color: colors.text, fontSize: 13, flex: 1, lineHeight: 18 },
  adminNote: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    gap: 6,
    paddingHorizontal: 4,
  },
  adminNoteText: { color: colors.muted, fontSize: 11, flex: 1, lineHeight: 16 },
});

export default DailyRewardsScreen;
