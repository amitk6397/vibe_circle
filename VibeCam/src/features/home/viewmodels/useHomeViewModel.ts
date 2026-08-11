import { PURPOSES } from '../../../constants/data';
import { useAppStore } from '../../../store/useAppStore';

export function useHomeViewModel() {
  const profile = useAppStore((state) => state.profile);
  const selectedPurpose = useAppStore((state) => state.selectedPurpose);
  const chats = useAppStore((state) => state.chats);
  const posts = useAppStore((state) => state.posts);

  return {
    profile,
    selectedPurpose,
    chats,
    posts,
    purposes: PURPOSES,
  };
}
