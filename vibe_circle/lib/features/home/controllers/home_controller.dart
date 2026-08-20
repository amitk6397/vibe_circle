import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_urls.dart';
import '../../../core/network/network_api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/story_model.dart';

class HomeController extends GetxController {
  final RxInt selectedTabIndex = 0.obs;
  final RxInt notificationsCount = 0.obs;

  // Collapsible stories panel state
  final RxBool storyRailOpen = false.obs;
  final RxString storyRailSide = 'left'.obs; // 'left' or 'right'
  final RxDouble storyHandleY = 220.0.obs;
  final RxDouble storyHandleX = 0.0.obs;

  // Floating Action Button expanded menu state
  final RxBool fabOpen = false.obs;

  void toggleFab() => fabOpen.value = !fabOpen.value;
  void closeFab() => fabOpen.value = false;

  // Active story viewer states
  final RxnString activeStoryOwner = RxnString();
  final RxnInt activeStoryIndex = RxnInt();
  final RxDouble storyProgress = 0.0.obs;
  final RxBool storyPaused = false.obs;
  Timer? _storyTimer;
  final TextEditingController storyReplyController = TextEditingController();
  final RxString reactionBurst = ''.obs;
  final RxDouble reactionScale = 0.0.obs;
  final RxBool viewersOpen = false.obs;

