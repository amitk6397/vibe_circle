import React, { useCallback, useState } from 'react';
import { Alert, Text, View } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Button, Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { chatApi } from '../../../services/api';
import { MessageRequest } from '../../conversation/models/ConversationAccess';

export function MessageRequestsScreen({ navigation }: any) {
  const [requests, setRequests] = useState<MessageRequest[]>([]);
  const [loading, setLoading] = useState(true);
  const load = useCallback(async () => {
    setLoading(true);
    try {
      const { data } = await chatApi.messageRequests();
      setRequests(data.filter((x) => x.status === 'pending'));
    } catch (error: any) {
      Alert.alert('Requests unavailable', error.message);
    } finally {
      setLoading(false);
    }
  }, []);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );
  const act = async (item: MessageRequest, action: 'accept' | 'reject' | 'block') => {
    try {
      const { data } = await chatApi.messageRequestAction(item.id, action);
      setRequests((items) => items.filter((x) => x.id !== item.id));
      if (action === 'accept' && data.conversationId)
        navigation.navigate('PrivateChat', {
          chatId: data.conversationId,
          name: item.senderName,
          personId: item.senderId,
        });
    } catch (error: any) {
      Alert.alert('Could not update request', error.message);
    }
  };
  return (
    <Screen>
      <Header
        title="Message requests"
        subtitle="Review introductions before starting a conversation"
        onBack={() => navigation.goBack()}
      />
      {requests.map((item) => (
        <Card key={item.id}>
          <Text style={ui.h2}>{item.senderName}</Text>
          <Text style={ui.body}>{item.introduction}</Text>
          {!!item.chatPrice && (
            <Text style={ui.muted}>
              Paid chat: {item.reservedMinutes} min · {item.chatPricePerMinute} coins/min ·{' '}
              {item.chatPrice} coins total.
            </Text>
          )}
          <View style={{ flexDirection: 'row', gap: 8, marginTop: 12 }}>
            <View style={{ flex: 1 }}>
              <Button compact title="Accept" onPress={() => void act(item, 'accept')} />
            </View>
            <View style={{ flex: 1 }}>
              <Button
                compact
                tone="secondary"
                title="Reject"
                onPress={() => void act(item, 'reject')}
              />
            </View>
          </View>
          <Button compact tone="ghost" title="Block" onPress={() => void act(item, 'block')} />
        </Card>
      ))}
      {!loading && !requests.length && (
        <EmptyState
          icon="mail-open-outline"
          title="No message requests"
          text="New introductions will appear here."
        />
      )}
    </Screen>
  );
}
export default MessageRequestsScreen;
