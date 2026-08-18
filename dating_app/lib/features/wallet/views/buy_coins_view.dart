import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class BuyCoinsView extends StatefulWidget {
  const BuyCoinsView({super.key});

  @override
  State<BuyCoinsView> createState() => _BuyCoinsViewState();
}

class _BuyCoinsViewState extends State<BuyCoinsView> {
  String _buying = '';

  final List<Map<String, dynamic>> _packages = [
    {
      'id': '1',
      'name': 'Starter Pack',
      'purchasedCoins': 100,
      'bonusCoins': 10,
      'price': 0.99,
      'currency': 'USD',
      'isPopular': false,
      'badge': null,
      'discountPercentage': 0,
      'description': 'Great for trying out features',
    },
    {
      'id': '2',
      'name': 'Value Pack',
      'purchasedCoins': 500,
      'bonusCoins': 75,
      'price': 3.99,
      'currency': 'USD',
      'isPopular': true,
      'badge': 'BEST VALUE',
      'discountPercentage': 10,
      'description': 'Perfect for regular users',
    },
    {
      'id': '3',
      'name': 'Premium Pack',
      'purchasedCoins': 1000,
      'bonusCoins': 200,
      'price': 6.99,
      'currency': 'USD',
      'isPopular': false,
      'badge': null,
      'discountPercentage': 20,
      'description': 'Best for power users',
    },
    {
      'id': '4',
      'name': 'Mega Bundle',
      'purchasedCoins': 5000,
      'bonusCoins': 1500,
      'price': 24.99,
      'currency': 'USD',
      'isPopular': false,
      'badge': 'MEGA DEAL',
      'discountPercentage': 30,
      'description': 'Ultimate coin bundle',
    },
  ];

  final List<Map<String, dynamic>> _offers = [
    {
      'id': 'o1',
      'title': '🎉 Weekend Special',
      'description': 'Get 25% extra bonus coins this weekend!',
      'discountPercentage': 0,
      'bonusCoinsPercentage': 25,
      'bannerUrl': null,
    },
  ];

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
            Text('Buy coins', style: AppTextStyles.h2),
            Text(
              'Development payment simulator',
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
            // Special Offers
            if (_offers.isNotEmpty) ...[
              Text('Special Promotions', style: AppTextStyles.h2),
              const SizedBox(height: 10),
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _offers.length,
                  itemBuilder: (context, index) {
                    final offer = _offers[index];
                    return _OfferCard(offer: offer);
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Coin packages
            ..._packages.map((pkg) {
              final discount = (pkg['discountPercentage'] as num).toDouble();
              final price = (pkg['price'] as num).toDouble();
              final originalPrice = discount > 0 ? price / (1 - discount / 100) : price;

              return _CoinPackageCard(
                package: pkg,
                originalPrice: originalPrice,
                buying: _buying == pkg['id'],
                onBuy: () async {
                  setState(() => _buying = pkg['id'].toString());
                  await Future.delayed(const Duration(seconds: 2));
                  setState(() => _buying = '');
                  Get.toNamed('/payment-success', arguments: {'kind': 'coins'});
                },
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  final Map<String, dynamic> offer;
  const _OfferCard({required this.offer});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      width: screenWidth - 48,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF35225D),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(offer['title'] ?? '', style: AppTextStyles.label.copyWith(color: Colors.white)),
          const SizedBox(height: 4),
          Text(
            offer['description'] ?? '',
            style: AppTextStyles.caption.copyWith(color: const Color(0xFFCCCCFF)),
            maxLines: 2,
          ),
          const SizedBox(height: 8),
          if ((offer['bonusCoinsPercentage'] as num? ?? 0) > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.amber,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '+${offer['bonusCoinsPercentage']}% BONUS',
                style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoinPackageCard extends StatelessWidget {
  final Map<String, dynamic> package;
  final double originalPrice;
  final bool buying;
  final VoidCallback onBuy;

  const _CoinPackageCard({
    required this.package,
    required this.originalPrice,
    required this.buying,
    required this.onBuy,
  });

  @override
  Widget build(BuildContext context) {
    final discount = (package['discountPercentage'] as num).toDouble();
    final price = (package['price'] as num).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (package['isPopular'] == true)
                      Text('⭐ Popular Choice',
                          style: AppTextStyles.caption.copyWith(
                            color: Colors.amber,
                            fontWeight: FontWeight.w700,
                          )),
                    Text(package['name'] ?? '', style: AppTextStyles.h2),
                    if (package['description'] != null)
                      Text(
                        package['description'].toString(),
                        style: AppTextStyles.caption.copyWith(color: AppColors.muted),
                      ),
                  ],
                ),
              ),
              if (package['badge'] != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    package['badge'].toString(),
                    style: AppTextStyles.caption.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${package['purchasedCoins']} purchased coins'
            '${package['bonusCoins'] != null ? ' + ${package['bonusCoins']} bonus' : ''}',
            style: AppTextStyles.body,
          ),
          const SizedBox(height: 8),
          if (discount > 0)
            Row(
              children: [
                Text(
                  '${package['currency']} ${price.toStringAsFixed(2)}',
                  style: AppTextStyles.h2,
                ),
                const SizedBox(width: 8),
                Text(
                  '${package['currency']} ${originalPrice.toStringAsFixed(0)}',
                  style: AppTextStyles.body.copyWith(
                    decoration: TextDecoration.lineThrough,
                    color: AppColors.muted,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '(${discount.toInt()}% OFF)',
                  style: const TextStyle(color: Colors.green, fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ],
            )
          else
            Text(
              '${package['currency']} ${price.toStringAsFixed(2)}',
              style: AppTextStyles.h2,
            ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: buying ? null : onBuy,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: buying
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                    )
                  : Text('Simulate purchase', style: AppTextStyles.buttonText),
            ),
          ),
        ],
      ),
    );
  }
}

