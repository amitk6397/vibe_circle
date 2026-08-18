import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/auth_repository.dart';
import 'auth_controller.dart';
import '../../../routes/app_routes.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/validators.dart';

class LoginController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final AuthController _authController = Get.find<AuthController>();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  final RxString error = ''.obs;
  final RxBool loading = false.obs;

  @override
  void onClose() {
    emailController.dispose();
    passwordController.dispose();
    super.onClose();
  }

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text;

    if (!Validators.isEmail(email)) {
      error.value = 'Enter a valid email address.';
      return;
    }
    final pwdErr = Validators.passwordError(password);
    if (pwdErr.isNotEmpty) {
      error.value = pwdErr;
      return;
    }

    error.value = '';
    loading.value = true;

    try {
      final data = await _authRepo.login(email.toLowerCase(), password);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      await LocalStorage.instance.saveTokens(accessToken, refreshToken);
      
      _authController.authenticated.value = true;
      await _authController.bootstrap();
      Get.offAllNamed(AppRoutes.MAIN);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}
