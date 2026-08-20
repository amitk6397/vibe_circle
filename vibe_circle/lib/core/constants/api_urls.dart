import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

class ApiUrls {
  ApiUrls._();

  static String get baseUrl {
    if (kIsWeb) {
      return 'http://192.168.31.161:8000/api/v1';
    }
    // Check if running on Android Emulator (needs 10.0.2.2) vs others (127.0.0.1 or localhost)
    final String host = Platform.isAndroid ? '192.168.31.161' : '127.0.0.1';
    return 'http://$host:8000/api/v1';
  }

  // WebSocket base URL helper
  static String get wsBaseUrl {
    if (kIsWeb) {
      return 'ws://192.168.31.161:8000/api/v1';
    }
    final String host = Platform.isAndroid ? '192.168.31.161' : '127.0.0.1';
    return 'ws://$host:8000/api/v1';
  }

  // Auth endpoints
  static String get login => '/auth/login';
  static String get register => '/auth/register';
  static String get restore => '/users/me';
  static String get logout => '/auth/logout';
  static String get forgotPassword => '/auth/forgot-password';
  static String get requestVerification => '/auth/request-verification';
  static String get verifyEmail => '/auth/verify-email';
  static String get referralInfo => '/auth/referral-info';

  // App content endpoints
  static String get support => '/app-content/support';

  // User endpoints
  static String publicProfile(String id) => '/users/$id';
  static String get updateProfile => '/users/me';
  static String get updatePreferences => '/users/me/preferences';
  static String get updatePrivacy => '/users/me/privacy';
  static String get updateNotificationPreferences =>
      '/users/me/notification-preferences';
  static String get availability => '/users/me/availability';
  static String get connections => '/users/connections';
  static String connectionAction(String id) => '/users/connections/$id';
  static String get activity => '/users/me/activity';

  // Discovery endpoints
  static String get discoveryUsers => '/discovery/users';
  static String get communities => '/communities';
  static String get feedPosts => '/feed/posts';
  static String get search => '/discovery/search';
  static String get recommendedPeople => '/discovery/recommended-people';

  // Feed/Posts endpoints
  static String postDetails(String id) => '/feed/posts/$id';
  static String postComments(String id) => '/feed/posts/$id/comments';
  static String commentLike(String id) => '/feed/comments/$id/like';
  static String commentAction(String id) => '/feed/comments/$id';
  static String votePost(String id) => '/feed/posts/$id/vote';
  static String likePost(String id) => '/feed/posts/$id/like';
  static String savePost(String id) => '/feed/posts/$id/save';
  static String unlockPost(String id) => '/feed/posts/$id/unlock';
  static String tipPost(String id) => '/feed/posts/$id/tip';
  static String postTips(String id) => '/feed/posts/$id/tips';
  static String boostPost(String id) => '/feed/posts/$id/boost';
  static String awardBounty(String id) => '/feed/posts/$id/award-bounty';
  static String postBountyStatus(String id) => '/feed/posts/$id/bounty';

  // Communities endpoints
  static String joinCommunity(String id) => '/communities/$id/join';
  static String leaveCommunity(String id) => '/communities/$id/leave';
  static String deleteCommunity(String id) => '/communities/$id';
  static String communityDetails(String id) => '/communities/$id';
  static String communityMembers(String id) => '/communities/$id/members';
  static String shareCommunity(String id) => '/communities/$id/share';
  static String sharePost(String id) => '/feed/posts/$id/share';
  static String get circleInvites => '/communities/invitations/me';
  static String inviteToCircle(String id) => '/communities/$id/invite';
  static String circleInviteAction(String id) => '/communities/invitations/$id';
  static String communityJoinRequests(String id) =>
      '/communities/$id/join-requests';
  static String communityJoinRequestsAction(String commId, String reqId) =>
      '/communities/$commId/join-requests/$reqId';
  static String sendCommunityMessage(String id) => '/communities/$id/messages';
  static String communitySubscriptionStatus(String id) =>
      '/communities/$id/subscription-status';

  // Story endpoints
  static String get stories => '/feed/stories';
  static String storyView(String id) => '/feed/stories/$id/view';
  static String storyReact(String id) => '/feed/stories/$id/reactions';
  static String storyReply(String id) => '/feed/stories/$id/replies';
  static String storyAction(String id) => '/feed/stories/$id';
  static String storyMute(String id) => '/feed/stories/$id/mute';
  static String storyArchive(String id) => '/feed/stories/$id/archive';
  static String get storiesArchiveList => '/feed/stories/archive';

