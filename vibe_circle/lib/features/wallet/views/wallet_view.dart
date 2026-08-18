import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/wallet_controller.dart';
import '../../../routes/app_routes.dart';

class WalletView extends GetView<WalletController> {
  const WalletView({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthController authController = Get.find<AuthController>();

    return AppScreen(
      header: AppHeader(
        title: 'Dashboard',
        subtitle: 'Your coins, earnings and activity',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          final int currentCoins = controller.dashboard['currentCoins'] ?? authController.coins.value;
          final int totalSpent = controller.dashboard['totalSpent'] ?? 0;
          final int totalEarned = controller.dashboard['totalEarned'] ?? 0;
          final int availableToWithdraw = controller.dashboard['availableToWithdraw'] ?? 0;
          final List history = controller.dashboard['history'] ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Filter Tabs
              Row(
                children: ['7d', '30d', '90d', 'all'].map((p) {
                  final bool isSel = controller.period.value == p;
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 6.0),
                      child: AppPill(
                        label: p == 'all' ? 'All' : p,
                        selected: isSel,
                        onPressed: () => controller.changePeriod(p),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16.0),

              // Hero Balance Card
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, Color(0xFF4F46E5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AVAILABLE BALANCE', style: TextStyle(color: Colors.white70, fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
                    const SizedBox(height: 4.0),
                    Text('$currentCoins', style: const TextStyle(color: Colors.white, fontSize: 40.0, fontWeight: FontWeight.w900)),
                    const Text('coins ready to use', style: TextStyle(color: Colors.white70, fontSize: 12.0)),
                    const SizedBox(height: 20.0),

                    Row(
                      children: [
                        Expanded(
                          child: AppButton(
                            title: 'Add coins',
                            tone: AppButtonTone.secondary,
                            onPressed: () => Get.toNamed(AppRoutes.SUBSCRIPTION_PLANS),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: AppButton(
                            title: 'Withdraw',
                            tone: AppButtonTone.secondary,
                            onPressed: () => Get.toNamed(AppRoutes.WITHDRAWAL),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Metrics Row
              Row(
                children: [
                  Expanded(child: _buildMetric(Icons.arrow_downward, AppColors.danger, 'Spent', '$totalSpent')),
                  const SizedBox(width: 8.0),
                  Expanded(child: _buildMetric(Icons.trending_up, AppColors.success, 'Earned', '$totalEarned')),
                  const SizedBox(width: 8.0),
                  Expanded(child: _buildMetric(Icons.account_balance_wallet, Colors.lightBlue, 'Withdrawable', '$availableToWithdraw')),
                ],
              ),
              const SizedBox(height: 20.0),

              // Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Recent history', style: AppTextStyles.h2),
                  Text('${history.length} activities', style: const TextStyle(color: AppColors.muted, fontSize: 11.5)),
                ],
              ),
              const SizedBox(height: 10.0),

              controller.loading.value
                  ? const Center(child: CircularProgressIndicator())
                  : history.isNotEmpty
                      ? Column(
                          children: history.take(10).map((item) {
                            final int amt = item['amount'] ?? 0;
                            final bool isEarned = amt > 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: AppCard(
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: isEarned ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                                      child: Icon(
                                        isEarned ? Icons.arrow_downward : Icons.arrow_upward,
                                        color: isEarned ? AppColors.success : AppColors.primary,
                                        size: 18.0,
                                      ),
                                    ),
                                    const SizedBox(width: 12.0),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item['title'] ?? item['type'] ?? 'Transaction',
                                            style: const TextStyle(color: AppColors.text, fontSize: 13.5, fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 2.0),
                                          Text(
                                            item['status'] ?? 'completed',
                                            style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '${isEarned ? '+' : ''}$amt',
                                      style: TextStyle(
                                        color: isEarned ? AppColors.success : AppColors.text,
                                        fontSize: 15.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        )
                      : const AppEmptyState(
                          icon: Icons.history,
                          title: 'No activity',
                          text: 'Your coin and earning history will appear here.',
                        ),
              const SizedBox(height: 30.0),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMetric(IconData icon, Color color, String label, String value) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20.0),
          const SizedBox(height: 6.0),
          Text(value, style: const TextStyle(color: AppColors.text, fontSize: 16.0, fontWeight: FontWeight.bold)),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10.0)),
        ],
      ),
    );
  }
}
