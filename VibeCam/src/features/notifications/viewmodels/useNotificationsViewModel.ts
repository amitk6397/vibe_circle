import { useAppStore } from '../../../store/useAppStore';

export function useNotificationsViewModel() {
  const unreadCount = useAppStore((state) => state.notifications);

  return {
    unreadCount,
    markAllRead: useAppStore.getState().markNotificationsRead,
  };
}
