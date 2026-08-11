import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Device from 'expo-device';
import * as Notifications from 'expo-notifications';
import { Platform } from 'react-native';
import { navigateFromPush } from '../navigation/navigationRef';
import { notificationsApi } from './api';

const PUSH_TOKEN_KEY = 'vibecircle.native_push_token';

Notifications.setNotificationHandler({
  handleNotification: async () => ({
    shouldPlaySound: true,
    shouldSetBadge: true,
    shouldShowBanner: true,
    shouldShowList: true,
  }),
});

async function configureChannels() {
  if (Platform.OS !== 'android') return;
  await Promise.all([
    Notifications.setNotificationChannelAsync('default', {
      name: 'VibeCircle updates',
      importance: Notifications.AndroidImportance.HIGH,
      vibrationPattern: [0, 250, 150, 250],
      lightColor: '#6C63FF',
      sound: 'default',
    }),
    Notifications.setNotificationChannelAsync('calls', {
      name: 'Incoming calls',
      importance: Notifications.AndroidImportance.MAX,
      vibrationPattern: [0, 500, 250, 500, 250, 500],
      lightColor: '#6C63FF',
      sound: 'default',
      lockscreenVisibility: Notifications.AndroidNotificationVisibility.PUBLIC,
    }),
  ]);
}

export async function registerForPushNotifications() {
  // The supplied Firebase configuration is Android-only. iOS requires APNs/FCM
  // credentials and a native Firebase Messaging token before it can be enabled safely.
  if (!Device.isDevice || Platform.OS !== 'android') return null;
  await configureChannels();
  let permissions = await Notifications.getPermissionsAsync();
  if (permissions.status !== 'granted') permissions = await Notifications.requestPermissionsAsync();
  if (permissions.status !== 'granted') return null;
  const token = String((await Notifications.getDevicePushTokenAsync()).data);
  await notificationsApi.registerDevice(token, Platform.OS as 'android' | 'ios');
  await AsyncStorage.setItem(PUSH_TOKEN_KEY, token);
  return token;
}

export async function unregisterPushNotifications() {
  const token = await AsyncStorage.getItem(PUSH_TOKEN_KEY);
  if (!token) return;
  try {
    await notificationsApi.unregisterDevice(token);
  } finally {
    await AsyncStorage.removeItem(PUSH_TOKEN_KEY);
  }
}

export function listenForPushNotifications(onReceive: () => void) {
  const received = Notifications.addNotificationReceivedListener(() => onReceive());
  const responded = Notifications.addNotificationResponseReceivedListener((response) => {
    navigateFromPush(response.notification.request.content.data);
  });
  void Notifications.getLastNotificationResponseAsync().then((response) => {
    if (response) navigateFromPush(response.notification.request.content.data);
  });
  return () => {
    received.remove();
    responded.remove();
  };
}
