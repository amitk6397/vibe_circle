import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../repositories/auth_repository.dart';
import 'auth_controller.dart';
import '../../../core/utils/validators.dart';
import '../../../core/models/local_attachment.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';
import '../../../routes/app_routes.dart';

class RegisterController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final AuthController _authController = Get.find<AuthController>();

  final nameController = TextEditingController();
  final ageController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final referralController = TextEditingController();

  final Rxn<LocalAttachment> avatar = Rxn<LocalAttachment>();
  final RxString error = ''.obs;
  final RxBool loading = false.obs;

  @override
  void onClose() {
    nameController.dispose();
    ageController.dispose();
    emailController.dispose();
    passwordController.dispose();
    referralController.dispose();
    super.onClose();
  }

  Future<void> pickAvatar() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
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

  Future<void> register() async {
    final name = nameController.text.trim();
    final ageStr = ageController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final referral = referralController.text.trim();

    final nameMsg = Validators.requiredTextError(name, 'Name');
    if (nameMsg.isNotEmpty) {
      error.value = nameMsg;
      return;
    }

    if (!Validators.isEmail(email)) {
      error.value = 'Enter a valid email address.';
      return;
    }

    final pwdMsg = Validators.passwordError(password);
    if (pwdMsg.isNotEmpty) {
      error.value = pwdMsg;
      return;
    }

    final int? age = int.tryParse(ageStr);
    if (age == null || age < 18) {
      error.value = 'VibeCircle is currently available only for people aged 18+.';
      return;
    }

    error.value = '';
    loading.value = true;

    try {
      String? avatarUrl;
      if (avatar.value != null) {
        final uploadResp = await NetworkApiService.instance.uploadFile(
          ApiUrls.uploads,
          File(avatar.value!.uri),
        );
        avatarUrl = uploadResp.data['url'] as String?;
      }

      await _authController.register({
        'name': name,
        'age': age,
        'email': email.toLowerCase(),
        'password': password,
        'avatar_url': avatarUrl,
        if (referral.isNotEmpty) 'referral_code': referral.toUpperCase(),
      });

      Get.toNamed(AppRoutes.VERIFY_EMAIL, arguments: {'email': email});
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}

