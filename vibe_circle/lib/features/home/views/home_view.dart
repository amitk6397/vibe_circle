import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_circle/features/home/models/story_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../community/widgets/post_card.dart';
import '../../discovery/models/person.dart';
import '../../../routes/app_routes.dart';
import '../../../core/utils/helpers.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../community/controllers/community_controller.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final authController = Get.find<AuthController>();
    final communityController = Get.find<CommunityController>();
    final discoveryController = Get.find<DiscoveryController>();

    return Obx(() {
      final double shiftOffset = controller.storyRailOpen.value
          ? (controller.storyRailSide.value == 'left' ? 102.0 : -102.0)
          : 0.0;
      final discoverPosts = communityController.posts
          .where((post) => post.community == 'Discover')
          .toList();

      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Stack(
          children: [
            // 1. Stories Rail Collapsible sidebar
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              left: controller.storyRailSide.value == 'left'
                  ? (controller.storyRailOpen.value ? 0.0 : -102.0)
                  : null,
              right: controller.storyRailSide.value == 'right'
                  ? (controller.storyRailOpen.value ? 0.0 : -102.0)
                  : null,
              top: 0,
              bottom: 0,
              width: 102.0,
              child: Container(
                color: const Color(0xFF15192B),
                child: SafeArea(
                  child: Column(
                    children: [
                      const SizedBox(height: 12.0),
                      const Text(
                        'Stories',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 10.0),
                      Expanded(
                        child: SingleChildScrollView(
                          child: Column(
                            children: [
                              // User's own story circle or upload button
                              Builder(
                                builder: (context) {
                                  final myGroup = controller.storyGroups
                                      .firstWhereOrNull((g) => g.mine);
                                  final hasMyStories =
                                      myGroup != null &&
                                      myGroup.stories.isNotEmpty;
                                  final String? avatarUrl =
                                      authController.profile.value?.avatarUrl;

                                  if (hasMyStories) {
                                    final firstStory = myGroup.stories.first;
                                    return GestureDetector(
                                      onTap: () => controller.openStory(
                                        myGroup.authorId,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 8.0,
                                        ),
                                        child: Column(
                                          children: [
                                            Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                Container(
                                                  width: 50.0,
                                                  height: 50.0,
                                                  decoration:
                                                      const BoxDecoration(
                                                        shape: BoxShape.circle,
                                                        gradient:
                                                            LinearGradient(
                                                              colors: [
                                                                Color(
                                                                  0xFFD63384,
                                                                ),
                                                                Color(
                                                                  0xFF7C3AED,
                                                                ),
                                                              ],
                                                              begin: Alignment
                                                                  .topLeft,
                                                              end: Alignment
                                                                  .bottomRight,
                                                            ),
                                                      ),
                                                  padding: const EdgeInsets.all(
                                                    2.0,
                                                  ),
                                                  child: Container(
                                                    decoration:
                                                        const BoxDecoration(
                                                          color: Color(
                                                            0xFF15192B,
                                                          ),
                                                          shape:
                                                              BoxShape.circle,
                                                        ),
                                                    padding:
                                                        const EdgeInsets.all(
                                                          2.0,
                                                        ),
                                                    child: CircleAvatar(
                                                      backgroundColor:
                                                          AppColors.surfaceAlt,
                                                      backgroundImage:
                                                          avatarUrl != null &&
                                                              avatarUrl
                                                                  .isNotEmpty
                                                          ? NetworkImage(
                                                              Helpers.resolveImageUrl(
                                                                    avatarUrl,
                                                                  ) ??
                                                                  '',
                                                            )
                                                          : (firstStory
                                                                    .mediaUrl
                                                                    .isNotEmpty
                                                                ? NetworkImage(
                                                                    Helpers.resolveImageUrl(
                                                                          firstStory
                                                                              .mediaUrl,
                                                                        ) ??
                                                                        '',
                                                                  )
                                                                : null),
                                                      child:
                                                          avatarUrl == null ||
                                                              avatarUrl.isEmpty
                                                          ? const Icon(
                                                              Icons.person,
                                                              color:
                                                                  Colors.white,
                                                              size: 20,
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                                ),
                                                Positioned(
                                                  bottom: 0,
                                                  right: 0,
                                                  child: GestureDetector(
                                                    onTap: controller
                                                        .chooseStoryAudience,
                                                    child: Container(
                                                      width: 18.0,
                                                      height: 18.0,
                                                      decoration: BoxDecoration(
                                                        color:
                                                            AppColors.primary,
                                                        shape: BoxShape.circle,
                                                        border: Border.all(
                                                          color: const Color(
                                                            0xFF15192B,
                                                          ),
                                                          width: 1.5,
                                                        ),
                                                      ),
                                                      alignment:
                                                          Alignment.center,
                                                      child:
                                                          controller
                                                              .storyUploading
                                                              .value
                                                          ? const SizedBox(
                                                              width: 10,
                                                              height: 10,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                    strokeWidth:
                                                                        1.5,
                                                                    color: Colors
                                                                        .white,
                                                                  ),
                                                            )
                                                          : const Icon(
                                                              Icons.add,
                                                              size: 12.0,
                                                              color:
                                                                  Colors.white,
                                                            ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4.0),
                                            const Text(
                                              'Your Story',
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 10.0,
                                                fontWeight: FontWeight.bold,
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }

                                  return GestureDetector(
                                    onTap: controller.chooseStoryAudience,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 8.0,
                                      ),
                                      child: Column(
                                        children: [
                                          Stack(
                                            alignment: Alignment.center,
                                            children: [
                                              Container(
                                                width: 50.0,
                                                height: 50.0,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppColors.muted,
                                                    width: 1.5,
                                                  ),
                                                ),
                                                padding: const EdgeInsets.all(
                                                  2.0,
                                                ),
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      AppColors.surfaceAlt,
                                                  backgroundImage:
                                                      avatarUrl != null &&
                                                          avatarUrl.isNotEmpty
                                                      ? NetworkImage(
                                                          Helpers.resolveImageUrl(
                                                                avatarUrl,
                                                              ) ??
                                                              '',
                                                        )
                                                      : null,
                                                  child:
                                                      avatarUrl == null ||
                                                          avatarUrl.isEmpty
                                                      ? const Icon(
                                                          Icons.person,
                                                          color:
                                                              AppColors.muted,
                                                          size: 24,
                                                        )
                                                      : null,
                                                ),
                                              ),
                                              Positioned(
                                                bottom: 0,
                                                right: 0,
                                                child: Container(
                                                  width: 18.0,
                                                  height: 18.0,
                                                  decoration: BoxDecoration(
                                                    color: AppColors.primary,
                                                    shape: BoxShape.circle,
                                                    border: Border.all(
                                                      color: const Color(
                                                        0xFF15192B,
                                                      ),
                                                      width: 1.5,
                                                    ),
                                                  ),
                                                  alignment: Alignment.center,
                                                  child:
                                                      controller
                                                          .storyUploading
                                                          .value
                                                      ? const SizedBox(
                                                          width: 10,
                                                          height: 10,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth:
                                                                    1.5,
                                                                color: Colors
                                                                    .white,
                                                              ),
                                                        )
                                                      : const Icon(
                                                          Icons.add,
                                                          size: 12.0,
                                                          color: Colors.white,
                                                        ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 4.0),
                                          const Text(
                                            'Add story',
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10.0,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),

                              // Grouped story circles for other authors (1 circle per user)
                              ...controller.storyGroups.where((g) => !g.mine).map((
                                group,
                              ) {
                                final String authorId = group.authorId;
                                final String name = group.authorName;
                                final bool allViewed = group.allViewed;
                                final firstStory = group.stories.first;
                                final String? avatarUrl = group.authorAvatarUrl;

                                return GestureDetector(
                                  onTap: () => controller.openStory(authorId),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 8.0,
                                    ),
                                    child: Column(
                                      children: [
                                        Container(
                                          width: 50.0,
                                          height: 50.0,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: allViewed
                                                ? null
                                                : const LinearGradient(
                                                    colors: [
                                                      Color(0xFFD63384),
                                                      Color(0xFF7C3AED),
                                                    ],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                            border: allViewed
                                                ? Border.all(
                                                    color: AppColors.muted,
                                                    width: 1.5,
                                                  )
                                                : null,
                                          ),
                                          padding: const EdgeInsets.all(2.0),
                                          child: Container(
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF15192B),
                                              shape: BoxShape.circle,
                                            ),
                                            padding: const EdgeInsets.all(2.0),
                                            child: CircleAvatar(
                                              backgroundColor:
                                                  AppColors.surfaceAlt,
                                              backgroundImage:
                                                  avatarUrl != null &&
                                                      avatarUrl.isNotEmpty
                                                  ? NetworkImage(
                                                      Helpers.resolveImageUrl(
                                                            avatarUrl,
                                                          ) ??
                                                          '',
                                                    )
                                                  : (firstStory
                                                            .mediaUrl
                                                            .isNotEmpty
                                                        ? NetworkImage(
                                                            Helpers.resolveImageUrl(
                                                                  firstStory
                                                                      .mediaUrl,
                                                                ) ??
                                                                '',
                                                          )
                                                        : null),
                                              child:
                                                  avatarUrl == null ||
                                                      avatarUrl.isEmpty
                                                  ? Text(
                                                      name.isNotEmpty
                                                          ? name[0]
                                                                .toUpperCase()
                                                          : '?',
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    )
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          name,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontSize: 10.0,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 2. Main Feed Screen (translates when stories rail opens)
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              left: shiftOffset,
              right: -shiftOffset,
              top: 0,
              bottom: 0,
              child: GestureDetector(
                onHorizontalDragEnd: (details) {
                  final velocity = details.primaryVelocity ?? 0.0;
                  if (controller.storyRailSide.value == 'left') {
                    if (velocity > 300) {
                      // Swipe right -> Open left rail
                      controller.storyRailOpen.value = true;
                    } else if (velocity < -300) {
                      // Swipe left -> Close left rail
                      controller.storyRailOpen.value = false;
                    }
                  } else if (controller.storyRailSide.value == 'right') {
                    if (velocity < -300) {
                      // Swipe left -> Open right rail
                      controller.storyRailOpen.value = true;
                    } else if (velocity > 300) {
                      // Swipe right -> Close right rail
                      controller.storyRailOpen.value = false;
                    }
                  }
                },
                child: Container(
                  color: AppColors.bg,
                  child: SafeArea(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Top Custom Header Row
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () => controller.changeTab(4),
                                    child: AppAvatar(
                                      name:
                                          authController.profile.value?.name ??
                                          'You',
                                      avatarUrl: authController
                                          .profile
                                          .value
                                          ?.avatarUrl,
                                      size: 44.0,
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'YOUR VIBECIRCLE',
                                        style: TextStyle(
                                          color: AppColors.primary,
                                          fontSize: 10.0,
                                          fontWeight: FontWeight.w900,
                                          letterSpacing: 1.2,
                                        ),
                                      ),
                                      Text(
                                        'Hi, ${authController.profile.value?.name.split(' ')[0] ?? 'User'} 👋',
                                        style: const TextStyle(
                                          color: AppColors.text,
                                          fontSize: 18.0,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  // Coin Balance Pill
                                  GestureDetector(
                                    onTap: () => Get.toNamed(
                                      AppRoutes.SUBSCRIPTION_PLANS,
                                    ),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8.0,
                                        vertical: 5.0,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.surfaceAlt,
                                        borderRadius: BorderRadius.circular(
                                          16.0,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(3.0),
                                            decoration: const BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors:
                                                    AppColors.primaryGradient,
                                              ),
                                            ),
                                            child: const Icon(
                                              Icons.cookie,
                                              size: 12.0,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const SizedBox(width: 4.0),
                                          Text(
                                            '${controller.coinBalance.value}',
                                            style: const TextStyle(
                                              color: AppColors.text,
                                              fontSize: 12.0,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const SizedBox(width: 4.0),
                                          const Icon(
                                            Icons.add_circle,
                                            size: 14.0,
                                            color: AppColors.primary,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10.0),
                                  // Notifications Icon Button
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: AppColors.surface,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: Badge(
                                        label: Text(
                                          '${controller.notificationsCount.value}',
                                        ),
                                        isLabelVisible:
                                            controller
                                                .notificationsCount
                                                .value >
                                            0,
                                        child: const Icon(
                                          Icons.notifications_none,
                                          color: AppColors.text,
                                        ),
                                      ),
                                      onPressed: () =>
                                          Get.toNamed(AppRoutes.NOTIFICATIONS),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        // Main feed scroll lists
                        Expanded(
                          child: Builder(
                            builder: (context) {
                              if (communityController.loading.value &&
                                  communityController.posts.isEmpty) {
                                return const Center(
                                  child: CircularProgressIndicator(),
                                );
                              }

                              return RefreshIndicator(
                                onRefresh: () async {
                                  await Future.wait([
                                    communityController.loadFeed(),
                                    discoveryController.loadDiscoverPeople(),
                                  ]);
                                  controller.loadCoinBalance();
                                },
                                child: SingleChildScrollView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16.0,
                                    vertical: 8.0,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      // Recommended People Horizontal Rail
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Recommended people',
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Get.toNamed(
                                              AppRoutes.RECOMMENDED_PEOPLE,
                                            ),
                                            child: const Text(
                                              'See all',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        height: 200,
                                        child: ListView.builder(
                                          scrollDirection: Axis.horizontal,
                                          itemCount:
                                              discoveryController
                                                      .people
                                                      .length >
                                                  6
                                              ? 6
                                              : discoveryController
                                                    .people
                                                    .length,
                                          itemBuilder: (context, idx) {
                                            final person =
                                                discoveryController.people[idx];
                                            return _buildRecommendedCard(
                                              person,
                                            );
                                          },
                                        ),
                                      ),
                                      const SizedBox(height: 20.0),

                                      // Posts feeds
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text(
                                            'Your feed',
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Get.toNamed(
                                              AppRoutes.COMMUNITY_FEED,
                                            ),
                                            child: const Text(
                                              'View feed',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4.0),

                                      if (discoverPosts.isEmpty)
                                        const AppEmptyState(
                                          icon: Icons.article_outlined,
                                          title: 'No posts yet',
                                          text:
                                              'Join a community and create the first post.',
                                        )
                                      else
                                        ...discoverPosts.map((post) {
                                          return PostCard(
                                            post: post,
                                            onPressed: () => Get.toNamed(
                                              AppRoutes.POST_DETAILS,
                                              arguments: {'postId': post.id},
                                            ),
                                          );
                                        }),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 3. Floating handle to slide stories open/closed
            if (!controller.storyRailOpen.value)
              Positioned(
                left:
                    controller.storyHandleX.value == 0.0 &&
                        controller.storyRailSide.value == 'right'
                    ? MediaQuery.of(context).size.width - 24.0
                    : controller.storyHandleX.value,
                top: controller.storyHandleY.value,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    controller.storyHandleY.value =
                        (details.globalPosition.dy - 45.0).clamp(
                          56.0,
                          MediaQuery.of(context).size.height - 210.0,
                        );
                  },
                  onHorizontalDragUpdate: (details) {
                    controller.storyHandleX.value =
                        (details.globalPosition.dx - 12.0).clamp(
                          0.0,
                          MediaQuery.of(context).size.width - 24.0,
                        );
                  },
                  onHorizontalDragEnd: (details) {
                    if (controller.storyHandleX.value <
                        MediaQuery.of(context).size.width / 2) {
                      controller.storyRailSide.value = 'left';
                      controller.storyHandleX.value = 0.0;
                    } else {
                      controller.storyRailSide.value = 'right';
                      controller.storyHandleX.value =
                          MediaQuery.of(context).size.width - 24.0;
                    }
                  },
                  child: InkWell(
                    onTap: controller.toggleStoryRail,
                    child: Container(
                      width: 24.0,
                      height: 90.0,
                      decoration: BoxDecoration(
                        color: const Color(0xD6D63384),
                        borderRadius: BorderRadius.only(
                          topRight: Radius.circular(
                            controller.storyRailSide.value == 'left' ? 12.0 : 0,
                          ),
                          bottomRight: Radius.circular(
                            controller.storyRailSide.value == 'left' ? 12.0 : 0,
                          ),
                          topLeft: Radius.circular(
                            controller.storyRailSide.value == 'right'
                                ? 12.0
                                : 0,
                          ),
                          bottomLeft: Radius.circular(
                            controller.storyRailSide.value == 'right'
                                ? 12.0
                                : 0,
                          ),
                        ),
                        border: Border.all(color: Colors.white30, width: 1.2),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Icon(
                            controller.storyRailSide.value == 'left'
                                ? Icons.chevron_right
                                : Icons.chevron_left,
                            size: 14.0,
                            color: Colors.white,
                          ),
                          RotatedBox(
                            quarterTurns: 3,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Icon(
                                  Icons.photo_library_outlined,
                                  size: 10.0,
                                  color: Colors.white,
                                ),
                                SizedBox(width: 4.0),
                                Text(
                                  'Story',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 9.0,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (controller.stories.isNotEmpty)
                            Container(
                              width: 6.0,
                              height: 6.0,
                              margin: const EdgeInsets.only(bottom: 4.0),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFF6B78),
                                shape: BoxShape.circle,
                              ),
                            )
                          else
                            const SizedBox(height: 6.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

            // Story Handle to slide back in when rail is open
            if (controller.storyRailOpen.value)
              Positioned(
                left: controller.storyRailSide.value == 'left' ? 102.0 : null,
                right: controller.storyRailSide.value == 'right' ? 102.0 : null,
                top: controller.storyHandleY.value,
                child: GestureDetector(
                  onTap: controller.toggleStoryRail,
                  child: Container(
                    width: 24.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF15192B),
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(
                          controller.storyRailSide.value == 'left' ? 8.0 : 0,
                        ),
                        bottomRight: Radius.circular(
                          controller.storyRailSide.value == 'left' ? 8.0 : 0,
                        ),
                        topLeft: Radius.circular(
                          controller.storyRailSide.value == 'right' ? 8.0 : 0,
                        ),
                        bottomLeft: Radius.circular(
                          controller.storyRailSide.value == 'right' ? 8.0 : 0,
                        ),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      controller.storyRailSide.value == 'left'
                          ? Icons.chevron_left
                          : Icons.chevron_right,
                      size: 16.0,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

            // 4. Story Player overlay modal
            if (controller.activeStoryOwner.value != null)
              _buildStoryPlayer(context),

            // 5. Daily Reward Dialog Modal
            if (controller.dailyRewardOpen.value &&
                controller.dailyRewardData.value != null)
              _buildDailyRewardDialog(),

            // 6. Draggable Floating Story Rail Handle (Edge Pill Button)
            if (controller.storyGroups.isNotEmpty)
              Positioned(
                top: controller.storyHandleY.value,
                left: controller.storyRailSide.value == 'left'
                    ? (controller.storyRailOpen.value ? 102.0 : 0.0)
                    : null,
                right: controller.storyRailSide.value == 'right'
                    ? (controller.storyRailOpen.value ? 102.0 : 0.0)
                    : null,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    final newY =
                        controller.storyHandleY.value + details.delta.dy;
                    final maxY = MediaQuery.of(context).size.height - 180.0;
                    controller.storyHandleY.value = newY.clamp(100.0, maxY);
                  },
                  onHorizontalDragEnd: (details) {
                    // Switch sides when dragged horizontally across middle
                    if (details.primaryVelocity != null &&
                        details.primaryVelocity!.abs() > 300) {
                      if (details.primaryVelocity! > 0) {
                        controller.storyRailSide.value = 'right';
                      } else {
                        controller.storyRailSide.value = 'left';
                      }
                    }
                  },
                  onTap: controller.toggleStoryRail,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF15192B),
                      borderRadius: BorderRadius.horizontal(
                        left: controller.storyRailSide.value == 'right'
                            ? const Radius.circular(16.0)
                            : Radius.zero,
                        right: controller.storyRailSide.value == 'left'
                            ? const Radius.circular(16.0)
                            : Radius.zero,
                      ),
                      border: Border.all(color: AppColors.border, width: 1.0),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black45,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          controller.storyRailOpen.value
                              ? (controller.storyRailSide.value == 'left'
                                    ? Icons.chevron_left
                                    : Icons.chevron_right)
                              : (controller.storyRailSide.value == 'left'
                                    ? Icons.chevron_right
                                    : Icons.chevron_left),
                          color: AppColors.primary,
                          size: 16.0,
                        ),
                        const SizedBox(height: 4.0),
                        const RotatedBox(
                          quarterTurns: 3,
                          child: Text(
                            'STORIES',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 9.0,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4.0),
                        // Unseen story indicator dot
                        if (controller.storyGroups.any(
                          (g) => !g.mine && !g.allViewed,
                        ))
                          Container(
                            width: 6.0,
                            height: 6.0,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD63384),
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

            // 7. FAB overlay menu (shows above FAB when open)
            if (controller.fabOpen.value)
              Positioned.fill(
                child: GestureDetector(
                  onTap: controller.closeFab,
                  behavior: HitTestBehavior.opaque,
                  child: Container(color: Colors.black54),
                ),
              ),
            if (controller.fabOpen.value)
              Positioned(
                bottom: 90.0 + MediaQuery.of(context).padding.bottom,
                right: 16.0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Create community action
                    GestureDetector(
                      onTap: () {
                        controller.closeFab();
                        Get.toNamed(AppRoutes.CREATE_COMMUNITY);
                      },
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Create community',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14.0,
                                shadows: [
                                  Shadow(blurRadius: 4, color: Colors.black87),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12.0),
                            Container(
                              width: 44.0,
                              height: 44.0,
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black38,
                                    blurRadius: 8,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.people,
                                size: 22.0,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Create post action
                    GestureDetector(
                      onTap: () {
                        controller.closeFab();
                        Get.toNamed(AppRoutes.CREATE_POST);
                      },
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Create post',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.0,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black87),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12.0),
                          Container(
                            width: 44.0,
                            height: 44.0,
                            decoration: const BoxDecoration(
                              color: AppColors.surface,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black38,
                                  blurRadius: 8,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.edit,
                              size: 22.0,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          backgroundColor: AppColors.primary,
          shape: const CircleBorder(),
          onPressed: controller.toggleFab,
          child: AnimatedRotation(
            turns: controller.fabOpen.value ? 0.125 : 0.0,
            duration: const Duration(milliseconds: 200),
            child: const Icon(Icons.add, size: 28.0, color: Colors.white),
          ),
        ),
      );
    });
  }

  Widget _buildRecommendedCard(Person person) {
    return GestureDetector(
      onTap: () => Get.toNamed(
        AppRoutes.PUBLIC_PROFILE,
        arguments: {'personId': person.id},
      ),
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18.0),
          color: AppColors.surfaceAlt,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Background image or gradient
            Positioned.fill(
              child: person.avatarUrl != null && person.avatarUrl!.isNotEmpty
                  ? Image.network(
                      Helpers.resolveImageUrl(person.avatarUrl!) ?? '',
                      fit: BoxFit.cover,
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Color(
                              int.parse(
                                person.avatarColor.replaceFirst('#', '0xFF'),
                              ),
                            ),
                            Color(
                              int.parse(
                                person.avatarColor.replaceFirst('#', '0xFF'),
                              ),
                            ).withAlpha(168),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        person.name[0].toUpperCase(),
                        style: const TextStyle(
                          fontSize: 44.0,
                          fontWeight: FontWeight.w900,
                          color: Colors.white70,
                        ),
                      ),
                    ),
            ),

            // Online Dot Status
            if (person.online == true)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  width: 12.0,
                  height: 12.0,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

            // Text Info Overlays
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(8.0),
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      person.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (person.city != null && person.city!.isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 10.0,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 2.0),
                          Expanded(
                            child: Text(
                              person.city!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 10.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4.0),
                    // Tags row
                    Row(
                      children: (person.interests).take(2).map((tag) {
                        return Container(
                          margin: const EdgeInsets.only(right: 4.0),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5.0,
                            vertical: 1.5,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            tag,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8.0,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryPlayer(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final authorStories = controller.stories
        .where((s) => s.authorId == controller.activeStoryOwner.value)
        .toList();
    if (authorStories.isEmpty || controller.activeStoryIndex.value == null) {
      return const SizedBox.shrink();
    }
    final int currentIndex = controller.activeStoryIndex.value!.clamp(
      0,
      authorStories.length - 1,
    );
    final StoryItem story = authorStories[currentIndex];
    final bool isMine = story.mine;

    return GestureDetector(
      onVerticalDragEnd: (details) {
        if ((details.primaryVelocity ?? 0) > 300) {
          controller.closeStoryViewer();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Story Image Content
            Positioned.fill(
              child: Image.network(
                Helpers.resolveImageUrl(story.mediaUrl) ?? '',
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(
                    Icons.broken_image,
                    color: Colors.white54,
                    size: 60,
                  ),
                ),
              ),
            ),

            // Top and Bottom Shades
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 120,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black87, Colors.transparent],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 140,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),

            // Emojis burst text
            if (controller.reactionBurst.value.isNotEmpty)
              Positioned.fill(
                child: AnimatedScale(
                  scale: controller.reactionScale.value,
                  duration: const Duration(milliseconds: 150),
                  child: Center(
                    child: Text(
                      controller.reactionBurst.value,
                      style: const TextStyle(fontSize: 80.0),
                    ),
                  ),
                ),
              ),

            // Segmented Progress lines (Instagram style)
            Positioned(
              top: MediaQuery.of(context).padding.top + 8.0,
              left: 12.0,
              right: 12.0,
              child: Row(
                children: List.generate(authorStories.length, (idx) {
                  double fillPercent = 0.0;
                  if (idx < currentIndex) {
                    fillPercent = 1.0;
                  } else if (idx == currentIndex) {
                    fillPercent = controller.storyProgress.value;
                  }

                  return Expanded(
                    child: Container(
                      height: 3.0,
                      margin: const EdgeInsets.symmetric(horizontal: 2.0),
                      decoration: BoxDecoration(
                        color: Colors.white30,
                        borderRadius: BorderRadius.circular(2.0),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: fillPercent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2.0),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Story author header details
            Positioned(
              top: MediaQuery.of(context).padding.top + 20.0,
              left: 14.0,
              right: 14.0,
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18.0,
                    backgroundColor: AppColors.primary,
                    backgroundImage:
                        story.authorAvatarUrl != null &&
                            story.authorAvatarUrl!.isNotEmpty
                        ? NetworkImage(
                            Helpers.resolveImageUrl(story.authorAvatarUrl!) ??
                                '',
                          )
                        : null,
                    child:
                        story.authorAvatarUrl == null ||
                            story.authorAvatarUrl!.isEmpty
                        ? Text(
                            story.authorName.isNotEmpty
                                ? story.authorName[0].toUpperCase()
                                : 'U',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          story.authorName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 13.5,
                          ),
                        ),
                        Text(
                          Helpers.formatRelativeDate(story.createdAt),
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isMine)
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: Colors.white,
                        size: 22.0,
                      ),
                      onPressed: () {
                        Get.defaultDialog(
                          title: 'Delete Story?',
                          middleText: 'This photo will be removed immediately.',
                          textConfirm: 'Delete',
                          textCancel: 'Cancel',
                          confirmTextColor: Colors.white,
                          buttonColor: AppColors.danger,
                          onConfirm: () {
                            Get.back();
                            controller.deleteStory(story.id);
                          },
                        );
                      },
                    ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 24.0,
                    ),
                    onPressed: controller.closeStoryViewer,
                  ),
                ],
              ),
            ),

            // Touch tap navigators (Left = prev, Right = next, Hold = pause)
            Positioned(
              top: 100.0,
              bottom: 100.0,
              left: 0,
              width: screenWidth * 0.4,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller.prevStory,
                onLongPressStart: (_) => controller.storyPaused.value = true,
                onLongPressEnd: (_) => controller.storyPaused.value = false,
              ),
            ),
            Positioned(
              top: 100.0,
              bottom: 100.0,
              right: 0,
              width: screenWidth * 0.4,
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                onTap: controller.nextStory,
                onLongPressStart: (_) => controller.storyPaused.value = true,
                onLongPressEnd: (_) => controller.storyPaused.value = false,
              ),
            ),

            // Bottom Footer
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16.0,
              left: 16.0,
              right: 16.0,
              child: isMine
                  ? Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14.0,
                            vertical: 8.0,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.visibility_outlined,
                                size: 16.0,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6.0),
                              Text(
                                '${story.viewCount} views',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Row(
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.18),
                              borderRadius: BorderRadius.circular(22.0),
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14.0,
                            ),
                            child: TextField(
                              controller: controller.storyReplyController,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.0,
                              ),
                              decoration: const InputDecoration(
                                hintText: 'Reply to story...',
                                hintStyle: TextStyle(color: Colors.white60),
                                border: InputBorder.none,
                              ),
                              onTap: () => controller.storyPaused.value = true,
                              onSubmitted: (val) {
                                controller.storyPaused.value = false;
                                controller.replyToStory(story.id);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        ...['❤️', '😂', '🔥'].map((emoji) {
                          return InkWell(
                            onTap: () =>
                                controller.reactToStory(story.id, emoji),
                            borderRadius: BorderRadius.circular(20.0),
                            child: Padding(
                              padding: const EdgeInsets.all(6.0),
                              child: Text(
                                emoji,
                                style: const TextStyle(fontSize: 24.0),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyRewardDialog() {
    final streak = controller.dailyRewardData.value!['streak_day'] ?? 1;
    final coins = controller.dailyRewardData.value!['coins_awarded'] ?? 5;

    return Container(
      color: Colors.black87,
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.all(24.0),
        padding: const EdgeInsets.all(24.0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(colors: AppColors.primaryGradient),
              ),
              child: const Icon(Icons.gif_box, size: 36.0, color: Colors.white),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Daily Login Rewards 🎁',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 20.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8.0),
            Text(
              'Day $streak Claimed successfully! You received:',
              style: const TextStyle(color: AppColors.text, fontSize: 13.0),
            ),
            const SizedBox(height: 12.0),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              decoration: BoxDecoration(
                color: AppColors.surfaceAlt,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cookie, color: AppColors.primary),
                  const SizedBox(width: 6.0),
                  Text(
                    '+$coins Coins',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(7, (i) {
                final int day = i + 1;
                final bool active = day <= streak;
                final int rewardAmt = day == 7 ? 50 : day * 5;
                return Expanded(
                  child: Column(
                    children: [
                      Container(
                        width: 28.0,
                        height: 28.0,
                        decoration: BoxDecoration(
                          color: active
                              ? AppColors.primary
                              : AppColors.muted.withAlpha(76),
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'D$day',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4.0),
                      Text(
                        '$rewardAmt🪙',
                        style: TextStyle(
                          color: active ? AppColors.primary : AppColors.muted,
                          fontSize: 8.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16.0),
            const Text(
              'Come back tomorrow to continue your streak! Day 7 gives 50 free coins!',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.muted, fontSize: 11.0),
            ),
            const SizedBox(height: 20.0),
            AppButton(
              title: 'Awesome!',
              onPressed: () {
                controller.dailyRewardOpen.value = false;
              },
            ),
          ],
        ),
      ),
    );
  }
}
