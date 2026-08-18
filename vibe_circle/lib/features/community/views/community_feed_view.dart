import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../controllers/community_controller.dart';
import '../widgets/post_card.dart';
import '../../../routes/app_routes.dart';

class CommunityFeedView extends GetView<CommunityController> {
  const CommunityFeedView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadFeed();

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
                Text('Feed', style: AppTextStyles.title),
                Row(
                  children: [
                    AppIconButton(
                      icon: Icons.search,
                      onPressed: () => Get.toNamed(AppRoutes.GLOBAL_SEARCH),
                    ),
                    const SizedBox(width: 8.0),
                    AppIconButton(
                      icon: Icons.notifications_none_outlined,
                      onPressed: () => Get.toNamed(AppRoutes.NOTIFICATIONS),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // For you / Trending filter pills
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                AppPill(label: 'For you', selected: true, onPressed: () {}),
                const SizedBox(width: 8.0),
                AppPill(label: 'Trending', selected: false, onPressed: () {}),
              ],
            ),
          ),
          const SizedBox(height: 14.0),

          // Posts Feed List
          Expanded(
            child: Obx(() {
              return controller.loading.value
                  ? const Center(child: CircularProgressIndicator())
                  : controller.posts.isNotEmpty
                      ? ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: controller.posts.length,
                          itemBuilder: (context, idx) {
                            final post = controller.posts[idx];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: PostCard(post: post),
                            );
                          },
                        )
                      : const AppEmptyState(
                          icon: Icons.feed_outlined,
                          title: 'Feed is empty',
                          text: 'Be the first to share a question or start a conversation!',
                        );
            }),
          ),
        ],
      ),
    );
  }
}
