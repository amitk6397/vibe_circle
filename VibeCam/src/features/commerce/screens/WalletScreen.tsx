import React, { useCallback, useState } from 'react';
import { Alert, Pressable, ScrollView, Share, StyleSheet, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { colors, gradients } from '../../../theme';
import { authApi, walletApi } from '../../../services/api';

type Period = '7d' | '30d' | '90d' | 'all';

export function WalletScreen({ navigation }: any) {
  const [period, setPeriod] = useState<Period>('30d');
  const [dashboard, setDashboard] = useState<any>(null);
  const [selectedDay, setSelectedDay] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [referralInfo, setReferralInfo] = useState<any>(null);
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const [dashRes, refRes] = await Promise.allSettled([
        walletApi.dashboard(period),
        authApi.getReferralInfo(),
      ]);
      if (dashRes.status === 'fulfilled') setDashboard(dashRes.value.data);
      if (refRes.status === 'fulfilled') setReferralInfo(refRes.value.data);
      if (dashRes.status === 'rejected') Alert.alert('Dashboard unavailable', dashRes.reason?.message);
    } finally {
      setLoading(false);
    }
  }, [period]);
  useFocusEffect(useCallback(() => void load(), [load]));

  const maxChart = Math.max(
    1,
    ...(dashboard?.chart || []).map((item: any) => Math.max(item.spent, item.earned)),
  );
  const visibleChart = (dashboard?.chart || []).filter(
    (_: any, index: number, all: any[]) =>
      all.length <= 12 || index % Math.ceil(all.length / 12) === 0,
  );

  return (
    <Screen>
      <Header
        title="Dashboard"
        subtitle="Your coins, earnings and activity"
        onBack={() => navigation.goBack()}
      />
      <View style={styles.periodTabs}>
        {(['7d', '30d', '90d', 'all'] as Period[]).map((value) => (
          <Pressable
            key={value}
            onPress={() => {
              setSelectedDay(null);
              setPeriod(value);
            }}
            style={[styles.periodTab, period === value && styles.periodTabActive]}
          >
            <Text style={[styles.periodText, period === value && styles.periodTextActive]}>
              {value === 'all' ? 'All' : value}
            </Text>
          </Pressable>
        ))}
      </View>
      {dashboard ? (
        <>
          <LinearGradient colors={gradients.support} style={styles.balanceHero}>
            <View style={styles.heroTop}>
              <View>
                <Text style={styles.heroLabel}>AVAILABLE BALANCE</Text>
                <Text style={styles.heroValue}>{dashboard.currentCoins || 0}</Text>
                <Text style={styles.heroUnit}>coins ready to use</Text>
              </View>
              <View style={styles.heroIcon}>
                <Ionicons name="wallet" size={25} color="#fff" />
              </View>
            </View>
            <View style={styles.heroActions}>
              <Pressable
                style={styles.heroButton}
                onPress={() => navigation.navigate('SubscriptionPlans')}
              >
                <Ionicons name="add-circle-outline" size={18} color="#fff" />
                <Text style={styles.heroButtonText}>Add coins</Text>
              </Pressable>
              <Pressable
                style={styles.heroButton}
                onPress={() => navigation.navigate('Withdrawal')}
              >
                <Ionicons name="arrow-up-circle-outline" size={18} color="#fff" />
                <Text style={styles.heroButtonText}>Withdraw</Text>
              </Pressable>
            </View>
          </LinearGradient>

          <View style={styles.metrics}>
            <Metric
              icon="arrow-down"
              color={colors.danger}
              label="Spent"
              value={dashboard.totalSpent}
            />
            <Metric
              icon="trending-up"
              color={colors.success}
              label="Earned"
              value={dashboard.totalEarned}
            />
            <Metric
              icon="cash-outline"
              color={colors.info}
              label="Withdrawable"
              value={dashboard.availableToWithdraw}
            />
          </View>

          <Card style={styles.chartCard}>
            <View style={styles.chartHeader}>
              <View>
                <Text style={ui.h2}>Coin activity</Text>
                <Text style={ui.muted}>Earned vs spent</Text>
              </View>
              <View style={styles.legend}>
                <View style={[styles.legendDot, { backgroundColor: colors.success }]} />
                <Text style={styles.legendText}>Earned</Text>
                <View style={[styles.legendDot, { backgroundColor: colors.primary }]} />
                <Text style={styles.legendText}>Spent</Text>
              </View>
            </View>
            {!!dashboard.chart?.length && (
              <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.dayFilters}
              >
                <Pressable
                  onPress={() => setSelectedDay(null)}
                  style={[styles.dayChip, !selectedDay && styles.dayChipActive]}
                >
                  <Text style={[styles.dayChipText, !selectedDay && styles.dayChipTextActive]}>
                    All days
                  </Text>
                </Pressable>
                {dashboard.chart.map((item: any) => (
                  <Pressable
                    key={item.date}
                    onPress={() => setSelectedDay(item.date)}
                    style={[styles.dayChip, selectedDay === item.date && styles.dayChipActive]}
                  >
                    <Text
                      style={[
                        styles.dayChipText,
                        selectedDay === item.date && styles.dayChipTextActive,
                      ]}
                    >
                      {new Date(item.date).toLocaleDateString(undefined, {
                        day: 'numeric',
                        month: 'short',
                      })}
                    </Text>
                  </Pressable>
                ))}
              </ScrollView>
            )}
            {(selectedDay
              ? dashboard.chart.filter((item: any) => item.date === selectedDay)
              : visibleChart
            ).length ? (
              <View style={styles.chart}>
                <View style={styles.axisLabels}>
                  {[100, 75, 50, 25, 0].map((value) => (
                    <Text key={value} style={styles.axisValue}>
                      {Math.round((maxChart * value) / 100)}
                    </Text>
                  ))}
                </View>
                <View style={[styles.gridLine, { bottom: '25%' }]} />
                <View style={[styles.gridLine, { bottom: '50%' }]} />
                <View style={[styles.gridLine, { bottom: '75%' }]} />
                {(selectedDay
                  ? dashboard.chart.filter((item: any) => item.date === selectedDay)
                  : visibleChart
                ).map((item: any) => (
                  <View key={item.date} style={styles.chartColumn}>
                    <View style={styles.barPair}>
                      <PointBar value={item.earned} max={maxChart} color={colors.success} />
                      <PointBar value={item.spent} max={maxChart} color={colors.primary} />
                    </View>
                    <Text style={styles.axisLabel}>
                      {new Date(item.date).toLocaleDateString(undefined, {
                        day: 'numeric',
                        month: 'short',
                      })}
                    </Text>
                  </View>
                ))}
              </View>
            ) : (
              <View style={styles.emptyChart}>
                <Ionicons name="analytics-outline" size={32} color={colors.muted} />
                <Text style={ui.muted}>Activity will appear here</Text>
              </View>
            )}
          </Card>

          <Card style={styles.breakdownCard}>
            <Text style={ui.h2}>Balance breakdown</Text>
            <Breakdown
              label="Purchased coins"
              value={dashboard.purchasedCoins}
              color={colors.info}
            />
            <Breakdown label="Bonus coins" value={dashboard.bonusCoins} color={colors.accent} />
            <Breakdown
              label="Pending earnings"
              value={dashboard.pendingEarnings}
              color={colors.warning}
            />
            <Breakdown
              label="Held in sessions"
              value={dashboard.heldCoins}
              color={colors.primary}
            />
          </Card>

          <View style={styles.historyTitle}>
            <Text style={ui.h2}>Recent history</Text>
            <Text style={ui.muted}>{dashboard.history.length} activities</Text>
          </View>
          {dashboard.history.map((item: any) => (
            <Card key={`${item.kind}-${item.id}`} style={styles.historyCard}>
              <View
                style={[
                  styles.historyIcon,
                  { backgroundColor: item.amount > 0 ? '#EAF8F3' : '#FFF0F4' },
                ]}
              >
                <Ionicons
                  name={item.amount > 0 ? 'arrow-down' : 'arrow-up'}
                  size={19}
                  color={item.amount > 0 ? colors.success : colors.primary}
                />
              </View>
              <View style={{ flex: 1 }}>
                <Text style={styles.historyName}>
                  {item.title || item.type.replaceAll('_', ' ')}
                </Text>
                <Text style={ui.muted}>
                  {new Date(item.createdAt).toLocaleString()} · {item.status}
                </Text>
              </View>
              <Text
                style={[
                  styles.historyAmount,
                  { color: item.amount > 0 ? colors.success : colors.text },
                ]}
              >
                {item.amount > 0 ? '+' : ''}
                {item.amount}{item.currency ? ` ${item.currency}` : ''}
              </Text>
            </Card>
          ))}
          {!dashboard.history.length && (
            <EmptyState
              title="No activity"
              text="Your coin and earning history will appear here."
            />
          )}

          {/* Referral Section */}
          {referralInfo && (
            <Card style={styles.referralCard}>
              <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 10 }}>
                <Ionicons name="gift-outline" size={22} color={colors.primary} />
                <Text style={[ui.h2, { color: colors.primary }]}>Refer &amp; Earn 🎁</Text>
              </View>
              <Text style={[ui.muted, { marginBottom: 14, lineHeight: 18 }]}>
                Share your referral code. You earn <Text style={{ color: colors.success, fontWeight: '700' }}>{referralInfo.rewardPerReferral} coins</Text> for each friend who joins,
                and they get <Text style={{ color: colors.accent, fontWeight: '700' }}>{referralInfo.inviteeBonus} bonus coins</Text> too!
              </Text>
              <View style={styles.referralCodeBox}>
                <Text style={styles.referralCode}>{referralInfo.referralCode}</Text>
                <Pressable
                  style={styles.shareButton}
                  onPress={() => void Share.share({ message: `Join VibeCircle using my referral code: ${referralInfo.referralCode} and get ${referralInfo.inviteeBonus} free coins!` })}
                >
                  <Ionicons name="share-social-outline" size={18} color="#fff" />
                  <Text style={styles.shareButtonText}>Share Code</Text>
                </Pressable>
              </View>
              <View style={styles.referralStats}>
                <View style={styles.referralStat}>
                  <Text style={styles.referralStatValue}>{referralInfo.totalReferrals}</Text>
                  <Text style={styles.referralStatLabel}>Referrals</Text>
                </View>
                <View style={styles.referralStatDivider} />
                <View style={styles.referralStat}>
                  <Text style={[styles.referralStatValue, { color: colors.success }]}>+{referralInfo.totalEarned}</Text>
                  <Text style={styles.referralStatLabel}>Coins Earned</Text>
                </View>
              </View>
            </Card>
          )}
        </>
      ) : !loading ? (
        <EmptyState
          title="Dashboard unavailable"
          text="Please try again."
          action="Retry"
          onAction={() => void load()}
        />
      ) : null}
    </Screen>
  );
}

