import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/withdrawal_controller.dart';

class WithdrawalView extends GetView<WithdrawalController> {
  const WithdrawalView({super.key});

  @override
  Widget build(BuildContext context) {
    final WithdrawalController c = Get.isRegistered<WithdrawalController>()
        ? Get.find<WithdrawalController>()
        : Get.put(WithdrawalController());

    return AppScreen(
      header: AppHeader(
        title: 'Withdrawal',
        subtitle: 'Cash out your creator earnings',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Available balance card
              Container(
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF0284C7), Color(0xFF0369A1)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'AVAILABLE TO WITHDRAW',
                      style: TextStyle(color: Colors.white70, fontSize: 10.0, fontWeight: FontWeight.bold, letterSpacing: 1.2),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '\$${c.availableBalance.value.toStringAsFixed(2)}',
                      style: const TextStyle(color: Colors.white, fontSize: 36.0, fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Request form card
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text('Request payout', style: AppTextStyles.h2),
                    const SizedBox(height: 14.0),
                    TextField(
                      controller: c.amountController,
                      style: const TextStyle(color: Colors.white),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: 'Amount (\$)',
                        labelStyle: const TextStyle(color: AppColors.muted),
                        prefixIcon: const Icon(Icons.attach_money, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12.0),
                    TextField(
                      controller: c.referenceController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Bank / UPI / PayPal reference',
                        labelStyle: const TextStyle(color: AppColors.muted),
                        prefixIcon: const Icon(Icons.account_balance, color: AppColors.muted),
                        filled: true,
                        fillColor: AppColors.surfaceAlt,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12.0), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 16.0),
                    AppButton(
                      title: 'Submit withdrawal request',
                      loading: c.saving.value,
                      onPressed: c.submit,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20.0),

              // History list
              const Text('Withdrawal history', style: AppTextStyles.h2),
              const SizedBox(height: 10.0),
              if (c.loading.value)
                const Center(child: CircularProgressIndicator())
              else if (c.withdrawals.isEmpty)
                const AppEmptyState(
                  icon: Icons.history,
                  title: 'No withdrawal history',
                  text: 'Your past withdrawal requests will appear here.',
                )
              else
                ...c.withdrawals.map((w) {
                  final String status = w['status']?.toString() ?? 'pending';
                  final num amt = w['amount'] as num? ?? 0;
                  final String date = w['created_at']?.toString().split('T')[0] ?? 'Recent';

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: AppCard(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '\$$amt',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16.0),
                              ),
                              Text('$date · $status', style: const TextStyle(color: AppColors.muted, fontSize: 11.0)),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: status == 'paid'
                                  ? AppColors.success.withValues(alpha: 0.15)
                                  : AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'paid' ? AppColors.success : AppColors.primary,
                                fontSize: 10.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 20.0),
            ],
          );
        }),
      ),
    );
  }
}
