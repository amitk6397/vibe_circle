import { useCallback, useEffect, useRef, useState } from 'react';
import { chatApi } from '../../../services/api';
import { realtimeService, RealtimeEvent } from '../../../services/realtimeSocket';
import { useAppStore } from '../../../store/useAppStore';
import { CommunityMessage } from '../../../types';

const mapMessage = (
  raw: any,
  communityId: string,
  currentUserId: string | null,
): CommunityMessage => ({
  id: raw.id,
  communityId,
  authorId: raw.author_id,
  author:
    raw.author_id === currentUserId
      ? useAppStore.getState().profile.name
      : useAppStore.getState().people.find((person) => person.id === raw.author_id)?.name ||
        'Member',
  text: raw.text || '',
  time: raw.created_at
    ? new Date(raw.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    : 'Now',
  mine: raw.author_id === currentUserId,
  role: 'member',
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

function merge(communityId: string, incoming: CommunityMessage[], clientId?: string) {
  useAppStore.setState((state) => {
    const other = state.communityMessages.filter((item) => item.communityId !== communityId);
    const current = state.communityMessages.filter(
      (item) => item.communityId === communityId && item.id !== clientId,
    );
    const byId = new Map(current.map((item) => [item.id, item]));
    incoming.forEach((item) => byId.set(item.id, item));
    return { communityMessages: [...other, ...byId.values()] };
  });
}

export function useCommunityRealtime(communityId: string, enabled: boolean) {
  const currentUserId = useAppStore((state) => state.currentUserId);
  const [loading, setLoading] = useState(enabled);
  const [error, setError] = useState<string | null>(null);
  const [connected, setConnected] = useState(false);
  const [typing, setTyping] = useState(false);
  const timer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const outgoingTimer = useRef<ReturnType<typeof setTimeout> | null>(null);
  const channel = realtimeService.communityChannel(communityId);

  const sync = useCallback(async () => {
    if (!enabled) return;
    setError(null);
    try {
      const { data } = await chatApi.communityMessages(communityId);
      merge(
        communityId,
        data.map((item) => mapMessage(item, communityId, currentUserId)),
      );
    } catch (requestError) {
      setError(
        requestError instanceof Error ? requestError.message : 'Could not sync community chat.',
      );
    } finally {
      setLoading(false);
    }
  }, [communityId, currentUserId, enabled]);

  useEffect(() => {
    if (!enabled) return;
    const unsubscribe = channel.subscribe((event: RealtimeEvent) => {
      if (event.event === 'connected') {
        setConnected(true);
        void sync();
      } else if (event.event === 'disconnected') setConnected(false);
      else if (event.event === 'typing' && event.user_id !== currentUserId) {
        setTyping(Boolean(event.typing));
        if (timer.current) clearTimeout(timer.current);
        timer.current = setTimeout(() => setTyping(false), 4000);
      } else if (event.event === 'message') {
        merge(
          communityId,
          [mapMessage(event.message, communityId, currentUserId)],
          event.client_id,
        );
      } else if (event.event === 'error') setError(event.message || 'Realtime error.');
    });
    void channel.connect();
    void sync();
    return () => {
      unsubscribe();
      channel.send({ event: 'typing', typing: false });
      channel.close();
      if (timer.current) clearTimeout(timer.current);
      if (outgoingTimer.current) clearTimeout(outgoingTimer.current);
    };
  }, [channel, communityId, currentUserId, enabled, sync]);

  return {
    loading,
    error,
    connected,
    typing,
    retry: sync,
    sendTyping: (value: boolean) => {
      if (outgoingTimer.current) clearTimeout(outgoingTimer.current);
      channel.send({ event: 'typing', typing: value });
      if (value)
        outgoingTimer.current = setTimeout(
          () => channel.send({ event: 'typing', typing: false }),
          1600,
        );
    },
  };
}
