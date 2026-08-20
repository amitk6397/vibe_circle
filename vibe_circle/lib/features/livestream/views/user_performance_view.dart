import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_animated_loader.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../routes/app_routes.dart';
import '../controllers/user_performance_controller.dart';
import '../models/creator_profile_model.dart';
import '../models/gift_model.dart';

class UserPerformanceView extends GetView<UserPerformanceController> {
  const UserPerformanceView({super.key});

  @override
  Widget build(BuildContext context) {
    // Ensure controller is registered
    final UserPerformanceController c = Get.isRegistered<UserPerformanceController>()
        ? Get.find<UserPerformanceController>()
        : Get.put(UserPerformanceController());

    return Obx(() {
      if (c.loading.value) {
        return const Scaffold(backgroundColor: AppColors.bg, body: AppAnimatedLoader());
      }
      if (c.error.value.isNotEmpty) {
        return Scaffold(
          backgroundColor: AppColors.bg,
          appBar: AppBar(
            backgroundColor: AppColors.surface,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Get.back(),
            ),
            title: const Text('Performance', style: AppTextStyles.title),
          ),
          body: Center(
            child: Text(c.error.value, style: AppTextStyles.body.copyWith(color: AppColors.danger)),
          ),
        );
      }

      final CreatorProfile p = c.profile.value ?? CreatorProfile();
      final String name = p.name;
      final String? avatarUrl = p.avatarUrl;
      final double rating = p.performanceRating;
      final int sessions = p.completedSessions;
      final int responseRate = p.responseRate;

      final int chatRate = p.chatPrice;
      final int audioRate = p.audioPricePerMinute;
      final int videoRate = p.videoPricePerMinute;

      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: AppBar(
          backgroundColor: AppColors.surface,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
            onPressed: () => Get.back(),
          ),
          title: const Text('Performance & Coin Rates', style: AppTextStyles.title),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Profile Hero
              Center(
                child: Column(
                  children: [
                    AppAvatar(name: name, avatarUrl: avatarUrl, size: 84.0),
                    const SizedBox(height: 12.0),
                    Text(
                      name,
                      style: const TextStyle(color: Colors.white, fontSize: 20.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      '${p.category} · ${p.availabilityStatus}',
                      style: const TextStyle(color: AppColors.muted, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Performance Stats Card
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16.0),
                              const SizedBox(width: 4.0),
                              Text(
                                rating.toStringAsFixed(1),
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16.0),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2.0),
                          const Text('Rating', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                        ],
                      ),
                    ),
                    Container(width: 1.0, height: 30.0, color: AppColors.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$sessions',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16.0),
                          ),
                          const SizedBox(height: 2.0),
                          const Text('Sessions', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                        ],
                      ),
                    ),
                    Container(width: 1.0, height: 30.0, color: AppColors.border),
                    Expanded(
                      child: Column(
                        children: [
                          Text(
                            '$responseRate%',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16.0),
                          ),
                          const SizedBox(height: 2.0),
                          const Text('Response', style: TextStyle(color: AppColors.muted, fontSize: 11.0)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16.0),

              // Coin Rates Section
              const Text('SESSION COIN RATES', style: TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 10.0),

              // Chat Rate Card
              _RateCard(
                icon: Icons.chat_bubble_outline,
                title: 'Private Chat',
                rate: '$chatRate coins / min',
                buttonTitle: 'Message',
                onPressed: () => Get.toNamed(AppRoutes.NEW_MESSAGE_REQUEST, arguments: {'recipientId': c.userId.value}),
              ),
              const SizedBox(height: 8.0),

              // Audio Call Rate Card
              _RateCard(
                icon: Icons.phone_outlined,
                title: 'Audio Call',
                rate: '$audioRate coins / min',
                buttonTitle: 'Request Call',
                onPressed: () => c.requestCall('audio'),
              ),
              const SizedBox(height: 8.0),

              // Video Call Rate Card
              _RateCard(
                icon: Icons.videocam_outlined,
                title: 'Video Call',
                rate: '$videoRate coins / min',
                buttonTitle: 'Request Video',
                onPressed: () => c.requestCall('video'),
              ),
              const SizedBox(height: 20.0),

              // Send Gift Section
              if (c.gifts.isNotEmpty) ...[
                const Text('SEND A GIFT', style: TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
                const SizedBox(height: 10.0),
                Wrap(
                  spacing: 8.0,
                  runSpacing: 8.0,
                  children: c.gifts.map((GiftItem gift) {
                    return InkWell(
                      onTap: () => c.sendGift(gift),
                      borderRadius: BorderRadius.circular(12.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12.0),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(gift.icon, style: const TextStyle(fontSize: 18.0)),
                            const SizedBox(width: 6.0),
                            Text(
                              '${gift.name} · ${gift.coinPrice} 🪙',
                              style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 12.0),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20.0),
              ],

              // Reviews Section
              const Text('REVIEWS', style: TextStyle(color: AppColors.muted, fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.8)),
              const SizedBox(height: 10.0),
              if (c.reviews.isEmpty)
                const AppEmptyState(title: 'No reviews yet', text: 'Be the first to review after a session.')
              else
                ...c.reviews.take(5).map((rev) {
                  final int ratingVal = rev.overallRating;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: List.generate(
                              5,
                              (i) => Icon(
                                i < ratingVal ? Icons.star : Icons.star_border,
                                color: Colors.amber,
                                size: 14.0,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6.0),
                          Text(
                            rev.review,
                            style: const TextStyle(color: AppColors.text, fontSize: 12.5),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      );
    });
  }
}

class _RateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String rate;
  final String buttonTitle;
  final VoidCallback onPressed;

  const _RateCard({
    required this.icon,
    required this.title,
    required this.rate,
    required this.buttonTitle,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.0),
            ),
            child: Icon(icon, color: AppColors.primary, size: 20.0),
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 13.5)),
                Text(rate, style: const TextStyle(color: Color(0xFFF59E0B), fontSize: 11.5, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.0)),
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            ),
            child: Text(buttonTitle, style: const TextStyle(color: Colors.white, fontSize: 12.0, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
