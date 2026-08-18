import 'package:get/get.dart';
import '../features/auth/views/splash_view.dart';
import '../features/auth/views/login_view.dart';
import '../features/auth/views/register_view.dart';
import '../features/auth/views/verify_email_view.dart';
import '../features/auth/views/forgot_password_view.dart';
import '../features/auth/views/basic_profile_view.dart';
import '../features/home/views/main_tabs_view.dart';
import '../features/home/views/choose_purpose_view.dart';
import '../features/discovery/views/search_filters_view.dart';
import '../features/discovery/views/recommended_people_view.dart';
import '../features/discovery/views/public_profile_view.dart';
import '../features/discovery/views/global_search_view.dart';
import '../features/discovery/views/discover_people_view.dart';
import '../features/discovery/views/discover_communities_view.dart';
import '../features/chat/views/private_chat_view.dart';
import '../features/chat/views/message_requests_view.dart';
import '../features/chat/views/new_message_request_view.dart';
import '../features/chat/views/archived_chats_view.dart';
import '../features/chat/views/paid_sessions_view.dart';
import '../features/matching/views/connection_request_view.dart';
import '../features/matching/views/connect_view.dart';
import '../features/matching/views/connect_setup_view.dart';
import '../features/matching/views/searching_match_view.dart';
import '../features/matching/views/match_found_view.dart';
import '../features/matching/views/session_feedback_view.dart';
import '../features/profile/views/connections_view.dart';
import '../features/profile/views/daily_rewards_view.dart';
import '../features/profile/views/referral_view.dart';
import '../features/profile/views/interests_languages_view.dart';
import '../features/profile/views/my_activity_view.dart';
import '../features/profile/views/my_communities_view.dart';
import '../features/profile/views/private_circles_view.dart';
import '../features/profile/views/my_creations_view.dart';
import '../features/profile/views/reports_view.dart';
import '../features/profile/views/account_management_view.dart';
import '../features/profile/views/support_article_view.dart';
import '../features/notifications/views/notifications_view.dart';
import '../features/subscription/views/subscription_plans_view.dart';
import '../features/subscription/views/plan_details_view.dart';
import '../features/subscription/views/active_subscription_view.dart';
import '../features/subscription/views/purchase_confirmation_view.dart';
import '../features/subscription/views/payment_result_view.dart';
import '../features/subscription/views/subscription_history_view.dart';
import '../features/community/views/community_feed_view.dart';
import '../features/community/views/create_post_view.dart';
import '../features/community/views/post_details_view.dart';
import '../features/community/views/community_details_view.dart';
import '../features/community/views/community_chat_view.dart';
import '../features/community/views/community_members_view.dart';
import '../features/community/views/community_join_requests_view.dart';
import '../features/community/views/create_community_view.dart';
import '../features/community/views/create_circle_view.dart';
import '../features/community/views/circle_invites_view.dart';
import '../features/profile/views/my_profile_view.dart';
import '../features/profile/views/edit_profile_view.dart';
import '../features/profile/views/blocked_users_view.dart';
import '../features/profile/views/settings_support_view.dart';
import '../features/wallet/views/wallet_view.dart';
import '../features/wallet/views/buy_coins_view.dart';
import '../features/wallet/views/transaction_history_view.dart';
import '../features/livestream/views/go_live_view.dart';
import '../features/livestream/views/watch_stream_view.dart';
import '../features/livestream/views/user_performance_view.dart';
import '../features/livestream/views/withdrawal_view.dart';
import 'app_routes.dart';

import '../bindings/auth_binding.dart';
import '../bindings/discovery_binding.dart';
import '../bindings/chat_binding.dart';
import '../bindings/community_binding.dart';
import '../bindings/home_binding.dart';
import '../bindings/wallet_binding.dart';
import '../bindings/profile_binding.dart';
import '../bindings/notifications_binding.dart';

import '../features/chat/views/chat_info_view.dart';
import '../features/chat/views/media_preview_view.dart';
import '../features/chat/views/incoming_call_view.dart';
import '../features/chat/views/audio_call_view.dart';
import '../features/chat/views/video_call_view.dart';
import '../features/community/views/invite_circle_members_view.dart';

class AppPages {
  AppPages._();

