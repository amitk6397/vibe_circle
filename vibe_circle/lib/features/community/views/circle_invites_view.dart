import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_animated_loader.dart';
import '../controllers/community_controller.dart';

class CircleInvitesView extends GetView<CommunityController> {
  const CircleInvitesView({super.key});

  Future<void> _respond(Map invite, String action) async {
    try {
      await controller.respondCircleInvite(invite['id'].toString(), action);
      if (action == 'accept') {
        await controller.loadCommunities();
        Get.toNamed('/community-details', arguments: {'communityId': invite['community_id']});
      }
    } catch (e) {
      Get.snackbar('Error', 'Could not respond to invitation: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    controller.loadCircleInvites();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: const Text('Circle invitations', style: AppTextStyles.title),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const AppAnimatedLoader();
        }

        if (controller.circleInvitesList.isEmpty) {
          return const _EmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.circleInvitesList.length,
          itemBuilder: (context, index) {
            final invite = controller.circleInvitesList[index] as Map;
            return _InviteCard(
              invite: invite,
              onAccept: () => _respond(invite, 'accept'),
              onDecline: () => _respond(invite, 'reject'),
            );
          },
        );
      }),
    );
  }
}

class _InviteCard extends StatelessWidget {
  final Map invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _InviteCard({required this.invite, required this.onAccept, required this.onDecline});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(invite['community_name']?.toString() ?? 'Unknown Circle', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            '${invite['inviter_name'] ?? 'Someone'} invited you to a private circle.',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onDecline,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.border),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Decline', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: onAccept,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Accept', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.mail_outline, size: 64, color: AppColors.muted),
            SizedBox(height: 16),
            Text('No invitations', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text('Private circle invitations will appear here.', style: TextStyle(color: AppColors.muted), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
