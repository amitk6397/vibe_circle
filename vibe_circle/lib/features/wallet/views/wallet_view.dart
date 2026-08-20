import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_dashboard_model.dart';
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
          final WalletDashboard dash = controller.dashboard.value ??
              WalletDashboard(currentCoins: authController.coins.value);
          final int currentCoins = dash.currentCoins > 0 ? dash.currentCoins : authController.coins.value;
          final int totalSpent = dash.totalSpent;
          final int totalEarned = dash.totalEarned;
          final int availableToWithdraw = dash.availableToWithdraw;
          final List<DashboardHistoryItem> history = dash.history;
          final List<ChartItem> chartData = dash.chart;
          final referral = controller.referralInfo.value;

          final String todayStr = DateTime.now().toIso8601String().split('T')[0];
          final ChartItem todayData = chartData.firstWhere(
            (item) => item.date == todayStr,
            orElse: () => chartData.isNotEmpty
                ? chartData.last
                : ChartItem(date: todayStr, earned: 0, spent: 0),
          );
          final int netCoins = todayData.earned - todayData.spent;

          final int maxChart = chartData.fold<int>(1, (max, item) {
            final int m = item.earned > item.spent ? item.earned : item.spent;
            return m > max ? m : max;
          });

          final List<ChartItem> visibleChart = controller.selectedDay.value != null
              ? chartData.where((item) => item.date == controller.selectedDay.value).toList()
              : chartData;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Period Filter Tabs (7d, 30d, 90d, all)
              Container(
                padding: const EdgeInsets.all(4.0),
                decoration: BoxDecoration(
                  color: AppColors.surfaceAlt,
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Row(
                  children: ['7d', '30d', '90d', 'all'].map((p) {
                    final bool isSel = controller.period.value == p;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => controller.changePeriod(p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.surface : Colors.transparent,
                            borderRadius: BorderRadius.circular(12.0),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.15),
                                      blurRadius: 4.0,
                                      offset: const Offset(0, 2),
                                    )
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            p == 'all' ? 'All' : p,
                            style: TextStyle(
                              color: isSel ? AppColors.primary : AppColors.muted,
                              fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
                              fontSize: 12.0,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16.0),

              // Available Balance Hero Gradient Card
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B6BD9), Color(0xFF5B5CE2)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24.0),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF5B5CE2).withValues(alpha: 0.3),
                      blurRadius: 16.0,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'AVAILABLE BALANCE',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 4.0),
                            Text(
                              '$currentCoins',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40.0,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const Text(
                              'coins ready to use',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12.0,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 48.0,
                          height: 48.0,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          alignment: Alignment.center,
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 26.0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20.0),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.SUBSCRIPTION_PLANS),
                            icon: const Icon(Icons.add_circle_outline, size: 18.0, color: Colors.white),
                            label: const Text('Add coins', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.22),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10.0),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Get.toNamed(AppRoutes.WITHDRAWAL),
                            icon: const Icon(Icons.arrow_upward_outlined, size: 18.0, color: Colors.white),
                            label: const Text('Withdraw', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white.withValues(alpha: 0.22),
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.0)),
                              padding: const EdgeInsets.symmetric(vertical: 12.0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // 3 Metrics Cards Row (Spent, Earned, Withdrawable)
              Row(
                children: [
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.arrow_downward,
                      color: AppColors.danger,
                      label: 'Spent',
                      value: '$totalSpent',
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.trending_up,
                      color: AppColors.success,
                      label: 'Earned',
                      value: '$totalEarned',
                    ),
                  ),
                  const SizedBox(width: 8.0),
                  Expanded(
                    child: _buildMetricCard(
                      icon: Icons.monetization_on_outlined,
                      color: const Color(0xFF0284C7),
                      label: 'Withdrawable',
                      value: '$availableToWithdraw',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16.0),

              // Coin Activity Chart Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with title and legend
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Coin activity', style: AppTextStyles.h2),
                            Text('Earned vs spent', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                          ],
                        ),
                        Row(
                          children: [
                            Container(width: 8.0, height: 8.0, decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle)),
                            const SizedBox(width: 4.0),
                            const Text('Earned', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                            const SizedBox(width: 10.0),
                            Container(width: 8.0, height: 8.0, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                            const SizedBox(width: 4.0),
                            const Text('Spent', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16.0),

                    // Today's Status Ring & Bars Row
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceAlt,
                        borderRadius: BorderRadius.circular(16.0),
                      ),
                      child: Row(
                        children: [
                          // Donut Ring
                          Container(
                            width: 72.0,
                            height: 72.0,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: netCoins >= 0 ? AppColors.success : AppColors.primary,
                                width: 4.0,
                              ),
                            ),
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  '${netCoins >= 0 ? '+' : ''}$netCoins',
                                  style: TextStyle(
                                    color: netCoins >= 0 ? AppColors.success : AppColors.primary,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 14.0,
                                  ),
                                ),
                                const Text('Net Coins', style: TextStyle(color: AppColors.muted, fontSize: 9.0)),
                              ],
                            ),
                          ),
                          const SizedBox(width: 14.0),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  todayData.date.isNotEmpty ? todayData.date : todayStr,
                                  style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 13.0),
                                ),
                                const SizedBox(height: 8.0),
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_upward, color: AppColors.success, size: 14.0),
                                    const SizedBox(width: 4.0),
                                    Text('Earned: +${todayData.earned} coins', style: const TextStyle(color: AppColors.success, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 4.0),
                                Row(
                                  children: [
                                    const Icon(Icons.arrow_downward, color: AppColors.primary, size: 14.0),
                                    const SizedBox(width: 4.0),
                                    Text('Spent: -${todayData.spent} coins', style: const TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16.0),

                    // Day Filter Chips Horizontal List
                    if (chartData.isNotEmpty) ...[
                      SizedBox(
                        height: 32.0,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            GestureDetector(
                              onTap: () => controller.selectedDay.value = null,
                              child: Container(
                                margin: const EdgeInsets.only(right: 6.0),
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                decoration: BoxDecoration(
                                  color: controller.selectedDay.value == null ? AppColors.primary : AppColors.surfaceAlt,
                                  borderRadius: BorderRadius.circular(16.0),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'All days',
                                  style: TextStyle(
                                    color: controller.selectedDay.value == null ? Colors.white : AppColors.muted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            ...chartData.map((item) {
                              final String dateStr = item.date;
                              final bool isSel = controller.selectedDay.value == dateStr;
                              return GestureDetector(
                                onTap: () => controller.selectedDay.value = dateStr,
                                child: Container(
                                  margin: const EdgeInsets.only(right: 6.0),
                                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                                  decoration: BoxDecoration(
                                    color: isSel ? AppColors.primary : AppColors.surfaceAlt,
                                    borderRadius: BorderRadius.circular(16.0),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    dateStr.length >= 5 ? dateStr.substring(5) : dateStr,
                                    style: TextStyle(
                                      color: isSel ? Colors.white : AppColors.muted,
                                      fontSize: 11.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                    ],

                    // Vertical Columns Graph
                    if (visibleChart.isNotEmpty) ...[
                      SizedBox(
                        height: 130.0,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: visibleChart.map((item) {
                            final double earnedHeight = (item.earned / maxChart) * 90.0;
                            final double spentHeight = (item.spent / maxChart) * 90.0;
                            final String dateStr = item.date;

                            return Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 8.0,
                                        height: earnedHeight.clamp(6.0, 90.0),
                                        decoration: BoxDecoration(
                                          color: AppColors.success,
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                      ),
                                      const SizedBox(width: 3.0),
                                      Container(
                                        width: 8.0,
                                        height: spentHeight.clamp(6.0, 90.0),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary,
                                          borderRadius: BorderRadius.circular(4.0),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6.0),
                                  Text(
                                    dateStr.length >= 5 ? dateStr.substring(5) : dateStr,
                                    style: const TextStyle(color: AppColors.muted, fontSize: 9.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Refer & Earn 🎁 Card
              if (referral != null) ...[
                AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.card_giftcard, color: AppColors.primary, size: 20.0),
                          SizedBox(width: 8.0),
                          Text('Refer & Earn 🎁', style: TextStyle(color: AppColors.primary, fontSize: 16.0, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        'Share your referral code. You earn ${referral.rewardPerReferral} coins for each friend who joins, and they get ${referral.inviteeBonus} bonus coins too!',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.0, height: 1.4),
                      ),
                      const SizedBox(height: 14.0),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(14.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              referral.referralCode.isNotEmpty ? referral.referralCode : 'VIBE2026',
                              style: const TextStyle(color: AppColors.text, fontSize: 16.0, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                            ),
                            ElevatedButton.icon(
                              onPressed: () {
                                final code = referral.referralCode;
                                Clipboard.setData(ClipboardData(text: code));
                                Get.snackbar('Copied!', 'Referral code $code copied to clipboard.');
                              },
                              icon: const Icon(Icons.copy, size: 15.0, color: Colors.white),
                              label: const Text('Copy Code', style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14.0),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              children: [
                                Text('${referral.totalReferrals}', style: const TextStyle(color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.w900)),
                                const Text('Referrals', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                              ],
                            ),
                          ),
                          Container(width: 1.0, height: 24.0, color: AppColors.border),
                          Expanded(
                            child: Column(
                              children: [
                                Text('+${referral.totalEarned}', style: const TextStyle(color: AppColors.success, fontSize: 18.0, fontWeight: FontWeight.w900)),
                                const Text('Coins Earned', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16.0),
              ],

              // Balance Breakdown Card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Balance breakdown', style: AppTextStyles.h2),
                    const SizedBox(height: 12.0),
                    _buildBreakdownRow('Purchased coins', dash.purchasedCoins > 0 ? dash.purchasedCoins : currentCoins, const Color(0xFF38BDF8)),
                    _buildBreakdownRow('Bonus coins', dash.bonusCoins, const Color(0xFFF59E0B)),
                    _buildBreakdownRow('Pending earnings', dash.pendingEarnings, const Color(0xFFEAB308)),
                    _buildBreakdownRow('Held in sessions', dash.heldCoins, AppColors.primary),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Recent History Section
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
                          children: [
                            ...history.take(10).map((item) {
                              final int amt = item.amount;
                              final bool isEarned = amt > 0;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8.0),
                                child: AppCard(
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38.0,
                                        height: 38.0,
                                        decoration: BoxDecoration(
                                          color: isEarned ? AppColors.success.withValues(alpha: 0.15) : AppColors.primary.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        alignment: Alignment.center,
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
                                              item.title.isNotEmpty ? item.title : item.type.replaceAll('_', ' '),
                                              style: const TextStyle(color: AppColors.text, fontSize: 13.5, fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 2.0),
                                            Text(
                                              '${item.createdAt.isNotEmpty ? item.createdAt.split('T')[0] : 'Recent'} · ${item.status}',
                                              style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${isEarned ? '+' : ''}$amt',
                                        style: TextStyle(
                                          color: isEarned ? AppColors.success : AppColors.text,
                                          fontWeight: FontWeight.w900,
                                          fontSize: 14.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                            const SizedBox(height: 8.0),
                            AppButton(
                              title: 'View all transactions',
                              tone: AppButtonTone.ghost,
                              onPressed: () => Get.toNamed(AppRoutes.TRANSACTION_HISTORY),
                            ),
                          ],
                        )
                      : const AppEmptyState(
                          icon: Icons.receipt_long_outlined,
                          title: 'No activity yet',
                          text: 'Your coin transactions and earnings will appear here.',
                        ),
              const SizedBox(height: 20.0),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required Color color,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Icon(icon, color: color, size: 16.0),
          ),
          const SizedBox(height: 10.0),
          Text(
            value,
            style: const TextStyle(color: AppColors.text, fontSize: 18.0, fontWeight: FontWeight.w900),
          ),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 11.0)),
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, dynamic value, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(width: 8.0, height: 8.0, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          const SizedBox(width: 10.0),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.text, fontSize: 13.0))),
          Text('$value', style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 13.0)),
        ],
      ),
    );
  }
}
