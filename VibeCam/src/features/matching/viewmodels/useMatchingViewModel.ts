import { useAppStore } from '../../../store/useAppStore';

export function useMatchingViewModel() {
  const purpose = useAppStore((state) => state.selectedPurpose);
  const anonymous = useAppStore((state) => state.anonymousMode);

  return {
    purpose,
    anonymous,
    selectPurpose: useAppStore.getState().selectPurpose,
    setAnonymous: useAppStore.getState().setAnonymousMode,
  };
}