  static const INITIAL = AppRoutes.SPLASH;

  static final routes = [
    GetPage(
      name: AppRoutes.SPLASH,
      page: () => const SplashView(),
      binding: AuthBinding(),
      transition: Transition.fadeIn,
    ),
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.REGISTER,
      page: () => const RegisterView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.VERIFY_EMAIL,
      page: () => const VerifyEmailView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.FORGOT_PASSWORD,
      page: () => const ForgotPasswordView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: AppRoutes.BASIC_PROFILE,
      page: () => const BasicProfileView(),
      binding: AuthBinding(),
      transition: Transition.rightToLeft,
    ),

    // App Main & Discovery routes
    GetPage(
      name: AppRoutes.MAIN,
      page: () => const MainTabsView(),
      bindings: [
        HomeBinding(),
        AuthBinding(),
        DiscoveryBinding(),
        ChatBinding(),
        CommunityBinding(),
        WalletBinding(),
        ProfileBinding(),
        NotificationsBinding(),
      ],
    ),
    GetPage(
      name: AppRoutes.CHOOSE_PURPOSE,
      page: () => const ChoosePurposeView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.GLOBAL_SEARCH,
      page: () => const GlobalSearchView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.DISCOVER_PEOPLE,
      page: () => const DiscoverPeopleView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.DISCOVER_COMMUNITIES,
      page: () => const DiscoverCommunitiesView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.RECOMMENDED_PEOPLE,
      page: () => const RecommendedPeopleView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.PUBLIC_PROFILE,
      page: () => const PublicProfileView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.SEARCH_FILTERS,
      page: () => const SearchFiltersView(),
      binding: DiscoveryBinding(),
    ),

    // Matching routes
    GetPage(
      name: AppRoutes.CONNECT_SETUP,
      page: () => const ConnectSetupView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.SEARCHING_MATCH,
      page: () => const SearchingMatchView(),
      binding: DiscoveryBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.MATCH_FOUND,
      page: () => const MatchFoundView(),
      binding: DiscoveryBinding(),
      transition: Transition.fade,
    ),
    GetPage(
      name: AppRoutes.CONNECTION_REQUEST,
      page: () => const ConnectionRequestView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.SESSION_FEEDBACK,
      page: () => const SessionFeedbackView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.SESSION_RATING,
      page: () => const SessionFeedbackView(),
      binding: DiscoveryBinding(),
    ),

    // Chat routes
    GetPage(
      name: AppRoutes.PRIVATE_CHAT,
      page: () => const PrivateChatView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.MEDIA_PREVIEW,
      page: () => const MediaPreviewView(),
    ),
    GetPage(name: AppRoutes.CHAT_INFO, page: () => const ChatInfoView()),
    GetPage(
      name: AppRoutes.MESSAGE_REQUESTS,
      page: () => const MessageRequestsView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.NEW_MESSAGE_REQUEST,
      page: () => const NewMessageRequestView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.PAID_SESSIONS,
      page: () => const PaidSessionsView(),
      binding: ChatBinding(),
    ),
    GetPage(
      name: AppRoutes.ARCHIVED_CHATS,
      page: () => const ArchivedChatsView(),
      binding: ChatBinding(),
    ),

    // Calls routes
    GetPage(name: AppRoutes.AUDIO_CALL, page: () => const AudioCallView()),
    GetPage(name: AppRoutes.VIDEO_CALL, page: () => const VideoCallView()),
    GetPage(
      name: AppRoutes.INCOMING_CALL,
      page: () => const IncomingCallView(),
    ),

    // Community routes
    GetPage(
      name: AppRoutes.COMMUNITY_FEED,
      page: () => const CommunityFeedView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.CREATE_POST,
      page: () => const CreatePostView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.POST_DETAILS,
      page: () => const PostDetailsView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.COMMUNITY_DETAILS,
      page: () => const CommunityDetailsView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.COMMUNITY_CHAT,
      page: () => const CommunityChatView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.COMMUNITY_MEMBERS,
      page: () => const CommunityMembersView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.COMMUNITY_JOIN_REQUESTS,
      page: () => const CommunityJoinRequestsView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.CREATE_COMMUNITY,
      page: () => const CreateCommunityView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.CREATE_CIRCLE,
      page: () => const CreateCircleView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.CIRCLE_INVITES,
      page: () => const CircleInvitesView(),
      binding: CommunityBinding(),
    ),
    GetPage(
      name: AppRoutes.INVITE_CIRCLE_MEMBERS,
      page: () => const InviteCircleMembersView(),
      binding: CommunityBinding(),
    ),

