import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../routes/app_routes.dart';
import '../controllers/community_controller.dart';
import '../models/community.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';

class CommunityDetailsView extends StatefulWidget {
  const CommunityDetailsView({super.key});

  @override
  State<CommunityDetailsView> createState() => _CommunityDetailsViewState();
}

class _CommunityDetailsViewState extends State<CommunityDetailsView> {
  final CommunityController _communityController = Get.find<CommunityController>();

  Community? _community;
  final List<Post> _posts = [];
  bool _loading = true;
  String _feedFilter = 'Latest';
  Map<String, dynamic>? _subStatus;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() async {
    final Map args = Get.arguments is Map ? Get.arguments : {};
    final String? communityId = args['communityId']?.toString();

    if (communityId != null) {
      try {
        final comm = await _communityController.fetchCommunityDetails(communityId);
        _community = comm;
      } catch (_) {
        _community = _communityController.communities.firstWhereOrNull((c) => c.id == communityId);
      }

      try {
        final feed = await _communityController.fetchFeed(communityId: communityId);
        _posts.clear();
        _posts.addAll(feed);
      } catch (_) {}

      try {
        final sub = await _communityController.fetchSubscriptionStatus(communityId);
        _subStatus = sub;
      } catch (_) {}
    }

    if (mounted) setState(() => _loading = false);
  }

  void _toggleJoin() async {
    if (_community == null) return;
    final isPremium = _community!.privacy == 'private' || _community!.privacy == 'premium';
    final hasActiveSub = _subStatus?['is_subscribed'] == true || _subStatus?['isSubscribed'] == true;

    if (isPremium && _community!.kind != 'circle' && !hasActiveSub) {
      Get.defaultDialog(
        title: 'Join VIP Community 💎',
        middleText: 'Join this VIP group for ${_community!.themeColor.isNotEmpty ? 50 : 50} coins/month?',
        textConfirm: 'Confirm & Pay',
        textCancel: 'Cancel',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () async {
          Get.back();
          await _performJoin();
        },
      );
    } else {
      await _performJoin();
    }
  }

  Future<void> _performJoin() async {
    try {
      await _communityController.joinCommunity(_community!.id);
      final updated = await _communityController.fetchCommunityDetails(_community!.id);
      final sub = await _communityController.fetchSubscriptionStatus(_community!.id);
      if (mounted) {
        setState(() {
          _community = updated;
          _subStatus = sub;
        });
      }
      Get.snackbar('Joined 🎉', 'You are now a member of ${_community!.name}.');
    } catch (e) {
      Get.snackbar('Could not join', e.toString());
    }
  }

