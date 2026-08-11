import React, { useState } from 'react';
import { Alert, Text, View } from 'react-native';
import { Button, Card, Field, Header, Pill, Screen, ui } from '../../../components/ui';
import { chatApi, walletApi } from '../../../services/api';

export function NewMessageRequestScreen({ navigation, route }: any) {
  const [introduction, setIntroduction] = useState('');
  const [saving, setSaving] = useState(false);
  const [duration, setDuration] = useState(10);
  const [pricing, setPricing] = useState<any>({
    chatCoinsPerMinute: route.params.chatPrice || 0,
    chatDurationOptions: [5, 10, 15, 30],
  });
  React.useEffect(() => {
    void walletApi.pricing().then(({ data }) => setPricing(data));
  }, []);
  const send = async () => {
    const text = introduction.trim();
    if (!text)
      return Alert.alert(
        'Add an introduction',
        'Write a short, respectful reason for reaching out.',
      );
    setSaving(true);
    try {
      await chatApi.sendMessageRequest(route.params.personId, text, duration);
      Alert.alert(
        'Request sent',
        `${route.params.name} can accept, reject, block, or report this request.`,
      );
      navigation.goBack();
    } catch (error: any) {
      Alert.alert(
        'Coins required',
        error.message || 'Please add enough coins to start this paid chat.',
        [
          { text: 'Cancel', style: 'cancel' },
          { text: 'View plans & coins', onPress: () => navigation.navigate('SubscriptionPlans') },
        ],
      );
    } finally {
      setSaving(false);
    }
  };
  return (
    <Screen>
      <Header
        title="Message request"
        subtitle={`Introduce yourself to ${route.params.name}`}
        onBack={() => navigation.goBack()}
      />
      <Card>
        <Text style={ui.body}>
          Your first message is sent as a request. Media, links, phone numbers, and calls remain
          unavailable until it is accepted.
        </Text>
      </Card>
      <Card>
        <Text style={ui.h2}>Paid private chat</Text>
        <Text style={ui.body}>{pricing.chatCoinsPerMinute} coins/minute · choose duration</Text>
        <View style={ui.wrap}>
          {pricing.chatDurationOptions.map((minutes: number) => (
            <Pill
              key={minutes}
              label={`${minutes} min`}
              selected={duration === minutes}
              onPress={() => setDuration(minutes)}
            />
          ))}
        </View>
        <Text style={ui.body}>Total hold: {pricing.chatCoinsPerMinute * duration} coins</Text>
        <Text style={ui.muted}>
          Charged only when {route.params.name} accepts. An active plan and enough coins are
          required.
        </Text>
      </Card>
      <Field
        label="Introduction"
        value={introduction}
        onChangeText={setIntroduction}
        multiline
        placeholder="Hi! I noticed we both enjoy..."
      />
      <Text style={ui.muted}>{introduction.length}/300 characters</Text>
      <Button
        title="Send paid request"
        loading={saving}
        disabled={saving || introduction.trim().length > 300}
        onPress={() => void send()}
      />
    </Screen>
  );
}
export default NewMessageRequestScreen;
