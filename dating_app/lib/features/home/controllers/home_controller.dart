import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_urls.dart';
import '../../../core/network/network_api_service.dart';
import '../../auth/controllers/auth_controller.dart';

class HomeController extends GetxController {
  final RxInt selectedTabIndex = 0.obs;
  final RxInt notificationsCount = 0.obs;

  // Collapsible stories panel state
  final RxBool storyRailOpen = false.obs;
  final RxString storyRailSide = 'left'.obs; // 'left' or 'right'
  final RxDouble storyHandleY = 220.0.obs;

  // Active story viewer states
  final RxnString activeStoryOwner = RxnString();
  final RxnInt activeStoryIndex = RxnInt();
  final RxDouble storyProgress = 0.0.obs;
  final RxBool storyPaused = false.obs;
  Timer? _storyTimer;
  final TextEditingController storyReplyController = TextEditingController();
  final RxString reactionBurst = ''.obs;
  final RxDouble reactionScale = 0.0.obs;

  // Local stories list cache
  final RxList<Map<String, dynamic>> stories = <Map<String, dynamic>>[].obs;
  final RxBool storyUploading = false.obs;

  // Coin and daily reward states
  final RxInt coinBalance = 0.obs;
  final RxBool dailyRewardOpen = false.obs;
  final Rxn<Map<String, dynamic>> dailyRewardData = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    loadCoinBalance();
    checkDailyReward();
    loadStoriesMock();
  }

  @override
  void onClose() {
    _storyTimer?.cancel();
    storyReplyController.dispose();
    super.onClose();
  }

  void changeTab(int index) {
    selectedTabIndex.value = index;
  }

  void updateNotificationsCount(int count) {
    notificationsCount.value = count;
  }

  void loadCoinBalance() async {
    try {
      final res = await NetworkApiService.instance.get(ApiUrls.wallet);
      final w = res.data as Map<String, dynamic>;
      coinBalance.value = (w['purchased_coins'] as num? ?? 0).toInt() + (w['bonus_coins'] as num? ?? 0).toInt();
    } catch (_) {}
  }

  void checkDailyReward() async {
    try {
      final res = await NetworkApiService.instance.post(ApiUrls.claimDailyReward);
      dailyRewardData.value = res.data as Map<String, dynamic>;
      dailyRewardOpen.value = true;
      loadCoinBalance();
    } catch (_) {}
  }

  void loadStoriesMock() {
    // Generate dummy active story groups for testing rail
    stories.assignAll([
      {
        'id': 'st_1',
        'author_id': '101',
        'author_name': 'Arjun',
        'author_avatar_url': '',
        'media_url': 'https://picsum.photos/1080/1920?random=1',
        'mine': false,
        'viewed': false,
        'created_at': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
      },
      {
        'id': 'st_2',
        'author_id': '102',
        'author_name': 'Sneha',
        'author_avatar_url': '',
        'media_url': 'https://picsum.photos/1080/1920?random=2',
        'mine': false,
        'viewed': true,
        'created_at': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
      }
    ]);
  }

  void toggleStoryRail() {
    storyRailOpen.value = !storyRailOpen.value;
  }

  void chooseStoryAudience() {
    Get.bottomSheet(
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(20.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text('Story Audience', style: TextStyle(color: AppColors.text, fontSize: 16.0, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6.0),
              const Text('Choose who can view this photo story.', style: TextStyle(color: AppColors.muted, fontSize: 12.0)),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.public, color: AppColors.text),
                title: const Text('Public', style: TextStyle(color: AppColors.text)),
                onTap: () { Get.back(); addStory('public'); },
              ),
              ListTile(
                leading: const Icon(Icons.people, color: AppColors.text),
                title: const Text('Followers', style: TextStyle(color: AppColors.text)),
                onTap: () { Get.back(); addStory('followers'); },
              ),
              ListTile(
                leading: const Icon(Icons.star, color: AppColors.primary),
                title: const Text('Close Circle', style: TextStyle(color: AppColors.text)),
                onTap: () { Get.back(); addStory('close_circle'); },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void addStory(String audience) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (image == null) return;

      storyUploading.value = true;

      final uploadResp = await NetworkApiService.instance.uploadFile(ApiUrls.uploads, File(image.path));
      final fileUrl = uploadResp.data['url'] as String;

      final storyResp = await NetworkApiService.instance.post(ApiUrls.stories, data: {
        'media_url': fileUrl,
        'audience': audience,
      });

      final authController = Get.find<AuthController>();
      stories.insert(0, {
        'id': storyResp.data['id'].toString(),
        'author_id': authController.currentUserId.value,
        'author_name': authController.profile.value?.name ?? 'You',
        'author_avatar_url': authController.profile.value?.avatarUrl,
        'media_url': fileUrl,
        'mine': true,
        'viewed': true,
        'created_at': DateTime.now().toIso8601String(),
      });

      Get.snackbar('Story uploaded! 📸', 'Your photo has been added to stories.');
    } catch (e) {
      Get.snackbar('Upload failed', e.toString());
    } finally {
      storyUploading.value = false;
    }
  }

  void openStory(String authorId) {
    final authorStories = stories.where((s) => s['author_id'] == authorId).toList();
    if (authorStories.isEmpty) return;

    final firstUnseenIndex = authorStories.indexWhere((s) => s['viewed'] == false);

    activeStoryOwner.value = authorId;
    activeStoryIndex.value = firstUnseenIndex != -1 ? firstUnseenIndex : 0;
    storyProgress.value = 0.0;
    storyPaused.value = false;

    _startStoryTimer();
  }

  void _startStoryTimer() {
    _storyTimer?.cancel();
    _storyTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (storyPaused.value) return;

      if (storyProgress.value < 0.98) {
        storyProgress.value += 0.02;
      } else {
        nextStory();
      }
    });
  }

  void nextStory() {
    final authorStories = stories.where((s) => s['author_id'] == activeStoryOwner.value).toList();
    if (activeStoryIndex.value! < authorStories.length - 1) {
      activeStoryIndex.value = activeStoryIndex.value! + 1;
      storyProgress.value = 0.0;
    } else {
      closeStoryViewer();
    }
  }

  void prevStory() {
    if (activeStoryIndex.value! > 0) {
      activeStoryIndex.value = activeStoryIndex.value! - 1;
      storyProgress.value = 0.0;
    }
  }

  void closeStoryViewer() {
    _storyTimer?.cancel();
    activeStoryOwner.value = null;
    activeStoryIndex.value = null;
    storyProgress.value = 0.0;
  }

  void reactToStory(String emoji) {
    reactionBurst.value = emoji;
    reactionScale.value = 0.0;
    
    // Spring scaling simulation
    Timer(const Duration(milliseconds: 50), () {
      reactionScale.value = 1.35;
    });
    Timer(const Duration(milliseconds: 200), () {
      reactionScale.value = 1.0;
    });
    Timer(const Duration(milliseconds: 800), () {
      reactionBurst.value = '';
    });
  }

  void deleteStory(String storyId) {
    stories.removeWhere((s) => s['id'] == storyId);
    closeStoryViewer();
  }
}
