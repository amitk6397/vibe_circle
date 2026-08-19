import 'package:dating_app/core/utils/helpers.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../community/models/community.dart';

class PrivateCirclesView extends StatelessWidget {
  const PrivateCirclesView({super.key});

  @override
  Widget build(BuildContext context) {
    // In a real app, filter from store: kind == 'circle' && joined
    final List<Community> circles = [];

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
            Text('Private circles', style: AppTextStyles.titleMedium),
            Text(
              'Small trusted spaces that only members can see',
              style: AppTextStyles.caption.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () => Get.toNamed('/create-circle'),
          ),
        ],
      ),
      body: Column(
        children: [
          // Circle invitations button
          Padding(
            padding: const EdgeInsets.all(16),
            child: OutlinedButton.icon(
              onPressed: () => Get.toNamed('/circle-invites'),
              icon: const Icon(
                Icons.mark_email_unread_outlined,
                color: AppColors.primary,
              ),
              label: Text(
                'Circle invitations',
                style: AppTextStyles.button.copyWith(color: AppColors.primary),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
          Expanded(
            child: circles.isEmpty
                ? _EmptyState(onAction: () => Get.toNamed('/create-circle'))
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: circles.length,
                    itemBuilder: (context, index) {
                      final circle = circles[index];
                      return _CircleCard(
                        circle: circle,
                        onPress: () => Get.toNamed(
                          '/community-details',
                          arguments: {'communityId': circle.id},
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _CircleCard extends StatelessWidget {
  final Community circle;
  final VoidCallback onPress;
  const _CircleCard({required this.circle, required this.onPress});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPress,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.primary.withValues(alpha: 0.2),
              backgroundImage: circle.logoUrl != null
                  ? NetworkImage(Helpers.resolveImageUrl(circle.logoUrl!) ?? '')
                  : null,
              child: circle.logoUrl == null
                  ? const Icon(
                      Icons.lock_outline,
                      color: AppColors.primary,
                      size: 22,
                    )
                  : null,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(circle.name, style: AppTextStyles.titleSmall),
                  Text(
                    '${circle.members ?? 0} members',
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textMuted),
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
            const Icon(
              Icons.people_outline,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: 16),
            Text('No private circles yet', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Create an invite-only space for close friends, study partners or support.',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: const Text('Create circle'),
            ),
          ],
        ),
      ),
    );
  }
}
