import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_animated_loader.dart';
import '../controllers/profile_controller.dart';

class ReportsView extends GetView<ProfileController> {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context) {
    controller.loadReports();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('My reports', style: AppTextStyles.title),
            Text(
              'Track safety-team review status',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: Obx(() {
        if (controller.loading.value) {
          return const AppAnimatedLoader();
        }

        if (controller.error.isNotEmpty) {
          return _ErrorState(
            error: controller.error.value,
            onRetry: () => controller.loadReports(),
          );
        }

        if (controller.reports.isEmpty) {
          return const _EmptyState();
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: controller.reports.length,
          itemBuilder: (context, index) {
            final item = controller.reports[index] as Map;
            return _ReportCard(item: item);
          },
        );
      }),
    );
  }
}

class _ReportCard extends StatelessWidget {
  final Map item;
  const _ReportCard({required this.item});

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
          Text(item['reason']?.toString() ?? '', style: AppTextStyles.title),
          const SizedBox(height: 4),
          Text(
            '${(item['target_type']?.toString() ?? '').replaceAll('_', ' ')} · ${item['status'] ?? ''}',
            style: AppTextStyles.body.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            item['created_at'] != null
                ? DateTime.tryParse(item['created_at'].toString())?.toLocal().toString() ?? ''
                : '',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
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
            Icon(Icons.shield_outlined, size: 64, color: AppColors.muted),
            SizedBox(height: 16),
            Text('No reports', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'Reports you submit will appear here.',
              style: TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.muted),
            const SizedBox(height: 16),
            const Text('Reports unavailable', style: AppTextStyles.title),
            const SizedBox(height: 8),
            Text(error, style: AppTextStyles.body.copyWith(color: AppColors.muted), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
