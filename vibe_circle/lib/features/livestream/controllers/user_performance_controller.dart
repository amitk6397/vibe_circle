import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/api_urls.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/network_api_service.dart';
import '../../../routes/app_routes.dart';
import '../models/creator_profile_model.dart';
import '../models/gift_model.dart';
import '../models/review_model.dart';

class UserPerformanceController extends GetxController {
  final NetworkApiService _api = NetworkApiService.instance;

  final RxString userId = ''.obs;
  final RxBool loading = true.obs;
  final RxString error = ''.obs;
  final Rxn<CreatorProfile> profile = Rxn<CreatorProfile>();
  final RxList<GiftItem> gifts = <GiftItem>[].obs;
  final RxList<UserReview> reviews = <UserReview>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>?;
    userId.value = args?['userId']?.toString() ?? '';
    loadData();
  }

  Future<void> loadData() async {
    loading.value = true;
    error.value = '';
    try {
      if (userId.value.isNotEmpty) {
        try {
          final profileRes = await _api.get(ApiUrls.earningsProfile(userId.value));
          if (profileRes.data is Map) {
            profile.value = CreatorProfile.fromJson(Map<String, dynamic>.from(profileRes.data));
          }
        } catch (_) {}

        try {
          final giftsRes = await _api.get(ApiUrls.gifts);
          if (giftsRes.data is List) {
            gifts.assignAll((giftsRes.data as List)
                .map((e) => GiftItem.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList());
          }
        } catch (_) {}

        try {
          final reviewsRes = await _api.get(ApiUrls.userReviews(userId.value));
          if (reviewsRes.data is List) {
            reviews.assignAll((reviewsRes.data as List)
                .map((e) => UserReview.fromJson(Map<String, dynamic>.from(e as Map)))
                .toList());
          }
        } catch (_) {}
      } else {
        try {
          final myProfileRes = await _api.get(ApiUrls.myEarningsProfile);
          if (myProfileRes.data is Map) {
            profile.value = CreatorProfile.fromJson(Map<String, dynamic>.from(myProfileRes.data));
          }
        } catch (_) {}
      }

      profile.value ??= CreatorProfile();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  void requestCall(String type) {
    final int price = type == 'audio'
        ? (profile.value?.audioPricePerMinute ?? 5)
        : (profile.value?.videoPricePerMinute ?? 10);

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(20.0),
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.0)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${type == 'audio' ? 'Audio' : 'Video'} Session Request',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 17.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4.0),
              Text(
                'Rate: $price coins / min. Choose a duration to reserve.',
                style: const TextStyle(color: AppColors.muted, fontSize: 12.0),
              ),
              const SizedBox(height: 16.0),
              ...[5, 10, 15, 30].map((mins) {
                final int totalCoins = price * mins;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8.0),
                  child: ElevatedButton(
                    onPressed: () async {
                      Get.back();
                      try {
                        final res = await _api.post(
                          ApiUrls.callsStart,
                          data: {
                            'receiver_id': userId.value,
                            'call_type': type,
                            'duration_minutes': mins,
                          },
                        );
                        final callData = res.data is Map ? res.data : {};
                        Get.toNamed(
                          type == 'audio' ? AppRoutes.AUDIO_CALL : AppRoutes.VIDEO_CALL,
                          arguments: {
                            'callId': callData['id']?.toString() ?? '',
                            'name': profile.value?.name ?? 'User',
                            'personId': userId.value,
                          },
                        );
                      } catch (e) {
                        Get.snackbar('Request failed', e.toString());
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceAlt,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$mins minutes',
                          style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '🪙 $totalCoins coins',
                          style: const TextStyle(color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  void sendGift(GiftItem gift) {
    final int price = gift.coinPrice;
    final String name = gift.name;

    Get.defaultDialog(
      title: 'Send $name?',
      middleText: 'Cost: $price coins. It will be sent to ${profile.value?.name ?? 'creator'}.',
      textConfirm: 'Send Gift',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () async {
        Get.back();
        try {
          await _api.post(
            ApiUrls.sendGift,
            data: {
              'gift_id': gift.id,
              'recipient_id': userId.value,
              'target_type': 'user_profile',
              'target_id': userId.value,
            },
          );
          Get.snackbar(
            'Gift Sent! 🎁',
            'You sent $name ($price coins) successfully.',
            backgroundColor: AppColors.primary,
            colorText: Colors.white,
          );
        } catch (e) {
          Get.snackbar('Gift failed', e.toString());
        }
      },
    );
  }
}
