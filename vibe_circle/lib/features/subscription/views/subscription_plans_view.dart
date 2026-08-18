import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../wallet/controllers/wallet_controller.dart';

class SubscriptionPlansView extends GetView<WalletController> {
  const SubscriptionPlansView({super.key});

  void _buyCoins(dynamic item) async {
    final String packageId = item['id'].toString();
    try {
      await controller.buyPackage(packageId);

      final num totalCoins = (item['purchasedCoins'] ?? 0) + (item['bonusCoins'] ?? 0);
      Get.defaultDialog(
        title: 'Coins added successfully! 🎉',
        middleText: '$totalCoins coins have been added to your wallet.',
        textConfirm: 'OK',
        confirmTextColor: Colors.white,
        buttonColor: AppColors.primary,
        onConfirm: () => Get.back(),
      );
    } catch (e) {
      Get.snackbar('Purchase failed', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Coin Store',
        subtitle: 'Power your conversations & interactions',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero card gradient banner
            Container(
              padding: const EdgeInsets.all(18.0),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(22.0),
                gradient: const LinearGradient(
                  colors: [Color(0xFFE65100), Color(0xFFFF9800)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46.0,
                    height: 46.0,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(15.0),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 24.0),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Premium Coin Store',
                          style: TextStyle(color: Colors.white, fontSize: 16.0, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 3.0),
                        Text(
                          'Coins allow you to interact with creators, start paid chat sessions, unlock premium posts, and join private communities.',
                          style: TextStyle(color: Colors.white70, fontSize: 10.5, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Creator earnings info card
            AppCard(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(13.0),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.trending_up, color: Color(0xFF10B981), size: 20.0),
                  ),
                  const SizedBox(width: 12.0),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '💸 Earn while you chat',
                          style: TextStyle(color: AppColors.text, fontSize: 14.0, fontWeight: FontWeight.w900),
                        ),
                        SizedBox(height: 4.0),
                        Text(
                          'You can also earn coins! When other users pay coins to chat or call you, you keep 80% of those coins. Withdraw them as real cash anytime.',
                          style: TextStyle(color: AppColors.muted, fontSize: 12.0, height: 1.3),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Rates details card
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('💡 Coin Usage Rates', style: TextStyle(color: AppColors.text, fontSize: 14.0, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 10.0),
                  Row(
                    children: [
                      _buildRateItem(Icons.chat_bubble_outline, 'Paid Chat', '2 coins/min', AppColors.primary),
                      const SizedBox(width: 6.0),
                      _buildRateItem(Icons.call_outlined, 'Audio Call', '5 coins/min', const Color(0xFF10B981)),
                      const SizedBox(width: 6.0),
                      _buildRateItem(Icons.videocam_outlined, 'Video Call', '10 coins/min', const Color(0xFF0284C7)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22.0),

            const Text('Select a Coin Pack', style: AppTextStyles.h2),
            const SizedBox(height: 12.0),

            // Grids packages
            Obx(() {
              final list = controller.packages;
              return controller.loading.value
                  ? const Center(child: CircularProgressIndicator())
                  : list.isNotEmpty
                      ? GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 10.0,
                            crossAxisSpacing: 10.0,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: list.length,
                          itemBuilder: (context, index) {
                            final item = list[index];
                            final bool isPopular = index == 1;
                            final num purchased = item['purchasedCoins'] ?? 0;
                            final num bonus = item['bonusCoins'] ?? 0;
                            final int discount = bonus > 0 ? ((bonus / purchased) * 100).round() : 0;

                            return Stack(
                              children: [
                                // Card container
                                Positioned.fill(
                                  child: AppCard(
                                    borderColor: isPopular ? AppColors.primary : Colors.transparent,
                                    borderWidth: isPopular ? 2.0 : 1.0,
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const SizedBox(height: 12.0),
                                        const CircleAvatar(
                                          radius: 20.0,
                                          backgroundColor: Color(0xFFFF9800),
                                          child: Icon(Icons.monetization_on, color: Colors.white, size: 22.0),
                                        ),
                                        const SizedBox(height: 8.0),
                                        Text(
                                          '${purchased + bonus}',
                                          style: const TextStyle(color: AppColors.text, fontSize: 26.0, fontWeight: FontWeight.w900),
                                        ),
                                        const Text(
                                          'COINS',
                                          style: TextStyle(color: AppColors.primary, fontSize: 9.0, fontWeight: FontWeight.w900, letterSpacing: 1.2),
                                        ),
                                        if (bonus > 0)
                                          Text(
                                            'Includes $bonus bonus coins',
                                            style: const TextStyle(color: Color(0xFF10B981), fontSize: 9.0, fontWeight: FontWeight.bold),
                                          ),
                                        const SizedBox(height: 4.0),
                                        Text(
                                          item['name'] ?? '',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 10.0),
                                        ),
                                        const SizedBox(height: 10.0),
                                        AppButton(
                                          title: 'Buy for ${item['currency']}${item['price']}',
                                          tone: isPopular ? AppButtonTone.primary : AppButtonTone.secondary,
                                          loading: controller.buyingId.value == item['id'].toString(),
                                          onPressed: () => _buyCoins(item),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // POPULAR Badge tag
                                if (isPopular)
                                  Positioned(
                                    top: 8.0,
                                    right: 8.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary,
                                        borderRadius: BorderRadius.circular(6.0),
                                      ),
                                      child: const Text(
                                        'POPULAR',
                                        style: TextStyle(color: Colors.white, fontSize: 7.5, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),

                                // FREE Bonus badge tag
                                if (bonus > 0)
                                  Positioned(
                                    top: 8.0,
                                    left: 8.0,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 3.0),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF10B981).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6.0),
                                      ),
                                      child: Text(
                                        '+$discount% FREE',
                                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 7.5, fontWeight: FontWeight.w900),
                                      ),
                                    ),
                                  ),
                              ],
                            );
                          },
                        )
                      : const AppEmptyState(
                          title: 'No Packages Available',
                          text: 'Please try again later.',
                        );
            }),
            const SizedBox(height: 18.0),

            // Secure checkout footer tag
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, color: Color(0xFF10B981), size: 16.0),
                SizedBox(width: 6.0),
                Text(
                  'Secure checkout · Managed by platform admin',
                  style: TextStyle(color: AppColors.muted, fontSize: 11.5),
                ),
              ],
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }

  Widget _buildRateItem(IconData icon, String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10.0),
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(icon, size: 16.0, color: color),
            const SizedBox(height: 4.0),
            Text(
              label,
              style: const TextStyle(color: AppColors.muted, fontSize: 9.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 2.0),
            Text(
              value,
              style: const TextStyle(color: AppColors.text, fontSize: 10.0, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
