import React, { useEffect, useState } from 'react';
import { Alert, Text, View } from 'react-native';
import { Avatar, Button, Card, EmptyState, Header, Pill, Screen, ui } from '../../../components/ui';
import { earningsApi, engagementApi, safetyApi, walletApi } from '../../../services/api';
import { UserPerformanceProfile } from '../../commerce/models/Commerce';
import { callApi } from '../../chat/services/callApi';

export function UserPerformanceScreen({ navigation, route }: any) {
  const [profile, setProfile] = useState<UserPerformanceProfile | null>(null);
  const [gifts, setGifts] = useState<any[]>([]);
  const [reviews, setReviews] = useState<any[]>([]);
  const [error, setError] = useState('');

  useEffect(() => {
    void Promise.all([
      earningsApi.profile(route.params.userId),
      engagementApi.gifts(),
      engagementApi.reviews(route.params.userId),
    ])
      .then(([profileResult, giftResult, reviewResult]) => {
        setProfile(profileResult.data);
        setGifts(giftResult.data);
        setReviews(reviewResult.data);
      })
      .catch((reason) => setError(reason.message));
  }, [route.params.userId]);

  if (error)
    return (
      <Screen>
        <Header title="Performance" onBack={() => navigation.goBack()} />
        <EmptyState title="User unavailable" text={error} />
      </Screen>
    );
  if (!profile)
    return (
      <Screen>
        <Header title="Performance" onBack={() => navigation.goBack()} />
        <Text style={ui.muted}>Loading...</Text>
      </Screen>
    );

  const requestCall = async (type: 'audio' | 'video') => {
    const price = type === 'audio' ? profile.audioPricePerMinute : profile.videoPricePerMinute;
    try {
      const { data: config } = await callApi.config();
      Alert.alert(
        `${type === 'audio' ? 'Audio' : 'Video'} session`,
        'Choose a duration. Credits are locked only after acceptance.',
        [
          { text: 'Cancel', style: 'cancel' },
          ...config.durationOptions.map((minutes) => ({
            text: `${minutes} min · up to ${price * minutes} coins`,
            onPress: async () => {
              try {
                const { data } = await callApi.requestPaid(profile.userId, type, minutes);
                Alert.alert('Session requested', 'Coins will be locked only if the user accepts.');
                navigation.navigate(type === 'audio' ? 'AudioCall' : 'VideoCall', {
                  name: profile.name,
                  callId: data.id,
                  chatId: data.conversationId,
                  personId: profile.userId,
                });
              } catch (reason: any) {
                Alert.alert('Request failed', reason.message);
              }
            },
          })),
        ],
      );
    } catch (reason: any) {
      Alert.alert('Session options unavailable', reason.message);
    }
  };

  const gift = async (item: any) => {
    try {
      const { data: wallet } = await walletApi.get();
      const balance = wallet.purchased_coins + wallet.bonus_coins;
      Alert.alert(`Send ${item.name}?`, `${item.coin_price} coins · balance ${balance}`, [
        { text: 'Cancel', style: 'cancel' },
        {
          text: 'Send',
          onPress: () =>
            void engagementApi
              .sendGift({
                gift_id: item.id,
                recipient_id: profile.userId,
                target_type: 'user_profile',
                target_id: profile.userId,
              })
              .then(() => Alert.alert('Gift sent'))
              .catch((reason) => Alert.alert('Gift failed', reason.message)),
        },
      ]);
    } catch (reason: any) {
      Alert.alert('Wallet unavailable', reason.message);
    }
  };

  return (
    <Screen>
      <Header title="Performance & rates" onBack={() => navigation.goBack()} />
      <View style={{ alignItems: 'center', gap: 8 }}>
        <Avatar name={profile.name} uri={profile.avatarUrl} size={92} />
        <Text style={ui.title}>
          {profile.name} {profile.verified ? '✓' : ''}
        </Text>
        <Text style={ui.muted}>
          {profile.category} · {profile.availabilityStatus}
        </Text>
      </View>
      <Card>
        <Text style={ui.body}>{profile.introduction}</Text>
        <Text style={ui.muted}>
          {profile.rating.toFixed(1)} rating · {profile.totalCompletedSessions} sessions ·{' '}
          {profile.responseRate}% response
        </Text>
      </Card>
      <View style={ui.wrap}>
        {profile.topics.map((topic) => (
          <Pill key={topic} label={topic} />
        ))}
      </View>
      <Button
        title={`Start chat · ${profile.chatPrice} coins/min`}
        disabled={!profile.chatAvailable}
        onPress={() =>
          navigation.navigate('NewMessageRequest', {
            personId: profile.userId,
            name: profile.name,
            chatPrice: profile.chatPrice,
          })
        }
      />
      <Button
        title={`Audio call · ${profile.audioPricePerMinute}/min`}
        disabled={!profile.audioAvailable}
        onPress={() => void requestCall('audio')}
      />
      <Button
        title={`Video call · ${profile.videoPricePerMinute}/min`}
        disabled={!profile.videoAvailable}
        onPress={() => void requestCall('video')}
      />
      <Text style={ui.h2}>Send a gift</Text>
      {gifts.map((item) => (
        <Button
          key={item.id}
          title={`${item.name} · ${item.coin_price} coins`}
          tone="secondary"
          onPress={() => void gift(item)}
        />
      ))}
      <Text style={ui.h2}>Recent reviews</Text>
      {reviews.length ? (
        reviews.slice(0, 5).map((item) => (
          <Card key={item.id}>
            <Text style={ui.body}>
              {'★'.repeat(item.overall_rating)}
              {'☆'.repeat(5 - item.overall_rating)}
            </Text>
            <Text style={ui.body}>{item.review || 'No written review.'}</Text>
            <Button
              compact
              title="Report review"
              tone="ghost"
              onPress={() =>
                void safetyApi
                  .report('rating', item.id, 'Abusive language')
                  .then(() => Alert.alert('Review reported'))
                  .catch((reason) => Alert.alert('Report failed', reason.message))
              }
            />
          </Card>
        ))
      ) : (
        <Text style={ui.muted}>No reviews yet.</Text>
      )}
      <Button
        title="Report user"
        tone="ghost"
        onPress={() => navigation.navigate('PublicProfile', { personId: profile.userId })}
      />
    </Screen>
  );
}

export default UserPerformanceScreen;
