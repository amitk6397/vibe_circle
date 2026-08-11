import React, { useEffect, useState } from 'react';
import { StyleSheet, View } from 'react-native';
import { NavigationContainer, DefaultTheme } from '@react-navigation/native';
import { createNativeStackNavigator } from '@react-navigation/native-stack';
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { RootStackParamList, TabParamList } from '../types';
import { colors } from '../theme';
import { useAppStore } from '../store/useAppStore';
import { chatApi } from '../services/api';
import { flushPendingPushNavigation, navigationRef } from './navigationRef';
import {
  BasicProfileScreen,
  ForgotPasswordScreen,
  LoginScreen,
  RegisterScreen,
  SplashScreen,
  VerifyEmailScreen,
} from '../features/auth';
import { ChoosePurposeScreen, HomeScreen } from '../features/home';
import {
  DiscoverCommunitiesScreen,
  DiscoverPeopleScreen,
  DiscoverScreen,
  GlobalSearchScreen,
  PublicProfileScreen,
  RecommendedPeopleScreen,
  SearchFiltersScreen,
} from '../features/discovery';
import {
  ConnectScreen,
  ConnectSetupScreen,
  ConnectionRequestScreen,
  MatchFoundScreen,
  SearchingMatchScreen,
  SessionFeedbackScreen,
} from '../features/matching';
import { LiveStreamScreen, GoLiveScreen, WatchStreamScreen } from '../features/livestream';
import {
  AudioCallScreen,
  ChatInfoScreen,
  InboxScreen,
  IncomingCallScreen,
  MediaPreviewScreen,
  PrivateChatScreen,
  VideoCallScreen,
  MessageRequestsScreen,
  NewMessageRequestScreen,
  ArchivedChatsScreen,
  PaidSessionsScreen,
} from '../features/chat';
import {
  ActiveSubscriptionScreen,
  PaymentFailureScreen,
  PaymentSuccessScreen,
  PlanDetailsScreen,
  PurchaseConfirmationScreen,
  SubscriptionHistoryScreen,
  SubscriptionPlansScreen,
} from '../features/subscription';
import { BuyCoinsScreen, TransactionHistoryScreen, WalletScreen } from '../features/commerce';
import { UserPerformanceScreen, SessionRatingScreen, WithdrawalScreen } from '../features/creator';
import {
  CommunityChatScreen,
  CommunityDetailsScreen,
  CommunityFeedScreen,
  CommunityMembersScreen,
  CommunityJoinRequestsScreen,
  CreateCommunityScreen,
  CreateCircleScreen,
  CircleInvitesScreen,
  InviteCircleMembersScreen,
  CreatePostScreen,
  PostDetailsScreen,
} from '../features/community';
import { NotificationsScreen } from '../features/notifications';
import {
  AccountManagementScreen,
  BlockedUsersScreen,
  ConnectionsScreen,
  EditProfileScreen,
  InterestsLanguagesScreen,
  MyActivityScreen,
  MyCommunitiesScreen,
  PrivateCirclesScreen,
  MyCreationsScreen,
  MyProfileScreen,
  ProfileScreen,
  ReportsScreen,
  SettingsSupportScreen,
  SupportArticleScreen,
  DailyRewardsScreen,
  ReferralScreen,
} from '../features/profile';

const Stack = createNativeStackNavigator<RootStackParamList>();
const Tabs = createBottomTabNavigator<TabParamList>();

function MainTabs() {
  const darkMode = useAppStore((state) => state.darkMode);
  const insets = useSafeAreaInsets();
  const [unreadChatCount, setUnreadChatCount] = useState(0);

  useEffect(() => {
    const fetchUnread = () => {
      chatApi.conversations()
        .then(({ data }) => {
          const total = data.reduce((sum: number, item: any) => sum + Number(item.unread_count || 0), 0);
          setUnreadChatCount(total);
        })
        .catch(() => {});
    };
    fetchUnread();
    const interval = setInterval(fetchUnread, 10000);
    return () => clearInterval(interval);
  }, []);

  const icons: Record<keyof TabParamList, string> = {
    Home: 'home',
    Discover: 'compass',
    Live: 'radio',
    Inbox: 'chatbubbles',
    Profile: 'person',
  };
  return (
    <Tabs.Navigator
      screenOptions={({ route }) => ({
        headerShown: false,
        tabBarActiveTintColor: colors.primary,
        tabBarInactiveTintColor: colors.muted,
        tabBarLabelStyle: styles.tabLabel,
        tabBarStyle: [
          styles.tabBar,
          { height: 64 + insets.bottom, paddingBottom: Math.max(insets.bottom, 8) },
          darkMode && { backgroundColor: '#15192B', borderTopColor: '#2B304A' },
        ],
        tabBarIcon: ({ color, focused }) =>
          route.name === 'Live' ? (
            <View style={styles.connectTab}>
              <Ionicons name="radio" size={26} color="#fff" />
            </View>
          ) : (
            <Ionicons
              name={(focused ? icons[route.name] : `${icons[route.name]}-outline`) as any}
              size={22}
              color={color}
            />
          ),
      })}
    >
      <Tabs.Screen name="Home" component={HomeScreen} />
      <Tabs.Screen name="Discover" component={DiscoverScreen} />
      <Tabs.Screen name="Live" component={LiveStreamScreen} />
      <Tabs.Screen 
        name="Inbox" 
        component={InboxScreen} 
        options={{
          tabBarBadge: unreadChatCount > 0 ? unreadChatCount : undefined,
          tabBarBadgeStyle: { backgroundColor: '#FF3040', color: '#fff', fontSize: 10 }
        }}
      />
      <Tabs.Screen name="Profile" component={ProfileScreen} />
    </Tabs.Navigator>
  );
}

