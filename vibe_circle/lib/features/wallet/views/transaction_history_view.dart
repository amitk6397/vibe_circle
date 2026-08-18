import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class TransactionHistoryView extends StatefulWidget {
  const TransactionHistoryView({super.key});

  @override
  State<TransactionHistoryView> createState() => _TransactionHistoryViewState();
}

class _TransactionHistoryViewState extends State<TransactionHistoryView> {
  String _filter = 'all';
  final bool _loading = false;

  final List<Map<String, dynamic>> _transactions = [];

  List<Map<String, dynamic>> get _filtered {
    if (_filter == 'credit') return _transactions.where((t) => (t['amount'] as num? ?? 0) > 0).toList();
    if (_filter == 'debit') return _transactions.where((t) => (t['amount'] as num? ?? 0) < 0).toList();
    return _transactions;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text('Transactions', style: AppTextStyles.h2),
      ),
      body: Column(
        children: [
          // Filter pills
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.bg,
              border: Border(bottom: BorderSide(color: AppColors.border)),
            ),
            child: Row(
              children: [
                _FilterPill(label: 'All', selected: _filter == 'all', onTap: () => setState(() => _filter = 'all')),
                const SizedBox(width: 8),
                _FilterPill(label: 'Received', selected: _filter == 'credit', onTap: () => setState(() => _filter = 'credit')),
                const SizedBox(width: 8),
                _FilterPill(label: 'Spent', selected: _filter == 'debit', onTap: () => setState(() => _filter = 'debit')),
              ],
            ),
          ),
          Expanded(
            child: _filtered.isEmpty
                ? const _EmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filtered.length,
                    itemBuilder: (context, index) {
                      return _TransactionCard(item: _filtered[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _FilterPill({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: selected ? Colors.white : AppColors.muted,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _TransactionCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final amount = (item['amount'] as num? ?? 0);
    final isCredit = amount > 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                (item['transaction_type']?.toString() ?? '').replaceAll('_', ' ').toUpperCase(),
                style: AppTextStyles.label,
              ),
              Text(
                '${isCredit ? '+' : ''}$amount',
                style: AppTextStyles.label.copyWith(
                  color: isCredit ? Colors.green : Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item['created_at'] ?? ''} · ${item['status'] ?? ''}',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 4),
          Text(
            'Transaction ID: ${item['id'] ?? ''}',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
          ),
          Text(
            'Payment: ${item['payment_method'] ?? 'wallet credit'}',
            style: AppTextStyles.caption.copyWith(color: AppColors.muted, fontSize: 11),
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
            Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.muted),
            SizedBox(height: 16),
            Text('No transactions', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w700)),
            SizedBox(height: 8),
            Text(
              'No transactions match this filter.',
              style: TextStyle(color: AppColors.muted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

