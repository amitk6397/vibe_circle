import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../discovery/controllers/discovery_controller.dart';

class ConnectView extends StatelessWidget {
  const ConnectView({super.key});

  @override
  Widget build(BuildContext context) {
    final DiscoveryController discoveryCtrl = Get.find<DiscoveryController>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              // Connect Hero
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(32),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.4),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.radio, size: 46, color: Colors.white),
                    ),
                    const SizedBox(height: 20),
                    const Text('Instant Connect', style: AppTextStyles.title),
                    const SizedBox(height: 8),
                    Text(
                      'Both people accept before a private conversation starts. You stay in control.',
                      style: AppTextStyles.body.copyWith(color: AppColors.muted),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),

              // Current Purpose Card
              Obx(() {
                final selected = discoveryCtrl.selectedPurpose.value;
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CURRENT PURPOSE',
                        style: AppTextStyles.caption.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(selected, style: AppTextStyles.title),
                      const SizedBox(height: 4),
                      Text(
                        'English · Ages 18–35 · Available now',
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                      ),
                    ],
                  ),
                );
              }),
              const SizedBox(height: 24),

              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => Get.toNamed('/connect-setup'),
                  icon: const Icon(Icons.tune, color: Colors.white),
                  label: const Text('Set up a connection', style: AppTextStyles.buttonText),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Safety disclaimer
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shield_outlined, color: Colors.green, size: 22),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Blocked and restricted accounts are excluded. Private conversation content is never used for relevant suggestions.',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted, height: 1.4),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
