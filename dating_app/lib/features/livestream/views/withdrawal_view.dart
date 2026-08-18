import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class WithdrawalView extends StatefulWidget {
  const WithdrawalView({super.key});

  @override
  State<WithdrawalView> createState() => _WithdrawalViewState();
}

class _WithdrawalViewState extends State<WithdrawalView> {
  String _amount = '';
  String _reference = '';
  bool _saving = false;
  final List _withdrawals = [];
  final double _availableBalance = 0;

  Future<void> _submit() async {
    final amt = double.tryParse(_amount);
    if (amt == null || amt <= 0 || _reference.trim().isEmpty) return;
    setState(() => _saving = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _saving = false;
      _amount = '';
      _reference = '';
    });
    _showSuccess();
  }

  void _showSuccess() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Withdrawal requested', style: AppTextStyles.title),
        content: const Text('Your request is pending review.', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Withdrawal', style: AppTextStyles.title),
            Text(
              'Available: $_availableBalance',
              style: AppTextStyles.caption.copyWith(color: AppColors.muted),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Info card
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Payout processing is currently manual/dummy. No bank transfer is claimed until an administrator marks it paid.',
                style: AppTextStyles.body,
              ),
            ),

            // Amount field
            Text('Amount', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
            const SizedBox(height: 6),
            TextField(
              style: const TextStyle(color: Colors.white),
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              ),
              onChanged: (v) => setState(() => _amount = v),
            ),
            const SizedBox(height: 14),

            // Reference field
            Text('Payout account reference', style: AppTextStyles.caption.copyWith(color: AppColors.muted)),
            const SizedBox(height: 6),
            TextField(
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Bank / payment reference',
                hintStyle: const TextStyle(color: AppColors.muted),
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.border)),
              ),
              onChanged: (v) => setState(() => _reference = v),
            ),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_amount.isEmpty || _reference.trim().isEmpty || _saving) ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Request withdrawal', style: AppTextStyles.buttonText),
              ),
            ),
            const SizedBox(height: 20),

            // Withdrawal history
            ..._withdrawals.map((item) {
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
                    Text('${item['amount']}', style: AppTextStyles.title),
                    Text(
                      '${item['status']} · ${item['created_at']}',
                      style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
