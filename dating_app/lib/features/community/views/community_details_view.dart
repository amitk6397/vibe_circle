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
            // Cover Hero Box
            Container(
              padding: const EdgeInsets.all(20.0),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(22.0),
              ),
              child: Column(
                children: [
                  AppAvatar(
                    name: _community!.name,
                    avatarUrl: _community!.avatarUrl,
                    size: 64.0,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    _community!.name,
                    style: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '${_community!.memberCount} members · ${_community!.category}',
                    style: const TextStyle(color: AppColors.muted, fontSize: 12.0),
                  ),
                ],
              ),
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