  // Typed stories list
  final RxList<StoryItem> stories = <StoryItem>[].obs;
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
    loadStories();
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
      coinBalance.value =
          (w['purchased_coins'] as num? ?? 0).toInt() +
          (w['bonus_coins'] as num? ?? 0).toInt();
    } catch (_) {}
  }

  void checkDailyReward() async {
    try {
      final res = await NetworkApiService.instance.post(
        ApiUrls.claimDailyReward,
      );
      dailyRewardData.value = res.data as Map<String, dynamic>;
      dailyRewardOpen.value = true;
      loadCoinBalance();
    } catch (_) {}
  }

  Future<void> loadStories() async {
    try {
      final res = await NetworkApiService.instance.get(ApiUrls.stories);
      final list = res.data as List? ?? [];
      final parsed = list
          .map((e) => StoryItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      stories.assignAll(parsed);
    } catch (_) {
      // Handled cleanly via live endpoint
    }
  }

  // Group stories by author_id so multiple stories from 1 user are grouped into 1 circle
  List<StoryGroup> get storyGroups {
    final Map<String, StoryGroup> groups = {};

    for (final story in stories) {
      final String authorId = story.authorId;
      if (!groups.containsKey(authorId)) {
        groups[authorId] = StoryGroup(
          authorId: authorId,
          authorName: story.authorName,
          authorAvatarUrl: story.authorAvatarUrl,
          mine: story.mine,
          stories: <StoryItem>[],
        );
      }
      groups[authorId]!.stories.add(story);
    }

    final list = groups.values.toList();
    // Sort so user's own story group appears first
    list.sort((a, b) {
      final aMine = a.mine ? 1 : 0;
      final bMine = b.mine ? 1 : 0;
      return bMine.compareTo(aMine);
    });
    return list;
  }

  void toggleStoryRail() {
    storyRailOpen.value = !storyRailOpen.value;
  }

  void chooseStoryAudience() {
    Get.defaultDialog(
      title: 'Story audience',
      middleText: 'Choose who can view this story.',
      actions: [
        TextButton(
          onPressed: () {
            Get.back();
            addStory('public');
          },
          child: const Text('Public'),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            addStory('followers');
          },
          child: const Text('Followers'),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            addStory('close_circle');
          },
          child: const Text('Close Circle'),
        ),
        TextButton(
          onPressed: () {
            Get.back();
            addStory('paid_supporters');
          },
          child: const Text('Paid supporters'),
        ),
        TextButton(
          onPressed: () => Get.back(),
          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
        ),
      ],
    );
  }

  void addStory(String audience) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      storyUploading.value = true;

      final uploadResp = await NetworkApiService.instance.uploadFile(
        ApiUrls.uploads,
        File(image.path),
      );
      final fileUrl = uploadResp.data['url'] as String;

      final storyResp = await NetworkApiService.instance.post(
        ApiUrls.stories,
        data: {'media_url': fileUrl, 'audience': audience},
      );

      final authController = Get.find<AuthController>();
      final newStory = StoryItem(
        id: storyResp.data != null && storyResp.data['id'] != null
            ? storyResp.data['id'].toString()
            : 'st_${DateTime.now().millisecondsSinceEpoch}',
        authorId: authController.currentUserId.value ?? '',
        authorName: authController.profile.value?.name ?? 'You',
        authorAvatarUrl: authController.profile.value?.avatarUrl,
        mediaUrl: fileUrl,
        mine: true,
        viewed: true,
        viewCount: 0,
        createdAt: DateTime.now().toIso8601String(),
        audience: audience,
      );

      stories.insert(0, newStory);
      Get.snackbar(
        'Story uploaded! 📸',
        'Your photo has been added to stories.',
      );
    } catch (e) {
      Get.snackbar('Upload failed', e.toString());
    } finally {
      storyUploading.value = false;
    }
  }

  void openStory(String authorId) {
    final authorStories = stories.where((s) => s.authorId == authorId).toList();
    if (authorStories.isEmpty) return;

    // Smart unseen start: find first unviewed story in this author's group
    final firstUnseenIndex = authorStories.indexWhere((s) => s.viewed == false);

    activeStoryOwner.value = authorId;
    activeStoryIndex.value = firstUnseenIndex != -1 ? firstUnseenIndex : 0;
    storyProgress.value = 0.0;
    storyPaused.value = false;

    // Mark current story as viewed
    _markStoryViewed(authorStories[activeStoryIndex.value!]);
    _startStoryTimer();
  }

  void _markStoryViewed(StoryItem story) {
    if (story.viewed != true && story.mine != true) {
      story.viewed = true;
      final storyId = story.id;
      NetworkApiService.instance
          .post('/feed/stories/$storyId/view')
          .catchError((_) => null);
    }
  }

  void _startStoryTimer() {
    _storyTimer?.cancel();
    _storyTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (storyPaused.value) return;

      if (storyProgress.value < 0.98) {
        storyProgress.value += 0.02; // 5 seconds total (50 ticks * 100ms)
      } else {
        nextStory();
      }
    });
  }

  void nextStory() {
    final authorStories = stories
        .where((s) => s.authorId == activeStoryOwner.value)
        .toList();
    if (activeStoryIndex.value != null &&
        activeStoryIndex.value! < authorStories.length - 1) {
      activeStoryIndex.value = activeStoryIndex.value! + 1;
      storyProgress.value = 0.0;
      _markStoryViewed(authorStories[activeStoryIndex.value!]);
    } else {
      closeStoryViewer();
    }
  }

  void prevStory() {
    if (activeStoryIndex.value != null && activeStoryIndex.value! > 0) {
      activeStoryIndex.value = activeStoryIndex.value! - 1;
      storyProgress.value = 0.0;
    }
  }

  void closeStoryViewer() {
    _storyTimer?.cancel();
    activeStoryOwner.value = null;
    activeStoryIndex.value = null;
    storyProgress.value = 0.0;
    viewersOpen.value = false;
  }

  void reactToStory(String storyId, String emoji) async {
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

    try {
      await NetworkApiService.instance.post(
        '/feed/stories/$storyId/reactions',
        data: {'emoji': emoji},
      );
    } catch (_) {}
  }

  void replyToStory(String storyId) async {
    final text = storyReplyController.text.trim();
    if (text.isEmpty) return;

    storyReplyController.clear();
    try {
      await NetworkApiService.instance.post(
        '/feed/stories/$storyId/replies',
        data: {'text': text},
      );
      Get.snackbar(
        'Reply Sent! 💬',
        'Your message has been sent to the author.',
      );
    } catch (e) {
      Get.snackbar('Reply failed', e.toString());
    }
  }

  void deleteStory(String storyId) async {
    stories.removeWhere((s) => s.id == storyId);
    closeStoryViewer();
    try {
      await NetworkApiService.instance.delete('/feed/stories/$storyId');
      Get.snackbar('Deleted', 'Story has been removed.');
    } catch (_) {}
  }
}