function PointBar({ value, max, color }: { value: number; max: number; color: string }) {
  const height = Math.max(8, Math.round(((value || 0) / max) * 118));
  return (
    <View style={[styles.pointBar, { height }]}>
      <Text style={styles.pointValue}>{value || 0}</Text>
      <View style={[styles.pointTriangle, { borderTopWidth: height, borderTopColor: color }]} />
      <View style={[styles.pointDiamond, { borderColor: color }]}>
        <Ionicons name="analytics-outline" size={9} color={color} style={styles.pointDiamondIcon} />
      </View>
    </View>
  );
}

function Metric({
  icon,
  color,
  label,
  value,
}: {
  icon: any;
  color: string;
  label: string;
  value: number;
}) {
  return (
    <Card style={styles.metric}>
      <View style={[styles.metricIcon, { backgroundColor: `${color}18` }]}>
        <Ionicons name={icon} size={17} color={color} />
      </View>
      <Text style={styles.metricValue}>{value || 0}</Text>
      <Text style={styles.metricLabel}>{label}</Text>
    </Card>
  );
}

function Breakdown({ label, value, color }: { label: string; value: number; color: string }) {
  return (
    <View style={styles.breakdownRow}>
      <View style={[styles.breakdownDot, { backgroundColor: color }]} />
      <Text style={[ui.body, { flex: 1 }]}>{label}</Text>
      <Text style={styles.breakdownValue}>{value || 0}</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  periodTabs: {
    flexDirection: 'row',
    padding: 4,
    borderRadius: 16,
    backgroundColor: '#F1EDF5',
    gap: 4,
  },
  periodTab: { flex: 1, paddingVertical: 9, borderRadius: 12, alignItems: 'center' },
  periodTabActive: {
    backgroundColor: colors.surface,
    elevation: 2,
    shadowColor: '#25152F',
    shadowOpacity: 0.08,
    shadowRadius: 6,
  },
  periodText: { color: colors.muted, fontSize: 12, fontWeight: '800' },
  periodTextActive: { color: colors.primary },
  balanceHero: { padding: 20, borderRadius: 24, gap: 20 },
  heroTop: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  heroLabel: {
    color: 'rgba(255,255,255,.72)',
    fontSize: 10,
    fontWeight: '900',
    letterSpacing: 1.2,
  },
  heroValue: { color: '#fff', fontSize: 42, lineHeight: 48, fontWeight: '900' },
  heroUnit: { color: 'rgba(255,255,255,.76)', fontSize: 12, fontWeight: '600' },
  heroIcon: {
    width: 48,
    height: 48,
    borderRadius: 16,
    backgroundColor: 'rgba(255,255,255,.16)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroActions: { flexDirection: 'row', gap: 10 },
  heroButton: {
    flex: 1,
    flexDirection: 'row',
    gap: 7,
    minHeight: 42,
    borderRadius: 13,
    backgroundColor: 'rgba(255,255,255,.16)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroButtonText: { color: '#fff', fontSize: 12, fontWeight: '800' },
  metrics: { flexDirection: 'row', gap: 8 },
  metric: { flex: 1, padding: 12, gap: 5 },
  metricIcon: {
    width: 30,
    height: 30,
    borderRadius: 10,
    alignItems: 'center',
    justifyContent: 'center',
  },
  metricValue: { color: colors.text, fontSize: 19, fontWeight: '900' },
  metricLabel: { color: colors.muted, fontSize: 10, fontWeight: '700' },
  chartCard: { paddingBottom: 12 },
  chartHeader: { flexDirection: 'row', justifyContent: 'space-between', alignItems: 'flex-start' },
  legend: { flexDirection: 'row', alignItems: 'center', gap: 5, paddingTop: 4 },
  legendDot: { width: 7, height: 7, borderRadius: 4 },
  legendText: { color: colors.muted, fontSize: 9, fontWeight: '700', marginRight: 3 },
  dayFilters: { gap: 7, paddingTop: 14, paddingBottom: 2 },
  dayChip: {
    paddingHorizontal: 11,
    paddingVertical: 7,
    borderRadius: 10,
    backgroundColor: '#F5F1F5',
    borderWidth: 1,
    borderColor: '#F0E5EB',
  },
  dayChipActive: { backgroundColor: colors.primary, borderColor: colors.primary },
  dayChipText: { color: colors.muted, fontSize: 10, fontWeight: '800' },
  dayChipTextActive: { color: '#fff' },
  chart: {
    height: 210,
    flexDirection: 'row',
    alignItems: 'stretch',
    paddingTop: 18,
    paddingBottom: 28,
    paddingLeft: 26,
    marginTop: 10,
    position: 'relative',
  },
  gridLine: { position: 'absolute', left: 26, right: 0, height: 1, backgroundColor: '#EDE4EA' },
  axisLabels: {
    position: 'absolute',
    left: 0,
    top: 8,
    bottom: 25,
    justifyContent: 'space-between',
  },
  axisValue: { color: colors.muted, fontSize: 8, fontWeight: '700' },
  chartColumn: { flex: 1, alignItems: 'center', justifyContent: 'flex-end', zIndex: 1 },
  barPair: {
    height: '100%',
    width: '88%',
    flexDirection: 'row',
    alignItems: 'flex-end',
    justifyContent: 'center',
    gap: 5,
  },
  pointBar: { width: 18, alignItems: 'center' },
  pointTriangle: {
    width: 0,
    height: 0,
    borderLeftWidth: 9,
    borderRightWidth: 9,
    borderLeftColor: 'transparent',
    borderRightColor: 'transparent',
  },
  pointDiamond: {
    position: 'absolute',
    top: -7,
    width: 18,
    height: 18,
    backgroundColor: '#fff',
    borderWidth: 1.5,
    transform: [{ rotate: '45deg' }],
    alignItems: 'center',
    justifyContent: 'center',
  },
  pointDiamondIcon: { transform: [{ rotate: '-45deg' }] },
  pointValue: {
    position: 'absolute',
    top: -25,
    color: colors.text,
    fontSize: 8,
    fontWeight: '900',
  },
  axisLabel: {
    position: 'absolute',
    bottom: -18,
    color: colors.muted,
    fontSize: 8,
    fontWeight: '700',
    width: 50,
    textAlign: 'center',
  },
  emptyChart: { height: 170, alignItems: 'center', justifyContent: 'center', gap: 8 },
  breakdownCard: { gap: 4 },
  breakdownRow: {
    minHeight: 38,
    flexDirection: 'row',
    alignItems: 'center',
    gap: 9,
    borderBottomWidth: 1,
    borderBottomColor: '#F5EEF2',
  },
  breakdownDot: { width: 8, height: 8, borderRadius: 4 },
  breakdownValue: { color: colors.text, fontSize: 14, fontWeight: '900' },
  historyTitle: {
    flexDirection: 'row',
    justifyContent: 'space-between',
    alignItems: 'center',
    marginTop: 2,
  },
  historyCard: { flexDirection: 'row', alignItems: 'center', gap: 11, padding: 12 },
  historyIcon: {
    width: 40,
    height: 40,
    borderRadius: 13,
    alignItems: 'center',
    justifyContent: 'center',
  },
  historyName: { color: colors.text, fontSize: 13, fontWeight: '800', textTransform: 'capitalize' },
  historyAmount: { fontSize: 15, fontWeight: '900' },
  referralCard: { gap: 0, overflow: 'hidden' },
  referralCodeBox: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    backgroundColor: '#F4F0FF',
    borderRadius: 12,
    padding: 12,
    marginBottom: 12,
    gap: 10,
  },
  referralCode: {
    fontSize: 22,
    fontWeight: '900',
    letterSpacing: 4,
    color: colors.primary,
    flex: 1,
  },
  shareButton: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 6,
    backgroundColor: colors.primary,
    borderRadius: 10,
    paddingHorizontal: 14,
    paddingVertical: 9,
  },
  shareButtonText: { color: '#fff', fontWeight: '800', fontSize: 13 },
  referralStats: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#F9F8FF',
    borderRadius: 12,
    padding: 12,
    gap: 0,
  },
  referralStat: { flex: 1, alignItems: 'center', gap: 3 },
  referralStatValue: { fontSize: 22, fontWeight: '900', color: colors.text },
  referralStatLabel: { fontSize: 12, color: colors.muted, fontWeight: '600' },
  referralStatDivider: { width: 1, height: 36, backgroundColor: '#E0DFF5', marginHorizontal: 8 },
});

export default WalletScreen;
