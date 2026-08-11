import 'react-native-gesture-handler';
import { StatusBar } from 'expo-status-bar';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import { SafeAreaProvider } from 'react-native-safe-area-context';
import { AppNavigator } from './src/navigation/AppNavigator';
import { useEffect } from 'react';
import { useAppStore } from './src/store/useAppStore';
import { AppErrorBoundary } from './src/components/AppErrorBoundary';
import {
  listenForPushNotifications,
  registerForPushNotifications,
} from './src/services/pushNotifications';

export default function App() {
  const bootstrap = useAppStore((state) => state.bootstrap);
  const darkMode = useAppStore((state) => state.darkMode);
  const currentUserId = useAppStore((state) => state.currentUserId);
  useEffect(() => {
    void bootstrap();
  }, [bootstrap]);
  useEffect(() => {
    if (!currentUserId) return;
    void registerForPushNotifications().catch(() => undefined);
    return listenForPushNotifications(() =>
      useAppStore.setState((state) => ({ notifications: state.notifications + 1 })),
    );
  }, [currentUserId]);
  return (
    <AppErrorBoundary>
      <GestureHandlerRootView style={{ flex: 1 }}>
        <SafeAreaProvider>
          <StatusBar style={darkMode ? 'light' : 'dark'} />
          <AppNavigator />
        </SafeAreaProvider>
      </GestureHandlerRootView>
    </AppErrorBoundary>
  );
}
