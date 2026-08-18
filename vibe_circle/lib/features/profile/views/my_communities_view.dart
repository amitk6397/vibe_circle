import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../community/models/community.dart';

class MyCommunitiesView extends StatelessWidget {
  const MyCommunitiesView({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, filter communities by isOwner from controller/store
    final List<Community> communities = [];

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
            Text('My communities', style: AppTextStyles.titleMedium),
            Text(
              'Communities created and managed by you',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Get.toNamed('/create-community'),
          ),
        ],
      ),
      body: communities.isEmpty
          ? _EmptyState(onAction: () => Get.toNamed('/create-community'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: communities.length,
              itemBuilder: (context, index) {
                final community = communities[index];
                return _CommunityCard(
                  community: community,
                  onPress: () => Get.toNamed('/community-details', arguments: {'communityId': community.id}),
                );
              },
            ),
    );
  }
}

class _CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback onPress;
  const _CommunityCard({required this.community, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover header
            Container(
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.3),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: community.coverUrl != null
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      child: Image.network(community.coverUrl!, fit: BoxFit.cover, width: double.infinity),
                    )
                  : const SizedBox(),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary,
                    backgroundImage: community.logoUrl != null ? NetworkImage(community.logoUrl!) : null,
                    child: community.logoUrl == null
                        ? const Icon(Icons.people, color: Colors.white, size: 20)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(community.name, style: AppTextStyles.titleMedium),
                        Text(
                          '${community.members ?? 0} members',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: AppColors.textMuted),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAction;
  const _EmptyState({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people_outline, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No community created yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Create your first community and bring people together.',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Create community'),
            ),
          ],
        ),
      ),
    );
  }
}
