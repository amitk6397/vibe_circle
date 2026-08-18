import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../community/widgets/post_card.dart';
import '../../discovery/models/person.dart';
import '../../../routes/app_routes.dart';

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
                              // Upload story item button
                              GestureDetector(
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
                                          Builder(
                                            builder: (context) {
                                              final currentAvatar =
                                                  authController
                                                      .profile
                                                      .value
                                                      ?.avatarUrl;
                                              return Container(
                                                width: 50.0,
                                                height: 50.0,
                                                decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: AppColors.primary,
                                                    width: 1.8,
                                                  ),
                                                  image: currentAvatar != null
                                                      ? DecorationImage(
                                                          image: NetworkImage(
                                                            currentAvatar,
                                                          ),
                                                          fit: BoxFit.cover,
                                                        )
                                                      : null,
                                                ),
                                                child: currentAvatar == null
                                                    ? const Icon(
                                                        Icons.person,
                                                        color: AppColors.muted,
                                                        size: 28.0,
                                                      )
                                                    : null,
                                              );
                                            },
                                          ),
                                          Positioned(
                                            bottom: 0,
                                            right: 0,
                                            child: Container(
                                              width: 16.0,
                                              height: 16.0,
                                              decoration: const BoxDecoration(
                                                color: AppColors.primary,
                                                shape: BoxShape.circle,
                                              ),
                                              alignment: Alignment.center,
                                              child: const Icon(
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
                                        'You',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 10.0,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Map story owners
                              ...controller.stories.map((story) {
                                final String authorId = story['author_id'];
                                final String name = story['author_name'];
                                final bool viewed = story['viewed'];
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
                                            border: Border.all(
                                              color: viewed
                                                  ? AppColors.muted
                                                  : AppColors.primary,
                                              width: 1.8,
                                            ),
                                          ),
                                          padding: const EdgeInsets.all(2.0),
                                          child: CircleAvatar(
                                            backgroundColor:
                                                AppColors.surfaceAlt,
                                            backgroundImage: NetworkImage(
                                              story['media_url'],
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
                                AppAvatar(
                                  name:
                                      authController.profile.value?.name ??
                                      'You',
                                  avatarUrl:
                                      authController.profile.value?.avatarUrl,
                                  size: 44.0,
                                ),
                                const SizedBox(width: 10.0),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
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
                                  onTap: () =>
                                      Get.toNamed(AppRoutes.SUBSCRIPTION_PLANS),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8.0,
                                      vertical: 5.0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.surfaceAlt,
                                      borderRadius: BorderRadius.circular(16.0),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(3.0),
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: AppColors.primaryGradient,
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
                                          controller.notificationsCount.value >
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
                                physics: const AlwaysScrollableScrollPhysics(),
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
                                            discoveryController.people.length >
                                                6
                                            ? 6
                                            : discoveryController.people.length,
                                        itemBuilder: (context, idx) {
                                          final person =
                                              discoveryController.people[idx];
                                          return _buildRecommendedCard(person);
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

                                    if (communityController.posts.isEmpty)
                                      const AppEmptyState(
                                        icon: Icons.article_outlined,
                                        title: 'No posts yet',
                                        text:
                                            'Join a community and create the first post.',
                                      )
                                    else
                                      ...communityController.posts.map((post) {
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

            // 3. Floating handle to slide stories open/closed
            if (!controller.storyRailOpen.value)
              Positioned(
                left: controller.storyRailSide.value == 'left' ? 0.0 : null,
                right: controller.storyRailSide.value == 'right' ? 0.0 : null,
                top: controller.storyHandleY.value,
                child: GestureDetector(
                  onVerticalDragUpdate: (details) {
                    controller.storyHandleY.value =
                        (details.globalPosition.dy - 45.0).clamp(
                          56.0,
                          MediaQuery.of(context).size.height - 210.0,
                        );
                  },
                  onHorizontalDragEnd: (details) {
                    // Switch side if dragged past center
                    if (details.primaryVelocity != null) {
                      if (details.primaryVelocity! > 300) {
                        controller.storyRailSide.value = 'right';
                      } else if (details.primaryVelocity! < -300) {
                        controller.storyRailSide.value = 'left';
                      }
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
          ],
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              backgroundColor: AppColors.primary,
              shape: const CircleBorder(),
              onPressed: () {
                Get.bottomSheet(
                  Container(
                    color: AppColors.surface,
                    padding: const EdgeInsets.all(20.0),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ListTile(
                            leading: const Icon(
                              Icons.people,
                              color: AppColors.text,
                            ),
                            title: const Text(
                              'Create community',
                              style: TextStyle(color: AppColors.text),
                            ),
                            onTap: () {
                              Get.back();
                              Get.toNamed(AppRoutes.CREATE_COMMUNITY);
                            },
                          ),
                          ListTile(
                            leading: const Icon(
                              Icons.create,
                              color: AppColors.text,
                            ),
                            title: const Text(
                              'Create post',
                              style: TextStyle(color: AppColors.text),
                            ),
                            onTap: () {
                              Get.back();
                              Get.toNamed(AppRoutes.CREATE_POST);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
              child: const Icon(Icons.add, size: 28.0, color: Colors.white),
            ),
          ],
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
                  ? Image.network(person.avatarUrl!, fit: BoxFit.cover)
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
        .where((s) => s['author_id'] == controller.activeStoryOwner.value)
        .toList();
    final story = authorStories[controller.activeStoryIndex.value!];

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Story Image Content
          Positioned.fill(
            child: Image.network(story['media_url'], fit: BoxFit.contain),
          ),

          // Shadows overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.black.withAlpha(204),
                    Colors.transparent,
                    Colors.black.withAlpha(204),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // Emojis burst burst text
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

          // Progress lines
          Positioned(
            top: 50.0,
            left: 16.0,
            right: 16.0,
            child: Row(
              children: List.generate(authorStories.length, (idx) {
                double fillPercent = 0.0;
                if (idx < controller.activeStoryIndex.value!) {
                  fillPercent = 1.0;
                } else if (idx == controller.activeStoryIndex.value!) {
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
                          color: AppColors.primary,
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
            top: 64.0,
            left: 16.0,
            right: 16.0,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18.0,
                  backgroundImage:
                      story['author_avatar_url'] != null &&
                          story['author_avatar_url'].isNotEmpty
                      ? NetworkImage(story['author_avatar_url'])
                      : null,
                  child:
                      story['author_avatar_url'] == null ||
                          story['author_avatar_url'].isEmpty
                      ? const Icon(Icons.person, color: Colors.white, size: 18)
                      : null,
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        story['author_name'],
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13.0,
                        ),
                      ),
                      Text(
                        'Uploaded recently',
                        style: TextStyle(
                          color: Colors.white.withAlpha(168),
                          fontSize: 10.0,
                        ),
                      ),
                    ],
                  ),
                ),
                if (story['mine'] == true)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.white),
                    onPressed: () {
                      controller.deleteStory(story['id']);
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: controller.closeStoryViewer,
                ),
              ],
            ),
          ),

          // Touch tap navigators
          Positioned(
            top: 120.0,
            bottom: 120.0,
            left: 0,
            width: screenWidth * 0.4,
            child: GestureDetector(
              onTap: controller.prevStory,
              onLongPressStart: (_) => controller.storyPaused.value = true,
              onLongPressEnd: (_) => controller.storyPaused.value = false,
            ),
          ),
          Positioned(
            top: 120.0,
            bottom: 120.0,
            right: 0,
            width: screenWidth * 0.4,
            child: GestureDetector(
              onTap: controller.nextStory,
              onLongPressStart: (_) => controller.storyPaused.value = true,
              onLongPressEnd: (_) => controller.storyPaused.value = false,
            ),
          ),

          // Interactive Reply Footer Bar
          Positioned(
            bottom: 24.0,
            left: 16.0,
            right: 16.0,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white12,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
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
                        if (val.trim().isNotEmpty) {
                          controller.storyReplyController.clear();
                          Get.snackbar(
                            'Reply sent! 🚀',
                            'Your response has been delivered.',
                          );
                        }
                      },
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                ...['❤️', '😂', '🔥'].map((emoji) {
                  return IconButton(
                    icon: Text(emoji, style: const TextStyle(fontSize: 22.0)),
                    onPressed: () => controller.reactToStory(emoji),
                  );
                }),
              ],
            ),
          ),
        ],
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