const screens: [keyof RootStackParamList, React.ComponentType<any>][] = [
  ['Splash', SplashScreen],
  ['Login', LoginScreen],
  ['Register', RegisterScreen],
  ['VerifyEmail', VerifyEmailScreen],
  ['ForgotPassword', ForgotPasswordScreen],
  ['BasicProfile', BasicProfileScreen],
  ['Main', MainTabs],
  ['ChoosePurpose', ChoosePurposeScreen],
  ['GlobalSearch', GlobalSearchScreen],
  ['DiscoverPeople', DiscoverPeopleScreen],
  ['DiscoverCommunities', DiscoverCommunitiesScreen],
  ['RecommendedPeople', RecommendedPeopleScreen],
  ['PublicProfile', PublicProfileScreen],
  ['SearchFilters', SearchFiltersScreen],
  ['ConnectSetup', ConnectSetupScreen],
  ['SearchingMatch', SearchingMatchScreen],
  ['MatchFound', MatchFoundScreen],
  ['ConnectionRequest', ConnectionRequestScreen],
  ['MessageRequests', MessageRequestsScreen],
  ['NewMessageRequest', NewMessageRequestScreen],
  ['PaidSessions', PaidSessionsScreen],
  ['ArchivedChats', ArchivedChatsScreen],
  ['SubscriptionPlans', SubscriptionPlansScreen],
  ['PlanDetails', PlanDetailsScreen],
  ['ActiveSubscription', ActiveSubscriptionScreen],
  ['PurchaseConfirmation', PurchaseConfirmationScreen],
  ['PaymentSuccess', PaymentSuccessScreen],
  ['PaymentFailure', PaymentFailureScreen],
  ['SubscriptionHistory', SubscriptionHistoryScreen],
  ['Wallet', WalletScreen],
  ['BuyCoins', BuyCoinsScreen],
  ['TransactionHistory', TransactionHistoryScreen],
  ['UserPerformance', UserPerformanceScreen],
  ['EarningsDashboard', WalletScreen],
  ['EarningsWallet', WalletScreen],
  ['Withdrawal', WithdrawalScreen],
  ['SessionRating', SessionRatingScreen],
  ['SessionFeedback', SessionFeedbackScreen],
  ['PrivateChat', PrivateChatScreen],
  ['MediaPreview', MediaPreviewScreen],
  ['ChatInfo', ChatInfoScreen],
  ['AudioCall', AudioCallScreen],
  ['VideoCall', VideoCallScreen],
  ['IncomingCall', IncomingCallScreen],
  ['CommunityFeed', CommunityFeedScreen],
  ['CreatePost', CreatePostScreen],
  ['PostDetails', PostDetailsScreen],
  ['CommunityDetails', CommunityDetailsScreen],
  ['CommunityChat', CommunityChatScreen],
  ['CommunityMembers', CommunityMembersScreen],
  ['CommunityJoinRequests', CommunityJoinRequestsScreen],
  ['CreateCommunity', CreateCommunityScreen],
  ['CreateCircle', CreateCircleScreen],
  ['CircleInvites', CircleInvitesScreen],
  ['InviteCircleMembers', InviteCircleMembersScreen],
  ['Notifications', NotificationsScreen],
  ['MyProfile', MyProfileScreen],
  ['EditProfile', EditProfileScreen],
  ['InterestsLanguages', InterestsLanguagesScreen],
  ['MyActivity', MyActivityScreen],
  ['MyCommunities', MyCommunitiesScreen],
  ['PrivateCircles', PrivateCirclesScreen],
  ['MyCreations', MyCreationsScreen],
  ['Connections', ConnectionsScreen],
  ['Reports', ReportsScreen],
  ['BlockedUsers', BlockedUsersScreen],
  ['SettingsSupport', SettingsSupportScreen],
  ['SupportArticle', SupportArticleScreen],
  ['AccountManagement', AccountManagementScreen],
  ['DailyRewards', DailyRewardsScreen],
  ['Referral', ReferralScreen],
  ['GoLive', GoLiveScreen],
  ['WatchStream', WatchStreamScreen],
  ['Connect', ConnectScreen],
];

export function AppNavigator() {
  const darkMode = useAppStore((state) => state.darkMode);
  const navigationColors = darkMode
    ? { background: colors.bg, card: colors.surface, text: colors.text, border: colors.border }
    : { background: colors.bg, card: colors.surface, text: colors.text, border: colors.border };
  return (
    <NavigationContainer
      ref={navigationRef}
      onReady={flushPendingPushNavigation}
      theme={{
        ...DefaultTheme,
        colors: {
          ...DefaultTheme.colors,
          ...navigationColors,
          primary: colors.primary,
        },
      }}
    >
      <Stack.Navigator
        initialRouteName="Splash"
        screenOptions={{
          headerShown: false,
          animation: 'slide_from_right',
          contentStyle: { backgroundColor: navigationColors.background },
        }}
      >
        {screens.map(([name, component]) => (
          <Stack.Screen
            key={name}
            name={name as any}
            component={component}
            options={name === 'SearchingMatch' ? { animation: 'fade' } : undefined}
          />
        ))}
      </Stack.Navigator>
    </NavigationContainer>
  );
}

const styles = StyleSheet.create({
  tabBar: {
    height: 74,
    paddingTop: 8,
    paddingBottom: 9,
    backgroundColor: colors.surface,
    borderTopColor: colors.border,
  },
  tabLabel: { fontSize: 10, fontWeight: '700' },
  connectTab: {
    width: 52,
    height: 52,
    borderRadius: 19,
    backgroundColor: colors.primary,
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: -18,
    borderWidth: 4,
    borderColor: colors.bg,
  },
});