  // Chat endpoints
  static String get createConversation => '/chat/conversations';
  static String get conversations => '/chat/conversations';
  static String messages(String conversationId) =>
      '/chat/conversations/$conversationId/messages';
  static String communityMessages(String communityId) =>
      '/communities/$communityId/messages';
  static String markRead(String conversationId) =>
      '/chat/conversations/$conversationId/read';
  static String sendPrivateMessage(String conversationId) =>
      '/chat/conversations/$conversationId/messages';
  static String reactMessage(String messageId) =>
      '/chat/messages/$messageId/reactions';
  static String deleteMessage(String messageId) => '/chat/messages/$messageId';
  static String get chatLimits => '/chat/limits';
  static String get messageRequests => '/chat/message-requests';
  static String messageRequestAction(String id) => '/chat/message-requests/$id';
  static String unlockConversation(String id) =>
      '/chat/conversations/$id/unlock';
  static String deductChatMinute(String id) =>
      '/chat/conversations/$id/deduct-minute';

  // WebSockets path helper
  static String privateChatWs(String conversationId) =>
      '/chat/ws/$conversationId';
  static String communityChatWs(String communityId) =>
      '/communities/ws/$communityId';
  static String callWs(String callId) => '/calls/ws/$callId';

  // Subscription endpoints
  static String get subscriptionPlans => '/subscriptions/plans';
  static String get activeSubscription => '/subscriptions/active';
  static String get subscriptionHistory => '/subscriptions/history';
  static String get purchaseSubscription => '/subscriptions/purchase';
  static String get cancelRenewal => '/subscriptions/cancel-renewal';

  // Wallet endpoints
  static String get wallet => '/wallet';
  static String get coinPackages => '/wallet/coin-packages';
  static String get walletOffers => '/wallet/offers';
  static String get walletTransactions => '/wallet/transactions';
  static String get buyCoins => '/wallet/buy-coins';
  static String get coinPricing => '/wallet/pricing';
  static String get walletDashboard => '/wallet/dashboard';
  static String get claimDailyReward => '/wallet/claim-daily-reward';
  static String get dailyRewardStatus => '/wallet/daily-reward-status';

  // Earnings endpoints
  static String earningsProfile(String id) => '/earnings/profile/$id';
  static String get myEarningsProfile => '/earnings/profile/me';
  static String get earningsDashboard => '/earnings/dashboard';
  static String get earningsHistory => '/earnings/history';
  static String get withdrawals => '/earnings/withdrawals';

  // Engagement/Gifts/Reviews endpoints
  static String get gifts => '/gifts';
  static String get sendGift => '/gifts/send';
  static String userReviews(String id) => '/users/$id/reviews';
  static String get submitRating => '/ratings';

  // Matching endpoints
  static String get matchingStart => '/matching/start';
  static String get matchingStatus => '/matching/status';
  static String matchingAction(String matchId, String action) =>
      '/matching/$matchId/$action';
  static String matchingFeedback(String matchId) =>
      '/matching/$matchId/feedback';

  // Notifications endpoints
  static String get notifications => '/notifications';
  static String get notificationsMarkAllRead => '/notifications/read-all';
  static String notificationMarkRead(String id) => '/notifications/$id/read';
  static String notificationDelete(String id) => '/notifications/$id';
  static String get registerDeviceToken => '/notifications/device-token';

  // Safety endpoints
  static String get safetyBlocks => '/safety/blocks';
  static String safetyUnblock(String id) => '/safety/blocks/$id';
  static String get safetyReports => '/safety/reports';
  static String get myReports => '/safety/reports/me';

  // Account endpoints
  static String get logoutAll => '/auth/logout-all';
  static String get deleteAccount => '/auth/account';
  static String get exportData => '/users/me/export';

  // Livestream endpoints
  static String get livestreamStart => '/livestream/start';
  static String livestreamEnd(String id) => '/livestream/$id/end';
  static String get livestreamActive => '/livestream/active';
  static String livestreamJoin(String id) => '/livestream/$id/join';
  static String livestreamLeave(String id) => '/livestream/$id/leave';
  static String livestreamSendGift(String id) => '/livestream/$id/gift';

  // Uploads endpoints
  static String get uploads => '/uploads';

  // Call config & history
  static String get callsConfig => '/calls/config';
  static String get callsHistory => '/calls/history';
  static String get callsStart => '/calls';
  static String callGet(String id) => '/calls/$id';
  static String callToken(String id) => '/calls/$id/token';
  static String callJoin(String id) => '/calls/$id/join';
  static String callAction(String id, String action) => '/calls/$id/$action';
  static String callExtend(String id) => '/calls/$id/extend';
}
