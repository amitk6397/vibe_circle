import React, { useCallback, useState } from 'react';
import { Text } from 'react-native';
import { useFocusEffect } from '@react-navigation/native';
import { Avatar, Card, EmptyState, Header, Screen, ui } from '../../../components/ui';
import { chatApi, usersApi } from '../../../services/api';
import { useAppStore } from '../../../store/useAppStore';

function ConversationFolder({ navigation, folder, title }: any) {
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [items, setItems] = useState<any[]>([]);
  const [error, setError] = useState('');
  const load = useCallback(async () => {
    try {
      const { data } = await chatApi.conversations(folder);
      const enriched = await Promise.all(
        data.map(async (item) => {
          const personId = item.member_ids.find((id: string) => id !== currentUserId) || '';
          const person = personId ? (await usersApi.publicProfile(personId)).data : null;
          return { ...item, personId, name: person?.name || 'Conversation' };
        }),
      );
      setItems(enriched);
    } catch (reason: any) {
      setError(reason.message);
    }
  }, [currentUserId, folder]);
  useFocusEffect(
    useCallback(() => {
      void load();
    }, [load]),
  );
  return (
    <Screen>
      <Header title={title} onBack={() => navigation.goBack()} />
      {!!error && (
        <EmptyState
          title={`${title} unavailable`}
          text={error}
          action="Retry"
          onAction={() => void load()}
        />
      )}
      {items.map((item) => (
        <Card
          key={item.id}
          style={{ flexDirection: 'row', alignItems: 'center', gap: 12 }}
          onPress={() =>
            navigation.navigate('PrivateChat', {
              chatId: item.id,
              name: item.name,
              personId: item.personId,
            })
          }
        >
          <Avatar name={item.name} />
          <Text style={[ui.body, { flex: 1 }]}>
            {item.name}
            {'\n'}
            <Text style={ui.muted}>{item.last_message || 'Open conversation'}</Text>
          </Text>
        </Card>
      ))}
      {!error && !items.length && (
        <EmptyState
          title={`No ${title.toLowerCase()}`}
          text="Nothing is stored in this section yet."
        />
      )}
    </Screen>
  );
}

export function ArchivedChatsScreen(props: any) {
  return <ConversationFolder {...props} folder="archived" title="Archived chats" />;
}
export function PaidSessionsScreen(props: any) {
  return <ConversationFolder {...props} folder="paid" title="Paid sessions" />;
}
