import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../controllers/wallet_controller.dart';
import '../models/wallet_transaction_model.dart';

class TransactionHistoryView extends GetView<WalletController> {
  const TransactionHistoryView({super.key});

  @override
  Widget build(BuildContext context) {
    final RxString filter = 'all'.obs; // 'all' | 'credit' | 'debit'

    return AppScreen(
      scroll: false,
      header: AppHeader(
        title: 'Transactions',
        subtitle: 'All credit and debit activities',
        onBack: () => Get.back(),
      ),
      child: Column(
        children: [
          // Filter pills (All, Received, Spent)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Obx(
              () => Row(
                children: [
                  _buildFilterPill('All', 'all', filter),
                  const SizedBox(width: 8.0),
                  _buildFilterPill('Received', 'credit', filter),
                  const SizedBox(width: 8.0),
                  _buildFilterPill('Spent', 'debit', filter),
                ],
              ),
            ),
          ),

          // Transactions List
          Expanded(
            child: Obx(() {
              if (controller.transactionsLoading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<WalletTransaction> list = controller.transactions;
              final List<WalletTransaction> filtered = filter.value == 'credit'
                  ? list.where((t) => t.amount > 0).toList()
                  : filter.value == 'debit'
                      ? list.where((t) => t.amount < 0).toList()
                      : list;

              if (filtered.isEmpty) {
                return const Center(
                  child: AppEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No transactions',
                    text: 'No transactions match this filter.',
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: filtered.length + (controller.hasMoreTransactions.value ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= filtered.length) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: AppButton(
                        title: 'Load more',
                        tone: AppButtonTone.ghost,
                        onPressed: () => controller.loadTransactions(refresh: false),
                      ),
                    );
                  }

                  final WalletTransaction item = filtered[index];
                  final int amt = item.amount;
                  final bool isCredit = amt > 0;
                  final String typeStr = item.transactionType.replaceAll('_', ' ');
                  final String createdAt = item.createdAt;
                  final String dateDisplay = createdAt.isNotEmpty ? createdAt.split('T')[0] : 'Recent';
                  final String status = item.status;
                  final String txId = item.id;
                  final String paymentMethod = item.paymentMethod;

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                typeStr.toUpperCase(),
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                '${isCredit ? '+' : ''}$amt',
                                style: TextStyle(
                                  color: isCredit ? AppColors.success : AppColors.text,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4.0),
                          Text(
                            '$dateDisplay · $status',
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                          ),
                          const SizedBox(height: 8.0),
                          Container(
                            padding: const EdgeInsets.all(8.0),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceAlt,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Transaction ID: $txId',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  'Payment: $paymentMethod',
                                  style: const TextStyle(color: AppColors.muted, fontSize: 10.5),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(String label, String value, RxString filter) {
    final bool isSel = filter.value == value;
    return GestureDetector(
      onTap: () => filter.value = value,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSel ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20.0),
          border: Border.all(color: isSel ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSel ? Colors.white : AppColors.muted,
            fontWeight: isSel ? FontWeight.w800 : FontWeight.w600,
            fontSize: 12.0,
          ),
        ),
      ),
    );
  }
}
