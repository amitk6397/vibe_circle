import { useAppStore } from '../../../store/useAppStore';

export function useCommunityViewModel() {
  const posts = useAppStore((state) => state.posts);
  const joinedCommunities = useAppStore((state) => state.joinedCommunities);

  return {
    posts,
    joinedCommunities,
    createPost: useAppStore.getState().createPost,
    toggleCommunity: useAppStore.getState().toggleCommunity,
    toggleLike: useAppStore.getState().toggleLike,
    toggleSave: useAppStore.getState().toggleSave,
  };
}
