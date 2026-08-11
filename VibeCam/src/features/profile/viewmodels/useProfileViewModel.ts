import { useAppStore } from '../../../store/useAppStore';

export function useProfileViewModel() {
  const profile = useAppStore((state) => state.profile);
  const blockedUsers = useAppStore((state) => state.blockedUsers);

  return {
    profile,
    blockedUsers,
    updateProfile: useAppStore.getState().updateProfile,
    blockUser: useAppStore.getState().blockUser,
    unblockUser: useAppStore.getState().unblockUser,
  };
}
