import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../controllers/discovery_controller.dart';
import '../../community/controllers/community_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/widgets/app_search_field.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_pill.dart';
import '../../community/widgets/post_card.dart';
import '../widgets/person_grid_card.dart';
import '../../community/widgets/community_grid_card.dart';
import '../../../routes/app_routes.dart';

class DiscoverView extends StatefulWidget {
  const DiscoverView({super.key});

  @override
  State<DiscoverView> createState() => _DiscoverViewState();
}

class _DiscoverViewState extends State<DiscoverView> {
  final DiscoveryController _discoveryController = Get.find<DiscoveryController>();
  final CommunityController _communityController = Get.find<CommunityController>();
  final AuthController _authController = Get.find<AuthController>();
  final TextEditingController _searchController = TextEditingController();
  String _query = '';
  String _activeTab = 'people'; // 'people' | 'communities' | 'posts'

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      scroll: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'DISCOVER',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 10.0,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      'Find your circle',
                      style: AppTextStyles.title,
                    ),
                  ],
                ),
                // Action IconButton
                if (_activeTab == 'people')
                  AppIconButton(
                    icon: Icons.tune,
                    onPressed: () => Get.toNamed(AppRoutes.SEARCH_FILTERS),
                  )
                else
                  AppIconButton(
                    icon: Icons.add,
                    onPressed: () {
                      if (_activeTab == 'communities') {
                        Get.toNamed(AppRoutes.CREATE_COMMUNITY);
                      } else {
                        Get.toNamed(AppRoutes.CREATE_POST);
                      }
                    },
                  ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: AppSearchField(
              value: _query,
              controller: _searchController,
              placeholder: _activeTab == 'people'
                  ? 'Search people, interests...'
                  : _activeTab == 'communities'
                      ? 'Search communities, categories...'
                      : 'Search post text, authors...',
              onChanged: (val) {
                setState(() {
                  _query = val.trim();
                });
              },
            ),
          ),
          const SizedBox(height: 14.0),

          // Horizontal Navigation Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              children: [
                _buildTabPill('people', 'People'),
                const SizedBox(width: 8.0),
                _buildTabPill('communities', 'Communities'),
                const SizedBox(width: 8.0),
                _buildTabPill('posts', 'Posts'),
              ],
            ),
          ),
          const SizedBox(height: 16.0),

          // Tab content area
          Expanded(
            child: Obx(() {
              if (_discoveryController.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _buildTabContent(),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPill(String tab, String label) {
    final bool isSelected = _activeTab == tab;
    return AppPill(
      label: label,
      selected: isSelected,
      onPressed: () {
        setState(() {
          _activeTab = tab;
          _query = '';
          _searchController.clear();
        });
      },
    );
  }

  Widget _buildTabContent() {
    final String q = _query.toLowerCase();

    if (_activeTab == 'people') {
      final list = _discoveryController.people.where((p) {
        final matchesQuery = p.name.toLowerCase().contains(q) ||
            p.username.toLowerCase().contains(q) ||
            p.interests.any((tag) => tag.toLowerCase().contains(q));
        final isBlocked = _authController.blockedUsers.contains(p.id);
        return matchesQuery && !isBlocked;
      }).toList();

      if (list.isEmpty) {
        return const AppEmptyState(
          icon: Icons.person_off_outlined,
          title: 'No people found',
          text: 'Try searching other interest categories.',
        );
      }

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.0,
          crossAxisSpacing: 12.0,
          childAspectRatio: 0.72,
        ),
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final person = list[idx];
          return PersonGridCard(
            person: person,
            onPressed: () => Get.toNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': person.id}),
          );
        },
      );
    } else if (_activeTab == 'communities') {
      final list = _communityController.communities.where((c) {
        final isPrivateCircle = c.kind == 'circle' && c.privacy == 'private';
        final isJoinedOrOwner = c.joined == true || c.isOwner == true;
        if (isPrivateCircle && !isJoinedOrOwner) return false;

        return c.name.toLowerCase().contains(q) ||
            c.category.toLowerCase().contains(q) ||
            c.description.toLowerCase().contains(q);
      }).toList();

      if (list.isEmpty) {
        return const AppEmptyState(
          icon: Icons.group_off_outlined,
          title: 'No communities found',
          text: 'Try searching other categories or create one.',
        );
      }

      return GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12.0,
          crossAxisSpacing: 12.0,
          childAspectRatio: 0.72,
        ),
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final comm = list[idx];
          return CommunityGridCard(
            community: comm,
            onPressed: () => Get.toNamed(AppRoutes.COMMUNITY_DETAILS, arguments: {'communityId': comm.id}),
          );
        },
      );
    } else {
      final list = _communityController.posts.where((p) {
        return p.author.toLowerCase().contains(q) ||
            (p.authorUsername?.toLowerCase().contains(q) ?? false) ||
            p.community.toLowerCase().contains(q) ||
            p.body.toLowerCase().contains(q);
      }).toList();

      if (list.isEmpty) {
        return const AppEmptyState(
          icon: Icons.article_outlined,
          title: 'No posts found',
          text: 'Try searching other topics.',
        );
      }

      return ListView.builder(
        itemCount: list.length,
        itemBuilder: (context, idx) {
          final post = list[idx];
          return PostCard(
            post: post,
            onPressed: () => Get.toNamed(AppRoutes.POST_DETAILS, arguments: {'postId': post.id}),
          );
        },
      );
    }
  }
}
