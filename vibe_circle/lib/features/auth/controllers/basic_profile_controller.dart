import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import 'auth_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../core/models/local_attachment.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';
import '../../../routes/app_routes.dart';

class BasicProfileController extends GetxController {
  final AuthController _authController = Get.find<AuthController>();

  final usernameController = TextEditingController();
  final dobController = TextEditingController();
  final genderController = TextEditingController();

  final RxList<String> selectedInterests = <String>[].obs;
  final RxList<String> selectedLanguages = <String>[].obs;
  final RxList<String> selectedTopics = <String>[].obs;

  final Rxn<LocalAttachment> avatar = Rxn<LocalAttachment>();
  final RxString error = ''.obs;
  final RxBool saving = false.obs;

  @override
  void onInit() {
    super.onInit();
    final profile = _authController.profile.value;
    if (profile != null) {
      usernameController.text = profile.username ?? '';
      dobController.text = profile.dateOfBirth ?? '';
      genderController.text = profile.gender ?? '';
      selectedInterests.addAll(profile.interests);
      selectedLanguages.addAll(profile.languages);
      selectedTopics.addAll(profile.conversationTopics!);
    }
  }

  @override
  void onClose() {
    usernameController.dispose();
    dobController.dispose();
    genderController.dispose();
    super.onClose();
  }

  Future<void> pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (image == null) return;

      avatar.value = LocalAttachment(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        kind: 'image',
        uri: image.path,
        name: image.name,
      );
    } catch (e) {
      error.value = 'Could not select photo: ${e.toString()}';
    }
  }

  void toggleInterest(String value) {
    if (selectedInterests.contains(value)) {
      selectedInterests.remove(value);
    } else {
      selectedInterests.add(value);
    }
  }

  void toggleLanguage(String value) {
    if (selectedLanguages.contains(value)) {
      selectedLanguages.remove(value);
    } else {
      selectedLanguages.add(value);
    }
  }

  void toggleTopic(String value) {
    if (selectedTopics.contains(value)) {
      selectedTopics.remove(value);
    } else {
      selectedTopics.add(value);
    }
  }

  Future<void> finish() async {
    final username = usernameController.text.trim();
    final dob = dobController.text.trim();
    final gender = genderController.text.trim();

    final userErr = Validators.usernameError(username);
    if (userErr.isNotEmpty) {
      error.value = userErr;
      return;
    }

    if (selectedInterests.isEmpty || selectedLanguages.isEmpty) {
      error.value = 'Choose at least one interest and one language.';
      return;
    }

    error.value = '';
    saving.value = true;

    try {
      String? avatarUrl;
      if (avatar.value != null) {
        final uploadResp = await NetworkApiService.instance.uploadFile(
          ApiUrls.uploads,
          File(avatar.value!.uri),
        );
        avatarUrl = uploadResp.data['url'] as String?;
      }

      final payload = {
        'username': username,
        'interests': selectedInterests,
        'languages': selectedLanguages,
        'conversation_topics': selectedTopics,
        if (dob.isNotEmpty) 'date_of_birth': dob,
        if (gender.isNotEmpty) 'gender': gender,
        'preferred_language': selectedLanguages.first,
        'avatar_url': ?avatarUrl,
      };

      await NetworkApiService.instance.patch(
        ApiUrls.updateProfile,
        data: payload,
      );
      await NetworkApiService.instance.patch(
        ApiUrls.updatePreferences,
        data: {
          'interests': selectedInterests,
          'languages': selectedLanguages,
          'conversation_topics': selectedTopics,
        },
      );

      // Reload global session info
      await _authController.bootstrap();
      Get.offAllNamed(AppRoutes.MAIN);
    } catch (e) {
      error.value = e.toString();
    } finally {
      saving.value = false;
    }
  }
}
