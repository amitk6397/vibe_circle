import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/community_controller.dart';
import '../models/community.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';
import '../../../core/utils/helpers.dart';
import '../../../routes/app_routes.dart';

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

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  void _loadDetails() async {
    final Map args = Get.arguments ?? {};
    final String? communityId = args['communityId']?.toString();

    if (communityId != null) {
      _community = _communityController.communities.firstWhereOrNull((c) => c.id == communityId);
      try {
        final feed = await _communityController.fetchFeed(communityId: communityId);
        setState(() {
          _posts.clear();
          _posts.addAll(feed);
        });
      } catch (_) {}
    }

    setState(() => _loading = false);
  }

  void _toggleJoin() async {
    if (_community == null) return;
    try {
      await _communityController.joinCommunity(_community!.id);
      _communityController.loadCommunities();
      Get.snackbar('Success', 'Community membership updated.');
    } catch (e) {
      Get.snackbar('Action failed', e.toString());
    }
  }

  Widget _buildCoverHero() {
    final comm = _community!;
    final imageUrl = comm.coverUrl ?? comm.avatarUrl ?? '';
    final hasImage = imageUrl.isNotEmpty;
    final resolvedUrl = hasImage ? (Helpers.resolveImageUrl(imageUrl) ?? '') : '';

    return Stack(
      children: [
        // Background image or gradient
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
        // Gradient overlay bottom
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
        // Info overlaid at bottom
        Positioned(
          bottom: 14.0,
          left: 14.0,
          right: 14.0,
          child: Row(
            children: [
              AppAvatar(
                name: comm.name,
                avatarUrl: comm.avatarUrl,
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
                        const SizedBox(width: 8.0),
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
        comm.name[0].toUpperCase(),
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

    final bool isJoined = _communityController.joinedCommunities.contains(_community!.id);

    return AppScreen(
      header: AppHeader(
        title: 'Community',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Cover Hero Banner (full-width image or gradient)
            ClipRRect(
              borderRadius: BorderRadius.circular(22.0),
              child: _buildCoverHero(),
            ),
            const SizedBox(height: 16.0),

            Text(
              _community!.description,
              style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.4),
            ),
            const SizedBox(height: 16.0),

            // Action Buttons
            if (isJoined) ...[
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('You\'re a community member', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2.0),
                    const Text('Join the group chat, meet members, or share a post.', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                    const SizedBox(height: 12.0),
                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            title: 'Group chat',
                            tone: AppButtonTone.secondary,
                            onPressed: () => Get.toNamed(AppRoutes.COMMUNITY_CHAT, arguments: {'communityId': _community!.id}),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: AppButton(
                            title: 'Members',
                            tone: AppButtonTone.secondary,
                            onPressed: () => Get.toNamed(AppRoutes.COMMUNITY_MEMBERS, arguments: {'communityId': _community!.id}),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12.0),
              AppButton(
                title: 'Create a post here',
                onPressed: () => Get.toNamed(AppRoutes.CREATE_POST, arguments: {'communityId': _community!.id}),
              ),
            ] else ...[
              AppButton(
                title: 'Join community',
                onPressed: _toggleJoin,
              ),
            ],
            const SizedBox(height: 20.0),

            const Text('Community posts', style: AppTextStyles.h2),
            const SizedBox(height: 10.0),

            // Filter Pills
            Row(
              children: ['Latest', 'Popular', 'Unanswered'].map((filter) {
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
            const SizedBox(height: 12.0),

            // Posts List
            _loading
                ? const Center(child: CircularProgressIndicator())
                : _posts.isNotEmpty
                    ? Column(
                        children: _posts.map((post) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: PostCard(
                              post: post,
                              onPressed: () => Get.toNamed(AppRoutes.POST_DETAILS, arguments: {'postId': post.id}),
                            ),
                          );
                        }).toList(),
                      )
                    : const AppEmptyState(
                        title: 'No posts yet',
                        text: 'Be the first to share something in this group.',
                      ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
