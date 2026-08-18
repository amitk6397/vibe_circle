import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_animated_loader.dart';

class PlanDetailsView extends StatefulWidget {
  const PlanDetailsView({super.key});

  @override
  State<PlanDetailsView> createState() => _PlanDetailsViewState();
}

class _PlanDetailsViewState extends State<PlanDetailsView> {
  bool _loading = true;
  Map<String, dynamic>? _plan;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // In real app: call subscriptionApi.plans() and find by planId from args
    await Future.delayed(const Duration(milliseconds: 600));
    final args = Get.arguments as Map<String, dynamic>?;
    setState(() {
      _plan = {
        'id': args?['planId'] ?? '1',
        'name': args?['name'] ?? 'Value Pass',
        'currency': 'USD',
        'price': 3.99,
        'interval': 'week',
        'features': [
          'Unlimited private chat',
          'Audio calls',
          'Video calls',
          'Priority matching',
        ],
      };
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.surface, title: Text('Plan details', style: AppTextStyles.titleMedium)),
        body: const AppAnimatedLoader(),
      );
    }
    if (_plan == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Get.back()),
          title: Text('Plan details', style: AppTextStyles.titleMedium),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.credit_card_off_outlined, size: 64, color: AppColors.textMuted),
                const SizedBox(height: 16),
                Text('Plan unavailable', style: AppTextStyles.titleMedium),
                const SizedBox(height: 8),
                Text('This plan may no longer be offered.', style: AppTextStyles.body.copyWith(color: AppColors.textMuted), textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white), onPressed: () => Get.back()),
        title: Text(_plan!['name']?.toString() ?? 'Plan details', style: AppTextStyles.titleMedium),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_plan!['currency']} ${_plan!['price']}/${_plan!['interval']}',
                    style: const TextStyle(fontSize: 28, color: Colors.white, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 12),
                  ...(_plan!['features'] as List).map((feature) => Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text('• ${feature.toString()}', style: AppTextStyles.body),
                  )),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Get.toNamed('/purchase-confirmation', arguments: {'planId': _plan!['id']}),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text('Continue', style: AppTextStyles.button),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
