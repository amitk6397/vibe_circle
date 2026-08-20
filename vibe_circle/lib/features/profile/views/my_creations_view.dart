import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class MyCreationsView extends StatefulWidget {
  const MyCreationsView({super.key});

  @override
  State<MyCreationsView> createState() => _MyCreationsViewState();
}

class _MyCreationsViewState extends State<MyCreationsView> with SingleTickerProviderStateMixin {
  String _tab = 'posts';
  late AnimationController _tabIndicatorController;
  late Animation<double> _indicatorAnim;
  bool _fabOpen = false;
  late AnimationController _fabController;

  // In real app: get from AppController
  final List _myPosts = [];
  final List _myCommunities = [];

  @override
  void initState() {
    super.initState();
    _tabIndicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _indicatorAnim = CurvedAnimation(parent: _tabIndicatorController, curve: Curves.easeInOut);
    _fabController = AnimationController(vsync: this, duration: const Duration(milliseconds: 200));
  }

  @override
  void dispose() {
    _tabIndicatorController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _switchTab(String tab) {
    setState(() => _tab = tab);
    if (tab == 'posts') {
      _tabIndicatorController.reverse();
    } else {
      _tabIndicatorController.forward();
    }
  }

  void _toggleFab() {
    setState(() => _fabOpen = !_fabOpen);
    if (_fabOpen) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('My Creations', style: AppTextStyles.titleMedium),
            Text(
              'Your posts & communities',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Animated Tab Bar
              Container(
                color: AppColors.surface,
                child: Stack(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchTab('posts'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: Text(
                                'Posts (${_myPosts.length})',
                                style: AppTextStyles.button.copyWith(
                                  color: _tab == 'posts' ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _switchTab('communities'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              alignment: Alignment.center,
                              child: Text(
                                'Communities (${_myCommunities.length})',
                                style: AppTextStyles.button.copyWith(
                                  color: _tab == 'communities' ? Colors.white : AppColors.textMuted,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Tab indicator
                    AnimatedBuilder(
                      animation: _indicatorAnim,
                      builder: (context, _) {
                        return Positioned(
                          bottom: 0,
                          left: _indicatorAnim.value * screenWidth / 2,
                          child: Container(
                            width: screenWidth / 2,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              // Content
              Expanded(
                child: _tab == 'posts'
                    ? _buildPostsTab()
                    : _buildCommunitiesTab(),
              ),
            ],
          ),
          // FAB
          Positioned(
            bottom: 24,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Sub-button
                AnimatedBuilder(
                  animation: _fabController,
                  builder: (context, _) {
                    return Transform.translate(
                      offset: Offset(0, (1 - _fabController.value) * 20),
                      child: Opacity(
                        opacity: _fabController.value,
                        child: _fabController.value > 0.01
                            ? Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.surface,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: AppColors.border),
                                      ),
                                      child: Text(
                                        _tab == 'posts' ? 'New Post' : 'New Community',
                                        style: AppTextStyles.caption.copyWith(color: Colors.white),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    GestureDetector(
                                      onTap: () {
                                        _toggleFab();
                                        Get.toNamed(_tab == 'posts' ? '/create-post' : '/create-community');
                                      },
                                      child: Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: _tab == 'posts' ? Colors.green : AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          _tab == 'posts' ? Icons.article_outlined : Icons.people_outlined,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    );
                  },
                ),
                // Main FAB
                GestureDetector(
                  onTap: _toggleFab,
                  child: AnimatedBuilder(
                    animation: _fabController,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _fabController.value * 3.14159 / 4,
                        child: Container(
                          width: 58,
                          height: 58,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.primary, AppColors.accent],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 28),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsTab() {
    if (_myPosts.isEmpty) {
      return _EmptyState(
        icon: Icons.article_outlined,
        title: 'No posts yet',
        text: 'Tap + to create your first post.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _myPosts.length,
      itemBuilder: (context, index) {
        final post = _myPosts[index] as Map;
        return _PostCreationCard(post: post);
      },
    );
  }

  Widget _buildCommunitiesTab() {
    if (_myCommunities.isEmpty) {
      return _EmptyState(
        icon: Icons.people_outline,
        title: 'No communities yet',
        text: 'Tap + to create your first community.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _myCommunities.length,
      itemBuilder: (context, index) {
        final community = _myCommunities[index] as Map;
        return _CommunityCreationCard(community: community);
      },
    );
  }
}

class _PostCreationCard extends StatelessWidget {
  final Map post;
  const _PostCreationCard({required this.post});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.article, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  post['body']?.toString() ?? '',
                  style: AppTextStyles.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.favorite_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${post['likes'] ?? 0}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                    const SizedBox(width: 12),
                    const Icon(Icons.chat_bubble_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Text('${post['comments'] ?? 0}', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textMuted),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _CommunityCreationCard extends StatelessWidget {
  final Map community;
  const _CommunityCreationCard({required this.community});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.3),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Text(community['name']?.toString() ?? '', style: AppTextStyles.titleSmall),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.visibility_outlined, color: AppColors.textMuted, size: 20),
                  onPressed: () => Get.toNamed('/community-details', arguments: {'communityId': community['id']}),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppColors.textMuted, size: 20),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _EmptyState({required this.icon, required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text(title, style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(text, style: AppTextStyles.body.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
