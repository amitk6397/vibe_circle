import { Platform } from 'react-native';

const fallbackHost = Platform.OS === 'android' ? '10.0.2.2' : '127.0.0.1';

export const environment = {
  apiUrl: process.env.EXPO_PUBLIC_API_URL || `http://${fallbackHost}:8000/api/v1`,
  dummyPayments: process.env.EXPO_PUBLIC_DUMMY_PAYMENTS === 'true',
};
