import React, { useCallback, useState } from 'react';
import { Alert, Pressable, StyleSheet, Text, View, ScrollView } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Ionicons } from '@expo/vector-icons';
import { LinearGradient } from 'expo-linear-gradient';
import { Button, Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { colors, gradients } from '../../../theme';
import { walletApi } from '../../../services/api';
import { CoinPackage } from '../../commerce/models/Commerce';

export function SubscriptionPlansScreen({ navigation }: any) {
  const [packages, setPackages] = useState<CoinPackage[]>([]);
  const [loading, setLoading] = useState(true);
  const [buying, setBuying] = useState('');

  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await walletApi.packages();
      setPackages(data);
    } catch (error: any) {
      Alert.alert('Coins unavailable', error.message || 'Please try again.');
    } finally {
      setLoading(false);
    }
  }, []);

  useFocusEffect(useCallback(() => void load(), [load]));

  const buyCoins = async (item: CoinPackage) => {
    setBuying(item.id);
    try {
      await walletApi.buyCoins(item.id, `dummy_${Date.now()}_${item.id}`);
      Alert.alert(
        'Coins added successfully! 🎉',
        `${item.purchasedCoins + item.bonusCoins} coins have been added to your wallet.`,
      );
    } catch (error: any) {
      Alert.alert('Purchase failed', error.message);
    } finally {
      setBuying('');
    }
  };

  return (
    <Screen>
      <Header
        title="Coin Store"
        subtitle="Power your conversations & interactions"
        onBack={() => navigation.goBack()}
      />

      <LinearGradient
        colors={gradients.warm}
        style={styles.hero}
      >
        <View style={styles.heroIcon}>
          <Ionicons name="wallet-outline" size={24} color="#fff" />
        </View>
        <View style={{ flex: 1 }}>
          <Text style={styles.heroTitle}>Premium Coin Store</Text>
          <Text style={styles.heroText}>
            Coins allow you to interact with creators, start paid chat sessions, unlock premium posts, and join private communities.
          </Text>
        </View>
      </LinearGradient>

      {/* Creator Earning Info */}
      <Card style={styles.earnCard}>
        <View style={styles.earnRow}>
          <View style={[styles.earnIcon, { backgroundColor: '#EAF8F3' }]}>
            <Ionicons name="trending-up" size={20} color={colors.success} />
          </View>
          <View style={{ flex: 1 }}>
            <Text style={styles.earnTitle}>💸 Earn while you chat</Text>
            <Text style={ui.muted}>
              You can also earn coins! When other users pay coins to chat or call you, you keep{' '}
              <Text style={{ color: colors.success, fontWeight: '900' }}>80%</Text> of those coins. Withdraw them as real cash anytime.
            </Text>
          </View>
        </View>
      </Card>

      {/* Coin Rates Info Card */}
      <Card style={styles.ratesCard}>
        <Text style={styles.ratesTitle}>💡 Coin Usage Rates</Text>
        <View style={styles.ratesGrid}>
          <View style={styles.rateItem}>
            <Ionicons name="chatbubble-ellipses-outline" size={16} color={colors.primary} />
            <Text style={styles.rateLabel}>Paid Chat</Text>
            <Text style={styles.rateValue}>2 coins / min</Text>
          </View>
          <View style={styles.rateItem}>
            <Ionicons name="call-outline" size={16} color={colors.success} />
            <Text style={styles.rateLabel}>Audio Call</Text>
            <Text style={styles.rateValue}>5 coins / min</Text>
          </View>
          <View style={styles.rateItem}>
            <Ionicons name="videocam-outline" size={16} color={colors.info} />
            <Text style={styles.rateLabel}>Video Call</Text>
            <Text style={styles.rateValue}>10 coins / min</Text>
          </View>
        </View>
      </Card>

      <Text style={ui.h2}>Select a Coin Pack</Text>

      {loading ? (
        <View style={{ padding: 40, alignItems: 'center' }}>
          <Text style={ui.muted}>Loading coin packages...</Text>
        </View>
      ) : packages.length ? (
        <View style={styles.coinGrid}>
          {packages.map((item, index) => {
            const isPopular = index === 1;
            const discountPercent = item.bonusCoins > 0 
              ? Math.round((item.bonusCoins / item.purchasedCoins) * 100)
              : 0;

            return (
              <Card 
                key={item.id} 
                style={[
                  styles.coinCard, 
                  isPopular && styles.highlightedCoin,
                  { backgroundColor: isPopular ? '#FFFBFD' : '#ffffff' }
                ]}
              >
                {item.bonusCoins > 0 && (
                  <View style={styles.bonusBadge}>
                    <Text style={styles.bonusText}>+{discountPercent}% FREE</Text>
                  </View>
                )}
                {isPopular && (
                  <View style={styles.popularTag}>
                    <Text style={styles.popularText}>POPULAR</Text>
                  </View>
                )}
                
                <LinearGradient
                  colors={isPopular ? gradients.support : gradients.warm}
                  style={styles.coinIcon}
                >
                  <Ionicons name="logo-bitcoin" size={26} color="#fff" />
                </LinearGradient>

                <Text style={styles.coinTotal}>{item.purchasedCoins + item.bonusCoins}</Text>
                <Text style={styles.coinLabel}>COINS</Text>
                
                {item.bonusCoins > 0 && (
                  <Text style={styles.bonusSub}>Includes {item.bonusCoins} bonus coins</Text>
                )}

                <Text style={styles.packName}>{item.name}</Text>
                
                <Button
                  compact
                  loading={buying === item.id}
                  tone={isPopular ? 'primary' : 'secondary'}
                  title={`Buy for ${item.currency} ${item.price}`}
                  onPress={() => void buyCoins(item)}
                />
              </Card>
            );
          })}
        </View>
      ) : (
        <EmptyState title="No Packages Available" text="Please try again later." />
      )}

      <View style={styles.secure}>
        <Ionicons name="shield-checkmark-outline" size={17} color={colors.success} />
        <Text style={ui.muted}>Secure checkout · Managed by platform admin</Text>
      </View>
    </Screen>
  );
}

