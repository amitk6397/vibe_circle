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
import '../../../routes/app_routes.dart';
import '../controllers/connection_request_controller.dart';
import '../models/connection_request_model.dart';

class ConnectionRequestView extends GetView<ConnectionRequestController> {
  const ConnectionRequestView({super.key});

  @override
  Widget build(BuildContext context) {
    final ConnectionRequestController c =
        Get.isRegistered<ConnectionRequestController>()
        ? Get.find<ConnectionRequestController>()
        : Get.put(ConnectionRequestController());

    return AppScreen(
      header: AppHeader(
        title: 'Follow requests',
        subtitle: 'People who want to follow you',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          if (c.loading.value && c.requests.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (c.error.value.isNotEmpty && c.requests.isEmpty) {
            return AppEmptyState(
              icon: Icons.cloud_off,
              title: 'Could not load requests',
              text: c.error.value,
              action: 'Try again',
              onAction: () => c.loadRequests(),
            );
          }

          if (c.requests.isEmpty) {
            return const AppEmptyState(
              icon: Icons.people_outline,
              title: 'No pending requests',
              text: 'New follow requests will appear here.',
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: c.requests
                .map((item) => _buildRequestCard(c, item))
                .toList(),
          );
        }),
      ),
    );
  }

  Widget _buildRequestCard(
    ConnectionRequestController c,
    ConnectionRequestItem item,
  ) {
    final bool isBusyAccept = c.busyAction.value == '${item.id}:accept';
    final bool isBusyReject = c.busyAction.value == '${item.id}:reject';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // User Header Row
            InkWell(
              onTap: () => Get.toNamed(
                AppRoutes.PUBLIC_PROFILE,
                arguments: {'personId': item.requesterId},
              ),
              child: Row(
                children: [
                  AppAvatar(
                    name: item.requesterName,
                    uri: item.requesterAvatar,
                    size: 48.0,
                  ),
                  const SizedBox(width: 14.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.requesterName,
                          style: AppTextStyles.subtitle.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item.requesterCity != null &&
                            item.requesterCity!.isNotEmpty)
                          Text(
                            item.requesterCity!,
                            style: AppTextStyles.caption.copyWith(
                              color: AppColors.muted,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            if (item.requesterBio.isNotEmpty) ...[
              const SizedBox(height: 10.0),
              Text(
                item.requesterBio,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13.0,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            if (item.requesterInterests.isNotEmpty) ...[
              const SizedBox(height: 8.0),
              Wrap(
                spacing: 6.0,
                runSpacing: 4.0,
                children: item.requesterInterests.take(4).map((interest) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8.0,
                      vertical: 2.0,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      interest,
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 10.5,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 14.0),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: 'Accept',
                    compact: true,
                    loading: isBusyAccept,
                    disabled: c.busyAction.value.isNotEmpty,
                    onPressed: () => c.respond(item, 'accept'),
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: AppButton(
                    title: 'Reject',
                    compact: true,
                    tone: AppButtonTone.secondary,
                    loading: isBusyReject,
                    disabled: c.busyAction.value.isNotEmpty,
                    onPressed: () => c.respond(item, 'reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