  void _leaveCommunity() {
    if (_community == null) return;
    Get.defaultDialog(
      title: 'Leave Community?',
      middleText: 'Are you sure you want to leave ${_community!.name}?',
      textConfirm: 'Leave',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        try {
          await _communityController.leaveCommunity(_community!.id);
          final updated = await _communityController.fetchCommunityDetails(_community!.id);
          if (mounted) setState(() => _community = updated);
          Get.snackbar('Left', 'You have left ${_community!.name}.');
        } catch (e) {
          Get.snackbar('Action failed', e.toString());
        }
      },
    );
  }

  void _deleteCommunity() {
    if (_community == null) return;
    final isCircle = _community!.kind == 'circle';
    Get.defaultDialog(
      title: isCircle ? 'Delete Private Circle?' : 'Delete Community?',
      middleText: 'This will permanently delete this community, all members, and all posts.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        try {
          await _communityController.deleteCommunity(_community!.id);
          Get.back();
          Get.snackbar('Deleted', 'Community was permanently deleted.');
        } catch (e) {
          Get.snackbar('Delete failed', e.toString());
        }
      },
    );
  }

  void _showShareDialog() {
    if (_community == null) return;
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Share ${_community!.name}', style: const TextStyle(color: AppColors.text, fontSize: 16.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14.0),
              AppCard(
                child: Row(
                  children: [
                    AppAvatar(name: _community!.name, avatarUrl: _community!.avatarUrl, size: 40.0),
                    const SizedBox(width: 10.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_community!.name, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                          Text('vibecam.app/c/${_community!.id}', style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),
              AppButton(
                title: 'Copy Link',
                icon: Icons.link,
                onPressed: () {
                  Get.back();
                  Get.snackbar('Link copied', 'Community link copied to clipboard!');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReportDialog() {
    if (_community == null) return;
    Get.defaultDialog(
      title: 'Report ${_community!.name}',
      middleText: 'Choose a reason for reporting. Only relevant evidence will be shared with moderators.',
      actions: [
        ListTile(
          title: const Text('Spam or scam', style: TextStyle(color: AppColors.text)),
          onTap: () {
            Get.back();
            NetworkApiService.instance.post('/safety/reports', data: {
              'target_type': 'community',
              'target_id': _community!.id,
              'reason': 'Spam or scam',
            });
            Get.snackbar('Report submitted', 'Thank you. Our safety team will review your report.');
          },
        ),
        ListTile(
          title: const Text('Harassment', style: TextStyle(color: AppColors.danger)),
          onTap: () {
            Get.back();
            NetworkApiService.instance.post('/safety/reports', data: {
              'target_type': 'community',
              'target_id': _community!.id,
              'reason': 'Harassment',
            });
            Get.snackbar('Report submitted', 'Thank you. Our safety team will review your report.');
          },
        ),
      ],
    );
  }

  Widget _buildCoverHero() {
    final comm = _community!;
    final imageUrl = comm.coverUrl ?? '';
    final hasImage = imageUrl.isNotEmpty;
    final resolvedUrl = hasImage ? (Helpers.resolveImageUrl(imageUrl) ?? '') : '';

    return Stack(
      children: [
        SizedBox(
          width: double.infinity,
          height: 180.0,
          child: hasImage && resolvedUrl.isNotEmpty
              ? Image.network(
                  resolvedUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => _communityGradient(comm),
                )
              : _communityGradient(comm),
        ),
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black87],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.35, 1.0],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: 14.0,
          left: 14.0,
          right: 14.0,
          child: Row(
            children: [
              AppAvatar(
                name: comm.name,
                avatarUrl: comm.logoUrl ?? comm.avatarUrl,
                size: 52.0,
              ),
              const SizedBox(width: 12.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      comm.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900,
                        shadows: [Shadow(blurRadius: 6, color: Colors.black54)],
                      ),
                    ),
                    const SizedBox(height: 3.0),
                    Row(
                      children: [
                        if (comm.kind == 'circle') ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lock, size: 10.0, color: Colors.white),
                                SizedBox(width: 3.0),
                                Text(
                                  'PRIVATE CIRCLE',
                                  style: TextStyle(color: Colors.white, fontSize: 9.0, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6.0),
                        ] else ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            child: Text(
                              comm.category,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6.0),
                        ],
                        Text(
                          '${comm.memberCount} members',
                          style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _communityGradient(Community comm) {
    final int hash = comm.name.codeUnits.fold(0, (prev, e) => prev + e);
    const gradients = [
      [Color(0xFF5B5CE2), Color(0xFF9B5CE2)],
      [Color(0xFFD63384), Color(0xFF7C3AED)],
      [Color(0xFF22C55E), Color(0xFF0EA5E9)],
      [Color(0xFFE2455B), Color(0xFFE2845B)],
    ];
    final pair = gradients[hash % gradients.length];
    return Container(
      height: 180.0,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pair,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        comm.name.isNotEmpty ? comm.name[0].toUpperCase() : 'C',
        style: const TextStyle(
          fontSize: 60.0,
          fontWeight: FontWeight.w900,
          color: Colors.white30,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScreen(
        header: AppHeader(title: 'Community', onBack: () => Get.back()),
        child: const Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator())),
      );
    }

    if (_community == null) {
      return AppScreen(
        header: AppHeader(
          title: 'Community',
          onBack: () => Get.back(),
        ),
        child: const AppEmptyState(
          title: 'Community unavailable',
          text: 'Refresh and try again.',
        ),
      );
    }

    final bool isJoined = _communityController.joinedCommunities.contains(_community!.id) || _community!.isJoined || _community!.joined;

    // Filter posts
    final filteredPosts = _posts.where((p) {
      if (_feedFilter == 'Unanswered') return p.comments == 0;
      if (_feedFilter == 'Polls') return p.postType.toLowerCase() == 'poll';
      return true;
    }).toList();

    if (_feedFilter == 'Popular') {
      filteredPosts.sort((a, b) => (b.likes + b.comments).compareTo(a.likes + a.comments));
    }

    return AppScreen(
      header: AppHeader(
        title: 'Community',
        onBack: () => Get.back(),
        right: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIconButton(icon: Icons.share_outlined, onPressed: _showShareDialog),
            AppIconButton(icon: Icons.more_horiz, onPressed: _showReportDialog),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Hero Banner
            ClipRRect(
              borderRadius: BorderRadius.circular(22.0),
              child: _buildCoverHero(),
            ),
            const SizedBox(height: 14.0),

            // VIP Community Badge
            if (_community!.kind != 'circle' && (_community!.privacy == 'private' || _community!.privacy == 'premium'))
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('VIP Premium Community 💎', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14.0)),
                    const SizedBox(height: 4.0),
                    if (_subStatus != null && (_subStatus!['is_subscribed'] == true || _subStatus!['isSubscribed'] == true))
                      Text(
                        '🔓 Active VIP Access! Expires: ${_subStatus!['expires_at'] != null ? _subStatus!['expires_at'].toString().split('T')[0] : "Lifetime"}',
                        style: const TextStyle(color: AppColors.success, fontSize: 12.0, fontWeight: FontWeight.bold),
                      )
                    else
                      const Text(
                        'Unlock VIP group access for exclusive discussions, member perks, and resources.',
                        style: TextStyle(color: AppColors.muted, fontSize: 12.0),
                      ),
                  ],
                ),
              ),

            // Description
            if (_community!.description.isNotEmpty) ...[
              Text(
                _community!.description,
                style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.4),
              ),
              const SizedBox(height: 12.0),
            ],

            // Tags
            if (_community!.tags.isNotEmpty) ...[
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: _community!.tags.map((t) {
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(16.0),
                    ),
                    child: Text('#$t', style: const TextStyle(color: AppColors.primary, fontSize: 12.0)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14.0),
            ],

            // Member Action Grid
            if (isJoined) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4.0),
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                          child: const Icon(Icons.check, color: Colors.white, size: 14.0),
                        ),
                        const SizedBox(width: 8.0),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('You\'re a community member', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 13.5)),
                              Text('Join the group chat, meet members, or share a post.', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14.0),
                    Row(
                      children: [
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.chat_bubble_outline,
                            color: AppColors.primary,
                            title: 'Group chat',
                            subtitle: 'Message everyone',
                            onTap: () => Get.toNamed(AppRoutes.COMMUNITY_CHAT, arguments: {'communityId': _community!.id}),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: _ActionTile(
                            icon: Icons.people_outline,
                            color: AppColors.success,
                            title: 'Members',
                            subtitle: 'Find people',
                            onTap: () => Get.toNamed(AppRoutes.COMMUNITY_MEMBERS, arguments: {'communityId': _community!.id}),
                          ),
                        ),
                      ],
                    ),
                    if (_community!.isOwner) ...[
                      const SizedBox(height: 8.0),
                      Row(
                        children: [
                          Expanded(
                            child: _ActionTile(
                              icon: Icons.person_add_alt_1,
                              color: const Color(0xFFD88712),
                              title: 'Join requests',
                              subtitle: 'Review access',
                              onTap: () => Get.toNamed(AppRoutes.COMMUNITY_JOIN_REQUESTS, arguments: {'communityId': _community!.id}),
                            ),
                          ),
                          if (_community!.kind == 'circle') ...[
                            const SizedBox(width: 8.0),
                            Expanded(
                              child: _ActionTile(
                                icon: Icons.group_add_outlined,
                                color: AppColors.primary,
                                title: 'Invite people',
                                subtitle: '${_community!.memberCount}/${_community!.maxMembers} limit',
                                onTap: () => Get.toNamed(AppRoutes.INVITE_CIRCLE_MEMBERS, arguments: {'communityId': _community!.id}),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              AppButton(
                title: 'Create a post here',
                icon: Icons.create_outlined,
                onPressed: () => Get.toNamed(AppRoutes.CREATE_POST, arguments: {'communityId': _community!.id}),
              ),
            ] else ...[
              AppButton(
                title: _community!.joinPending
                    ? 'Request pending'
                    : _community!.privacy == 'private' && _community!.kind == 'circle'
                        ? 'Invite only'
                        : 'Join community',
                disabled: _community!.joinPending || (_community!.privacy == 'private' && _community!.kind == 'circle'),
                icon: Icons.person_add_alt_outlined,
                onPressed: _toggleJoin,
              ),
            ],
            const SizedBox(height: 16.0),

            // Community Rules Card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Community rules', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14.0)),
                  const SizedBox(height: 10.0),
                  ...(_community!.rules.isNotEmpty
                          ? _community!.rules
                          : ['Be kind and stay on topic', 'No spam or promotional links', 'Report unsafe content'])
                      .asMap()
                      .entries
                      .map((e) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 20.0,
                            height: 20.0,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(6.0),
                            ),
                            alignment: Alignment.center,
                            child: Text('${e.key + 1}', style: const TextStyle(color: AppColors.primary, fontSize: 11.0, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 8.0),
                          Expanded(
                            child: Text(e.value, style: const TextStyle(color: AppColors.text, fontSize: 12.5)),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
            const SizedBox(height: 20.0),

            // Community Posts Header & Filter Pills
            const Text('Community posts', style: AppTextStyles.h2),
            const SizedBox(height: 10.0),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['Latest', 'Popular', 'Unanswered', 'Polls'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AppPill(
                      label: filter,
                      selected: _feedFilter == filter,
                      onPressed: () => setState(() => _feedFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 12.0),

            // Posts List
            filteredPosts.isNotEmpty
                ? Column(
                    children: filteredPosts.map((post) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: PostCard(
                          post: post,
                          onPressed: () => Get.toNamed(AppRoutes.POST_DETAILS, arguments: {'postId': post.id}),
                          onLikePressed: () => _communityController.toggleLike(post.id),
                          onBookmarkPressed: () => _communityController.toggleSave(post.id),
                          onAuthorPressed: () => Get.toNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': post.authorId}),
                        ),
                      );
                    }).toList(),
                  )
                : const AppEmptyState(
                    title: 'No posts found',
                    text: 'Be the first to share something in this community.',
                  ),
            const SizedBox(height: 20.0),

            // Danger Actions (Leave or Delete)
            if (isJoined) ...[
              if (_community!.isOwner)
                AppButton(
                  title: _community!.kind == 'circle' ? 'Delete private circle' : 'Delete community',
                  tone: AppButtonTone.danger,
                  onPressed: _deleteCommunity,
                )
              else
                AppButton(
                  title: 'Leave community',
                  tone: AppButtonTone.secondary,
                  onPressed: _leaveCommunity,
                ),
            ],
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(14.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: color, size: 20.0),
            ),
            const SizedBox(height: 8.0),
            Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 13.0)),
            Text(subtitle, style: const TextStyle(color: AppColors.muted, fontSize: 11.0)),
          ],
        ),
      ),
    );
  }
}

