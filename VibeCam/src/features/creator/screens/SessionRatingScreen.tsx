import React, { useEffect, useState } from 'react';
import { Alert, Text, View } from 'react-native';
import { Button, Field, Header, Pill, Screen, ui } from '../../../components/ui';
import { engagementApi, walletApi } from '../../../services/api';

export function SessionRatingScreen({ navigation, route }: any) {
  const [overall, setOverall] = useState(5);
  const [review, setReview] = useState('');
  const [saving, setSaving] = useState(false);
  const [gifts, setGifts] = useState<any[]>([]);
  useEffect(() => {
    void engagementApi.gifts().then(({ data }) => setGifts(data));
  }, []);
  const tip = async (gift: any) => {
    try {
      const { data: wallet } = await walletApi.get();
      Alert.alert(
        `Send ${gift.name}?`,
        `${gift.coin_price} coins · balance ${wallet.purchased_coins + wallet.bonus_coins}`,
        [
          { text: 'Cancel', style: 'cancel' },
          {
            text: 'Send tip',
            onPress: () =>
              void engagementApi
                .sendGift({
                  gift_id: gift.id,
                  recipient_id: route.params.userId,
                  target_type: route.params.sessionType === 'chat' ? 'chat' : 'audio_call',
                  target_id: route.params.sessionId,
                })
                .then(() => Alert.alert('Tip sent'))
                .catch((error) => Alert.alert('Tip failed', error.message)),
          },
        ],
      );
    } catch (error: any) {
      Alert.alert('Wallet unavailable', error.message);
    }
  };
  const submit = async () => {
    setSaving(true);
    try {
      await engagementApi.submitRating({
        session_id: route.params.sessionId,
        overall_rating: overall,
        conversation_quality: overall,
        behaviour: overall,
        helpfulness: overall,
        media_quality: overall,
        review,
      });
      Alert.alert('Thank you', 'Your verified-session review was submitted.');
      navigation.popToTop();
    } catch (error: any) {
      Alert.alert('Review failed', error.message);
    } finally {
      setSaving(false);
    }
  };
  return (
    <Screen>
      <Header
        title="Rate your session"
        subtitle="Only completed-session reviews are accepted"
        onBack={() => navigation.goBack()}
      />
      <Text style={ui.h2}>Overall rating</Text>
      <View style={ui.wrap}>
        {[1, 2, 3, 4, 5].map((value) => (
          <Pill
            key={value}
            label={`${value} ★`}
            selected={overall === value}
            onPress={() => setOverall(value)}
          />
        ))}
      </View>
      <Field label="Written review (optional)" multiline value={review} onChangeText={setReview} />
      <Button title="Submit review" loading={saving} onPress={() => void submit()} />
      <Text style={ui.h2}>Optional tip</Text>
      {gifts.map((gift) => (
        <Button
          key={gift.id}
          title={`${gift.name} · ${gift.coin_price} coins`}
          tone="secondary"
          onPress={() => void tip(gift)}
        />
      ))}
    </Screen>
  );
}
export default SessionRatingScreen;
