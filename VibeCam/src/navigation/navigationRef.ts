import { createNavigationContainerRef } from '@react-navigation/native';
import { RootStackParamList } from '../types';

export const navigationRef = createNavigationContainerRef<RootStackParamList>();

let pendingNavigation: { screen: keyof RootStackParamList; params?: object } | null = null;

export function navigateFromPush(data: Record<string, unknown>) {
  let screen = data.screen as keyof RootStackParamList | undefined;
  if (!screen) {
    const type = String(data.type || '');
    if (type === 'incoming_call') screen = 'IncomingCall';
    else if (type === 'message') screen = 'PrivateChat';
    else if (type.startsWith('follow_')) screen = 'ConnectionRequest';
    else if (type.startsWith('community_') || type === 'circle_invite') screen = 'Notifications';
    else if (type.startsWith('post_')) screen = 'PostDetails';
    else screen = 'Notifications';
  }
  const allowed = new Set<keyof RootStackParamList>([
    'IncomingCall',
    'PrivateChat',
    'ConnectionRequest',
    'PublicProfile',
    'PostDetails',
    'CommunityDetails',
    'Notifications',
    'Main',
  ]);
  if (!allowed.has(screen)) screen = 'Notifications';
  const params = { ...data } as object;
  if (!navigationRef.isReady()) {
    pendingNavigation = { screen, params };
    return;
  }
  (navigationRef.navigate as any)(screen, params);
}

export function flushPendingPushNavigation() {
  if (!pendingNavigation || !navigationRef.isReady()) return;
  const { screen, params } = pendingNavigation;
  pendingNavigation = null;
  (navigationRef.navigate as any)(screen, params);
}
