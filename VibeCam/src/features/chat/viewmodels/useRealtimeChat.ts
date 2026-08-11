import { useCallback, useEffect, useRef, useState } from 'react';
import { chatApi, usersApi } from '../../../services/api';
import { realtimeService, RealtimeEvent } from '../../../services/realtimeSocket';
import { useAppStore } from '../../../store/useAppStore';
import { Chat, Message } from '../../../types';

const timeLabel = (value?: string) => {
  if (!value) return 'Now';
  try {
    let dateStr = value;
    if (!dateStr.endsWith('Z') && !dateStr.includes('+')) {
      const parts = dateStr.split(' ');
      if (parts.length === 2 && !parts[1].includes('+') && !parts[1].includes('-')) {
        dateStr = `${dateStr.replace(' ', 'T')}Z`;
      } else if (dateStr.includes('T')) {
        dateStr = `${dateStr}Z`;
      } else {
        dateStr = `${dateStr}T00:00:00Z`;
      }
    }
    const date = new Date(dateStr);
    if (isNaN(date.getTime())) {
      return new Date(value).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
    }
    return date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' });
  } catch {
    return 'Now';
  }
};

const mapMessage = (raw: any, chatId: string, currentUserId: string | null): Message => ({
  id: raw.id,
  chatId,
  text: raw.text || '',
  mine: raw.sender_id === currentUserId,
  time: timeLabel(raw.created_at),
  status: raw.read_at ? 'read' : raw.delivered_at ? 'delivered' : 'sent',
  replyToId: raw.reply_to_id || undefined,
  reactions: raw.reactions || {},
  deleted: Boolean(raw.is_deleted),
  safetyFlags: raw.safety_flags || [],
  attachment: raw.media_url
    ? {
        id: raw.id,
        kind: raw.mime_type?.startsWith('image/') ? 'image' : 'file',
        uri: raw.media_url,
        name: raw.media_name || 'Attachment',
        mimeType: raw.mime_type,
      }
    : undefined,
});

function mergeMessages(chatId: string, incoming: Message[], clientId?: string) {
  useAppStore.setState((state) => {
    const other = state.messages.filter((item) => item.chatId !== chatId);
    const current = state.messages.filter((item) => item.chatId === chatId && item.id !== clientId);
    const byId = new Map(current.map((item) => [item.id, item]));
    incoming.forEach((item) => byId.set(item.id, item));
    return { messages: [...other, ...byId.values()] };
  });
}

export function useInboxSync() {
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const refresh = useCallback(async () => {
    if (!currentUserId) return;
    setLoading(true);
    setError(null);
    try {
      const { data } = await chatApi.conversations();
      const chats = await Promise.all(
        data.map(async (item): Promise<Chat> => {
          const personId = item.member_ids.find((id: string) => id !== currentUserId) || '';
          const profile = personId
            ? await usersApi.publicProfile(personId).then((x) => x.data)
            : null;
          return {
            id: item.id,
            personId,
            name:
              item.type === 'match_anonymous'
                ? 'Anonymous Connect'
                : profile?.name || 'VibeCircle member',
            preview: item.last_message || 'Start a conversation',
            time: timeLabel(item.updated_at),
            unread: item.unread_count || 0,
            online: profile?.is_online,
            avatarUrl: profile?.avatar_url,
          };
        }),
      );
      useAppStore.setState({ chats });
    } catch (requestError) {
      setError(
        requestError instanceof Error ? requestError.message : 'Could not load conversations.',
      );
    } finally {
      setLoading(false);
    }
  }, [currentUserId]);
  useEffect(() => {
    void refresh();
  }, [refresh]);
  return { loading, error, refresh };
}

export function usePrivateRealtime(chatId: string) {
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [connected, setConnected] = useState(false);
  const [typing, setTyping] = useState(false);
  const [online, setOnline] = useState(false);
  const [loadingOlder, setLoadingOlder] = useState(false);
  const typingTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const outgoingTypingTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const channel = realtimeService.privateChannel(chatId);

  const sync = useCallback(async () => {
    setError(null);
    try {
      const { data } = await chatApi.messages(chatId);
      const older = data.map((item) => mapMessage(item, chatId, currentUserId));
      useAppStore.setState((state) => {
        const existingIds = new Set(state.messages.map((item) => item.id));
        const updatedChats = state.chats.map((c) =>
          c.id === chatId ? { ...c, unread: 0 } : c
        );
        return {
          messages: [...older.filter((item) => !existingIds.has(item.id)), ...state.messages],
          chats: updatedChats,
        };
      });
      await chatApi.markRead(chatId);
      channel.send({ event: 'read' });
    } catch (requestError) {
      setError(requestError instanceof Error ? requestError.message : 'Could not sync messages.');
    } finally {
      setLoading(false);
    }
  }, [channel, chatId, currentUserId]);

  useEffect(() => {
    const unsubscribe = channel.subscribe((event: RealtimeEvent) => {
      if (event.event === 'connected') {
        setConnected(true);
        void sync();
      } else if (event.event === 'disconnected') setConnected(false);
      else if (event.event === 'typing' && event.user_id !== currentUserId) {
        setTyping(Boolean(event.typing));
        if (typingTimer.current) clearTimeout(typingTimer.current);
        typingTimer.current = setTimeout(() => setTyping(false), 4000);
      } else if (event.event === 'presence' && event.user_id !== currentUserId) {
        setOnline(Boolean(event.online));
      } else if (event.event === 'message') {
        const message = mapMessage(event.message, chatId, currentUserId);
        mergeMessages(chatId, [message], event.client_id);
        if (!message.mine) channel.send({ event: 'read' });
      } else if (event.event === 'read') {
        useAppStore.setState((state) => ({
          messages: state.messages.map((item) =>
            event.message_ids?.includes(item.id) ? { ...item, status: 'read' } : item,
          ),
        }));
      } else if (event.event === 'error') setError(event.message || 'Realtime error.');
    });
    void channel.connect();
    void sync();
    return () => {
      unsubscribe();
      channel.send({ event: 'typing', typing: false });
      channel.close();
      if (typingTimer.current) clearTimeout(typingTimer.current);
      if (outgoingTypingTimer.current) clearTimeout(outgoingTypingTimer.current);
    };
  }, [channel, chatId, currentUserId, sync]);

  const sendTyping = (value: boolean) => {
    if (outgoingTypingTimer.current) clearTimeout(outgoingTypingTimer.current);
    channel.send({ event: 'typing', typing: value });
    if (value)
      outgoingTypingTimer.current = setTimeout(
        () => channel.send({ event: 'typing', typing: false }),
        1600,
      );
  };
  const loadOlder = async () => {
    const first = useAppStore.getState().messages.find((item) => item.chatId === chatId);
    if (!first || loadingOlder) return;
    setLoadingOlder(true);
    try {
      const { data } = await chatApi.messages(chatId, 30, first.id);
      mergeMessages(
        chatId,
        data.map((item) => mapMessage(item, chatId, currentUserId)),
      );
    } finally {
      setLoadingOlder(false);
    }
  };
  return {
    loading,
    loadingOlder,
    error,
    connected,
    typing,
    online,
    retry: sync,
    loadOlder,
    sendTyping,
  };
}
