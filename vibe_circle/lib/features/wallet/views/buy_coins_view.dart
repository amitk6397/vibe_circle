import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../routes/app_routes.dart';
import '../controllers/wallet_controller.dart';
import '../models/coin_package_model.dart';

class BuyCoinsView extends GetView<WalletController> {
  const BuyCoinsView({super.key});

  void _handleBuy(WalletController c, CoinPackage pkg) async {
    try {
      await c.buyPackage(pkg.id);
      Get.toNamed(
        AppRoutes.PURCHASE_CONFIRMATION,
        arguments: {
          'title': 'Coins purchased',
          'amount': '${pkg.currency} ${pkg.price}',
          'detail': '${pkg.totalCoins} coins added to your wallet',
          'type': 'coins',
        },
      );
    } catch (e) {
      Get.toNamed(
        AppRoutes.PAYMENT_FAILURE,
        arguments: {
          'title': 'Purchase failed',
          'reason': e.toString(),
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final WalletController c = Get.isRegistered<WalletController>()
        ? Get.find<WalletController>()
        : Get.put(WalletController());

    if (c.packages.isEmpty) {
      c.loadPackages();
    }

    return AppScreen(
      header: AppHeader(
        title: 'Buy coins',
        subtitle: 'Development payment simulator',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Obx(() {
          final List<CoinPackage> pkgs = c.packages;

          if (pkgs.isEmpty) {
            return const Center(
              child: AppEmptyState(
                icon: Icons.monetization_on_outlined,
                title: 'No Packages Available',
                text: 'Coin packages could not be loaded at this time.',
              ),
            );
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...pkgs.map((pkg) => _buildPackageCard(c, pkg)),
              const SizedBox(height: 16.0),

              // Subscription link card
              AppCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: const Icon(Icons.card_membership, color: AppColors.primary, size: 24.0),
                    ),
                    const SizedBox(width: 14.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Looking for a subscription?', style: AppTextStyles.subtitle),
                          const SizedBox(height: 2.0),
                          Text(
                            'Get coins + premium features with a monthly plan',
                            style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8.0),
                    TextButton(
                      onPressed: () => Get.toNamed(AppRoutes.SUBSCRIPTION_PLANS),
                      child: const Text('View plans', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32.0),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildPackageCard(WalletController c, CoinPackage pkg) {
    final double numPrice = double.tryParse(pkg.price) ?? 0.0;
    final double originalPrice = (pkg.discountPercentage > 0 && pkg.discountPercentage < 100)
        ? (numPrice / (1 - (pkg.discountPercentage / 100)))
        : numPrice;

    return Obx(() {
      final bool isProcessing = c.buyingId.value == pkg.id;

      return Padding(
        padding: const EdgeInsets.only(bottom: 14.0),
        child: AppCard(
          borderColor: pkg.isPopular ? AppColors.primary : Colors.transparent,
          borderWidth: pkg.isPopular ? 1.8 : 1.0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Badges Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (pkg.isPopular)
                    const Text(
                      '⭐ POPULAR CHOICE',
                      style: TextStyle(
                        color: Color(0xFFF59E0B),
                        fontSize: 11.0,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (pkg.bonusCoins > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      child: Text(
                        '+${pkg.bonusCoins} BONUS',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6.0),

              // Package Name
              Text(pkg.name, style: AppTextStyles.h2),
              const SizedBox(height: 4.0),

              // Coin description breakdown
              Text(
                '${pkg.purchasedCoins} purchased coins${pkg.bonusCoins > 0 ? ' + ${pkg.bonusCoins} bonus' : ''}',
                style: const TextStyle(color: AppColors.muted, fontSize: 13.5),
              ),
              const SizedBox(height: 8.0),

              // Price & Discount tags
              Row(
                children: [
                  Text(
                    '${pkg.currency} ${pkg.price}',
                    style: const TextStyle(color: AppColors.text, fontSize: 18.0, fontWeight: FontWeight.w900),
                  ),
                  if (pkg.discountPercentage > 0) ...[
                    const SizedBox(width: 8.0),
                    Text(
                      '${pkg.currency} ${originalPrice.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: AppColors.muted,
                        fontSize: 13.0,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    Text(
                      '(${pkg.discountPercentage}% OFF)',
                      style: const TextStyle(
                        color: AppColors.success,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 14.0),

              // Simulate purchase button
              AppButton(
                title: 'Simulate purchase',
                loading: isProcessing,
                disabled: c.buyingId.value.isNotEmpty,
                tone: pkg.isPopular ? AppButtonTone.primary : AppButtonTone.secondary,
                onPressed: () => _handleBuy(c, pkg),
              ),
            ],
          ),
        ),
      );
    });
  }
}
