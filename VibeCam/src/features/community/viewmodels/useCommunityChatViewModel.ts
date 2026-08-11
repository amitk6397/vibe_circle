import { useMemo } from 'react';
import { useAppStore } from '../../../store/useAppStore';
import { LocalAttachment } from '../../../types';

export function useCommunityChatViewModel(communityId: string) {
  const messages = useAppStore((state) => state.communityMessages);
  const communities = useAppStore((state) => state.communities);
  const joinedCommunities = useAppStore((state) => state.joinedCommunities);
  const blockedUsers = useAppStore((state) => state.blockedUsers);
  const people = useAppStore((state) => state.people);

  const community = communities.find((item) => item.id === communityId) ?? {
    id: communityId,
    name: 'Community unavailable',
    category: '',
    description: '',
    members: 0,
    color: '#6C63FF',
  };
  const visibleMessages = useMemo(
    () =>
      messages.filter(
        (message) =>
          message.communityId === communityId && !blockedUsers.includes(message.authorId),
      ),
    [blockedUsers, communityId, messages],
  );

  return {
    community,
    messages: visibleMessages,
    members: people.filter((person) => !blockedUsers.includes(person.id)),
    joined: joinedCommunities.includes(communityId),
    join: () => {
      if (!useAppStore.getState().joinedCommunities.includes(communityId)) {
        useAppStore.getState().toggleCommunity(communityId);
      }
    },
    sendMessage: (text: string, attachment?: LocalAttachment) =>
      useAppStore.getState().sendCommunityMessage(communityId, text, attachment),
  };
}
