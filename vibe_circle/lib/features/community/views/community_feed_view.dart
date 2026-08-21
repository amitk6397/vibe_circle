import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../routes/app_routes.dart';
import '../controllers/community_controller.dart';
import '../models/post.dart';
import '../widgets/post_card.dart';

class CommunityFeedView extends StatefulWidget {
  const CommunityFeedView({super.key});

  @override
  State<CommunityFeedView> createState() => _CommunityFeedViewState();
}

class _CommunityFeedViewState extends State<CommunityFeedView> {
  final CommunityController _controller = Get.find<CommunityController>();
  String _activeFilter = 'For you';

  @override
  void initState() {
    super.initState();
    _controller.loadFeed();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      scroll: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'COMMUNITY',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 11.0,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text('Your feed', style: AppTextStyles.title),
                  ],
                ),
                Row(
                  children: [
                    AppIconButton(
                      icon: Icons.add,
                      onPressed: () => Get.toNamed(AppRoutes.CREATE_POST),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Feed filter pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ['For you', 'Following', 'Questions', 'Saved'].map((filter) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: AppPill(
                      label: filter,
                      selected: _activeFilter == filter,
                      onPressed: () => setState(() => _activeFilter = filter),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 14.0),

          // Posts Feed List
          Expanded(
            child: Obx(() {
              final allPosts = _controller.posts;
              final List<Post> filtered = allPosts.where((post) {
                if (_activeFilter == 'Questions') {
                  return post.postType.toLowerCase() == 'question';
                }
                if (_activeFilter == 'Saved') {
                  return post.saved || _controller.savedPosts.contains(post.id);
                }
                return true;
              }).toList();

              return _controller.loading.value
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: filtered.length,
                          itemBuilder: (context, idx) {
                            final post = filtered[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: PostCard(
                                post: post,
                                onPressed: () => Get.toNamed(
                                  AppRoutes.POST_DETAILS,
                                  arguments: {'postId': post.id, 'post': post},
                                ),
                                onLikePressed: () => _controller.toggleLike(post.id),
                                onBookmarkPressed: () => _controller.toggleSave(post.id),
                                onAuthorPressed: () => Get.toNamed(
                                  AppRoutes.PUBLIC_PROFILE,
                                  arguments: {'personId': post.authorId},
                                ),
                                onCommentPressed: () => Get.toNamed(
                                  AppRoutes.POST_DETAILS,
                                  arguments: {'postId': post.id, 'post': post},
                                ),
                              ),
                            );
                          },
                        )
                      : AppEmptyState(
                          icon: Icons.feed_outlined,
                          title: _activeFilter == 'Saved' ? 'No saved posts' : 'Feed is empty',
                          text: _activeFilter == 'Saved'
                              ? 'Bookmark posts you want to revisit later.'
                              : 'Be the first to share a question or start a conversation!',
                        );
            }),
          ),
        ],
      ),
    );
  }
}

