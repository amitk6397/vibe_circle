import React, { useState } from 'react';
import { Text, View, ScrollView, Image, StyleSheet, Dimensions } from 'react-native';
import { Button, Card, Header, Screen, ui } from '../../../components/ui';
import { environment } from '../../../config/environment';
import { useWalletViewModel } from '../viewmodels/useWalletViewModel';

export function BuyCoinsScreen({ navigation }: any) {
  const { packages, offers, buy } = useWalletViewModel();
  const [buying, setBuying] = useState('');

  return (
    <Screen>
      <Header
        title="Buy coins"
        subtitle="Development payment simulator"
        onBack={() => navigation.goBack()}
      />
      {!environment.dummyPayments && (
        <Card>
          <Text style={ui.body}>Purchases are disabled until store billing is configured.</Text>
        </Card>
      )}

      {/* Special Offers Carousel */}
      {offers && offers.length > 0 && (
        <View style={styles.offersContainer}>
          <Text style={[ui.h2, { marginBottom: 10 }]}>Special Promotions</Text>
          <ScrollView
            horizontal
            showsHorizontalScrollIndicator={false}
            contentContainerStyle={styles.offersList}
          >
            {offers.map((offer: any) => (
              <View key={offer.id} style={styles.offerCard}>
                {offer.bannerUrl ? (
                  <Image source={{ uri: offer.bannerUrl }} style={styles.offerBanner} resizeMode="cover" />
                ) : (
                  <View style={styles.offerTextCard}>
                    <Text style={styles.offerTitle}>{offer.title}</Text>
                    <Text style={styles.offerDesc} numberOfLines={2}>{offer.description}</Text>
                    {offer.discountPercentage > 0 && (
                      <View style={styles.offerBadge}>
                        <Text style={styles.offerBadgeText}>{offer.discountPercentage}% OFF</Text>
                      </View>
                    )}
                    {offer.bonusCoinsPercentage > 0 && (
                      <View style={styles.offerBadgeBonus}>
                        <Text style={styles.offerBadgeText}>+{offer.bonusCoinsPercentage}% BONUS</Text>
                      </View>
                    )}
                  </View>
                )}
              </View>
            ))}
          </ScrollView>
        </View>
      )}

      {/* Coin Packages */}
      {packages.map((item: any) => {
        const originalPrice = item.price / (1 - (item.discountPercentage || 0) / 100);
        return (
          <Card key={item.id}>
            <View style={{ position: 'relative', width: '100%' }}>
              {item.badge ? (
                <View style={styles.pkgBadge}>
                  <Text style={styles.pkgBadgeText}>{item.badge}</Text>
                </View>
              ) : null}
              {item.isPopular ? (
                <Text style={{ color: '#eab308', fontSize: 11, fontWeight: 'bold', textTransform: 'uppercase', marginBottom: 2 }}>⭐ Popular Choice</Text>
              ) : null}
              <Text style={ui.h2}>{item.name}</Text>
              {item.description ? (
                <Text style={[ui.body, { fontSize: 13, color: '#8888aa', marginBottom: 6, marginTop: -2 }]}>{item.description}</Text>
              ) : null}
              <Text style={[ui.body, { marginBottom: 6 }]}>
                {item.purchasedCoins} purchased coins
                {item.bonusCoins ? ` + ${item.bonusCoins} bonus` : ''}
              </Text>
              
              {item.discountPercentage && item.discountPercentage > 0 ? (
                <View style={{ flexDirection: 'row', alignItems: 'center', gap: 8, marginBottom: 12 }}>
                  <Text style={ui.title}>{item.currency} {item.price}</Text>
                  <Text style={[ui.body, { textDecorationLine: 'line-through', opacity: 0.5, fontSize: 14, marginBottom: 0 }]}>
                    {item.currency} {originalPrice.toFixed(0)}
                  </Text>
                  <Text style={{ color: '#22c55e', fontSize: 12, fontWeight: '700' }}>({item.discountPercentage}% OFF)</Text>
                </View>
              ) : (
                <Text style={[ui.title, { marginBottom: 12 }]}>{item.currency} {item.price}</Text>
              )}
              
              <Button
                title="Simulate purchase"
                loading={buying === item.id}
                disabled={!environment.dummyPayments || !!buying}
                onPress={async () => {
                  setBuying(item.id);
                  try {
                    await buy(item.id);
                    navigation.replace('PaymentSuccess', { kind: 'coins' });
                  } catch (error: any) {
                    navigation.replace('PaymentFailure', { message: error.message });
                  } finally {
                    setBuying('');
                  }
                }}
              />
            </View>
          </Card>
        );
      })}
    </Screen>
  );
}

const { width } = Dimensions.get('window');

const styles = StyleSheet.create({
  offersContainer: {
    marginVertical: 15,
    paddingHorizontal: 4,
  },
  offersList: {
    gap: 12,
    paddingRight: 10,
  },
  offerCard: {
    width: width - 48,
    height: 120,
    borderRadius: 12,
    overflow: 'hidden',
    backgroundColor: '#1f1f2e',
    borderWidth: 1,
    borderColor: '#2e2e42',
  },
  offerBanner: {
    width: '100%',
    height: '100%',
  },
  offerTextCard: {
    padding: 16,
    height: '100%',
    justifyContent: 'center',
    backgroundColor: '#35225d',
  },
  offerTitle: {
    color: '#ffffff',
    fontSize: 16,
    fontWeight: 'bold',
    marginBottom: 4,
  },
  offerDesc: {
    color: '#ccccff',
    fontSize: 12,
    marginBottom: 8,
  },
  offerBadge: {
    alignSelf: 'flex-start',
    backgroundColor: '#22c55e',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  offerBadgeBonus: {
    alignSelf: 'flex-start',
    backgroundColor: '#eab308',
    paddingHorizontal: 8,
    paddingVertical: 2,
    borderRadius: 6,
  },
  offerBadgeText: {
    color: '#ffffff',
    fontSize: 9,
    fontWeight: 'bold',
  },
  pkgBadge: {
    position: 'absolute',
    top: 0,
    right: 0,
    backgroundColor: '#6c5dd3',
    paddingHorizontal: 8,
    paddingVertical: 3,
    borderRadius: 6,
    zIndex: 10,
  },
  pkgBadgeText: {
    color: '#ffffff',
    fontSize: 10,
    fontWeight: 'bold',
    textTransform: 'uppercase',
  },
});

export default BuyCoinsScreen;
