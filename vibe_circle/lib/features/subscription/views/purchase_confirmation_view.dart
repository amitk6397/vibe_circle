import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class PurchaseConfirmationView extends StatefulWidget {
  const PurchaseConfirmationView({super.key});

  @override
  State<PurchaseConfirmationView> createState() => _PurchaseConfirmationViewState();
}

class _PurchaseConfirmationViewState extends State<PurchaseConfirmationView> {
  bool _processing = false;
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    _loadPlan();
  }

  Future<void> _loadPlan() async {
    final args = Get.arguments as Map<String, dynamic>?;
    await Future.delayed(const Duration(milliseconds: 500));
    setState(() {
      _plan = {
        'id': args?['planId'] ?? '1',
        'name': args?['name'] ?? 'Value Pass',
        'currency': 'USD',
        'price': 3.99,
        'interval': 'week',
      };
    });
  }

  Future<void> _purchase() async {
    setState(() => _processing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _processing = false);
    // In real app: dummyPayments=true → subscriptionApi.purchase(plan.id, token)
    Get.offAndToNamed('/payment-success', arguments: {'kind': 'subscription'});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        title: Text('Purchase confirmation', style: AppTextStyles.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Plan summary card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: _plan == null
                  ? Text('Loading plan...', style: AppTextStyles.body)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_plan!['name']?.toString() ?? '', style: AppTextStyles.titleMedium),
                        const SizedBox(height: 8),
                        Text(
                          '${_plan!['currency']} ${_plan!['price']}/${_plan!['interval']}',
                          style: const TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                        const SizedBox(height: 8),
                        Text('Unlocks private chat, audio, and video for this period.', style: AppTextStyles.body),
                        const SizedBox(height: 4),
                        Text('Coins are charged separately for each paid conversation.', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
                      ],
                    ),
            ),
            // Dummy payments notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: const Color(0xFF1E3A1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.developer_mode, color: Colors.green, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Development mode: this payment is simulated and no real money is charged.',
                      style: AppTextStyles.caption.copyWith(color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _plan == null || _processing ? null : _purchase,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _processing
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Confirm purchase', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
