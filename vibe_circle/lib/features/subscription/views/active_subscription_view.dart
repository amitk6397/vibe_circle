import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_animated_loader.dart';

class ActiveSubscriptionView extends StatefulWidget {
  const ActiveSubscriptionView({super.key});

  @override
  State<ActiveSubscriptionView> createState() => _ActiveSubscriptionViewState();
}

class _ActiveSubscriptionViewState extends State<ActiveSubscriptionView> {
  bool _loading = true;
  Map<String, dynamic>? _subscription;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // In real app: subscriptionApi.active()
    await Future.delayed(const Duration(milliseconds: 700));
    setState(() {
      // null means no active subscription
      _subscription = null;
      _loading = false;
    });
  }

  void _showCancelDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Cancel renewal?', style: AppTextStyles.titleMedium),
        content: Text('Your benefits stay active until the expiry date.', style: AppTextStyles.body),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep plan', style: TextStyle(color: AppColors.primary)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _load();
            },
            child: const Text('Cancel renewal', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
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
        title: Text('Active subscription', style: AppTextStyles.titleMedium),
      ),
      body: _loading
          ? const AppAnimatedLoader()
          : _subscription == null
              ? _EmptyState(onAction: () => Get.toNamed('/subscription-plans'))
              : _SubscriptionDetail(
                  subscription: _subscription!,
                  onCancelRenewal: _showCancelDialog,
                  onUpgrade: () => Get.toNamed('/subscription-plans'),
                  onHistory: () => Get.toNamed('/subscription-history'),
                ),
    );
  }
}

class _SubscriptionDetail extends StatelessWidget {
  final Map<String, dynamic> subscription;
  final VoidCallback onCancelRenewal;
  final VoidCallback onUpgrade;
  final VoidCallback onHistory;
  const _SubscriptionDetail({
    required this.subscription,
    required this.onCancelRenewal,
    required this.onUpgrade,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    final plan = subscription['plan'] as Map? ?? {};
    final startsAt = subscription['startsAt']?.toString() ?? '';
    final expiresAt = subscription['expiresAt']?.toString() ?? '';
    final autoRenews = subscription['autoRenews'] as bool? ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(plan['name']?.toString() ?? '', style: AppTextStyles.titleLarge),
                const SizedBox(height: 8),
                if (startsAt.isNotEmpty) Text('Started: $startsAt', style: AppTextStyles.body),
                if (expiresAt.isNotEmpty) Text('Expires: $expiresAt', style: AppTextStyles.body),
                Text('Auto-renewal: ${autoRenews ? 'On' : 'Off'}', style: AppTextStyles.body),
                const SizedBox(height: 8),
                Text('Private chat, audio, and video access is active.', style: AppTextStyles.body),
                const SizedBox(height: 4),
                Text('Conversation charges are paid separately with coins.', style: AppTextStyles.caption.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onCancelRenewal,
              child: Text('Cancel renewal', style: AppTextStyles.button.copyWith(color: AppColors.textMuted)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onUpgrade,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Upgrade plan', style: AppTextStyles.button.copyWith(color: Colors.white)),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onHistory,
              child: Text('Subscription history', style: AppTextStyles.button.copyWith(color: AppColors.textMuted)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAction;
  const _EmptyState({required this.onAction});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.stars_outlined, size: 64, color: AppColors.textMuted),
            const SizedBox(height: 16),
            Text('No active pass', style: AppTextStyles.titleMedium),
            const SizedBox(height: 8),
            Text(
              'Choose a 1 day, 1 week, or 1 month pass to use paid chat and calls.',
              style: AppTextStyles.body.copyWith(color: AppColors.textMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: onAction,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('View plans'),
            ),
          ],
        ),
      ),
    );
  }
}