const styles = StyleSheet.create({
  hero: { borderRadius: 22, padding: 18, flexDirection: 'row', gap: 13, alignItems: 'center' },
  heroIcon: {
    width: 46,
    height: 46,
    borderRadius: 15,
    backgroundColor: 'rgba(255,255,255,.16)',
    alignItems: 'center',
    justifyContent: 'center',
  },
  heroTitle: { color: '#fff', fontSize: 18, fontWeight: '900', marginBottom: 3 },
  heroText: { color: 'rgba(255,255,255,.85)', fontSize: 11, lineHeight: 16, fontWeight: '600' },
  coinGrid: { flexDirection: 'row', flexWrap: 'wrap', gap: 10, paddingVertical: 10 },
  coinCard: {
    width: '48%',
    minHeight: 240,
    alignItems: 'center',
    gap: 5,
    padding: 14,
    overflow: 'hidden',
    position: 'relative',
    borderWidth: 1,
    borderColor: '#F0E5EB',
  },
  highlightedCoin: { borderColor: colors.primary, borderWidth: 2 },
  bonusBadge: {
    position: 'absolute',
    top: 8,
    left: 8,
    backgroundColor: '#EAF8F3',
    borderRadius: 8,
    paddingHorizontal: 6,
    paddingVertical: 3,
  },
  bonusText: { color: colors.success, fontSize: 8, fontWeight: '900' },
  popularTag: {
    position: 'absolute',
    top: 8,
    right: 8,
    backgroundColor: colors.primary,
    borderRadius: 8,
    paddingHorizontal: 6,
    paddingVertical: 3,
  },
  popularText: { color: '#fff', fontSize: 8, fontWeight: '900' },
  coinIcon: {
    width: 52,
    height: 52,
    borderRadius: 19,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 15,
    marginBottom: 5,
  },
  coinTotal: { color: colors.text, fontSize: 32, lineHeight: 36, fontWeight: '900' },
  coinLabel: { color: colors.primary, fontSize: 9, letterSpacing: 1.3, fontWeight: '900' },
  bonusSub: { color: colors.success, fontSize: 9, fontWeight: '700', textAlign: 'center' },
  packName: { color: colors.muted, fontSize: 11, fontWeight: '700', marginBottom: 12, marginTop: 4 },
  secure: {
    flexDirection: 'row',
    gap: 7,
    alignItems: 'center',
    justifyContent: 'center',
    paddingVertical: 18,
  },
  earnCard: { padding: 16, marginTop: 10 },
  earnRow: { flexDirection: 'row', gap: 12, alignItems: 'flex-start' },
  earnIcon: { width: 40, height: 40, borderRadius: 13, alignItems: 'center', justifyContent: 'center' },
  earnTitle: { color: colors.text, fontSize: 14, fontWeight: '900', marginBottom: 5 },
  ratesCard: { padding: 16, marginTop: 10, gap: 10 },
  ratesTitle: { color: colors.text, fontSize: 14, fontWeight: '900' },
  ratesGrid: { flexDirection: 'row', justifyContent: 'space-between', gap: 6, marginTop: 4 },
  rateItem: {
    flex: 1,
    alignItems: 'center',
    backgroundColor: '#F7F4FA',
    paddingVertical: 10,
    borderRadius: 12,
    gap: 4,
    borderWidth: 1,
    borderColor: '#ECE6F2',
  },
  rateLabel: { color: colors.muted, fontSize: 9, fontWeight: '800' },
  rateValue: { color: colors.text, fontSize: 10, fontWeight: '900' },
});

export default SubscriptionPlansScreen;