    // Subscriptions routes
    GetPage(
      name: AppRoutes.SUBSCRIPTION_PLANS,
      page: () => const SubscriptionPlansView(),
      binding: WalletBinding(),
    ),
    GetPage(name: AppRoutes.PLAN_DETAILS, page: () => const PlanDetailsView()),
    GetPage(
      name: AppRoutes.ACTIVE_SUBSCRIPTION,
      page: () => const ActiveSubscriptionView(),
    ),
    GetPage(
      name: AppRoutes.PURCHASE_CONFIRMATION,
      page: () => const PurchaseConfirmationView(),
    ),
    GetPage(
      name: AppRoutes.PAYMENT_SUCCESS,
      page: () => const PaymentSuccessView(),
    ),
    GetPage(
      name: AppRoutes.PAYMENT_FAILURE,
      page: () => const PaymentFailureView(),
    ),
    GetPage(
      name: AppRoutes.SUBSCRIPTION_HISTORY,
      page: () => const SubscriptionHistoryView(),
    ),

    // Wallet routes
    GetPage(
      name: AppRoutes.WALLET,
      page: () => const WalletView(),
      binding: WalletBinding(),
    ),
    GetPage(name: AppRoutes.BUY_COINS, page: () => const BuyCoinsView()),
    GetPage(
      name: AppRoutes.TRANSACTION_HISTORY,
      page: () => const TransactionHistoryView(),
    ),

    // Creator & Livestream routes
    GetPage(
      name: AppRoutes.USER_PERFORMANCE,
      page: () => const UserPerformanceView(),
    ),
    GetPage(name: AppRoutes.WITHDRAWAL, page: () => const WithdrawalView()),
    GetPage(name: AppRoutes.GO_LIVE, page: () => const GoLiveView()),
    GetPage(name: AppRoutes.WATCH_STREAM, page: () => const WatchStreamView()),

    // Profile settings routes
    GetPage(
      name: AppRoutes.MY_PROFILE,
      page: () => const MyProfileView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.EDIT_PROFILE,
      page: () => const EditProfileView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.INTERESTS_LANGUAGES,
      page: () => const InterestsLanguagesView(),
    ),
    GetPage(name: AppRoutes.MY_ACTIVITY, page: () => const MyActivityView()),
    GetPage(
      name: AppRoutes.MY_COMMUNITIES,
      page: () => const MyCommunitiesView(),
    ),
    GetPage(
      name: AppRoutes.PRIVATE_CIRCLES,
      page: () => const PrivateCirclesView(),
    ),
    GetPage(name: AppRoutes.MY_CREATIONS, page: () => const MyCreationsView()),
    GetPage(
      name: AppRoutes.CONNECTIONS,
      page: () => const ConnectionsView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.REPORTS,
      page: () => const ReportsView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.BLOCKED_USERS,
      page: () => const BlockedUsersView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.SETTINGS_SUPPORT,
      page: () => const SettingsSupportView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.SUPPORT_ARTICLE,
      page: () => const SupportArticleView(),
    ),
    GetPage(
      name: AppRoutes.ACCOUNT_MANAGEMENT,
      page: () => const AccountManagementView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.DAILY_REWARDS,
      page: () => const DailyRewardsView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.REFERRAL,
      page: () => const ReferralView(),
      binding: ProfileBinding(),
    ),
    GetPage(
      name: AppRoutes.NOTIFICATIONS,
      page: () => const NotificationsView(),
      binding: NotificationsBinding(),
    ),
    GetPage(
      name: AppRoutes.CONNECT,
      page: () => const ConnectView(),
      binding: DiscoveryBinding(),
    ),
    GetPage(
      name: AppRoutes.CONNECTION_REQUEST,
      page: () => const ConnectionRequestView(),
      binding: DiscoveryBinding(),
    ),
  ];
}
