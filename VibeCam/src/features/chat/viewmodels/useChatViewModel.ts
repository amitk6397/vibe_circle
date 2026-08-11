import { useMemo } from 'react';
import { useAppStore } from '../../../store/useAppStore';

export function useChatViewModel(chatId: string) {
  const chats = useAppStore((state) => state.chats);
  const allMessages = useAppStore((state) => state.messages);
  const messages = useMemo(
    () => allMessages.filter((message) => message.chatId === chatId),
    [allMessages, chatId],
  );

  return {
    chat: chats.find((item) => item.id === chatId),
    messages,
    sendMessage: (text: string) => useAppStore.getState().sendMessage(chatId, text),
  };
}
