import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/controllers/app_controller.dart';
import '../controllers/auth_controller.dart';
import '../../../routes/app_routes.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {
  final AppController _appController = Get.find<AppController>();
  final AuthController _authController = Get.find<AuthController>();
  StreamSubscription? _subscription;

  @override
  void initState() {
    super.initState();
    _checkSession();
  }

  void _checkSession() async {
    try {
      // 1. Wait for system/storage bootstrap
      if (!_appController.sessionReady.value) {
        await _appController.sessionReady.stream.firstWhere((ready) => ready == true).timeout(const Duration(seconds: 4));
      }

      // 2. Wait for auth bootstrap token check
      if (_authController.loading.value) {
        await _authController.loading.stream.firstWhere((loading) => loading == false).timeout(const Duration(seconds: 4));
      }
    } catch (_) {
      // Timeout fallback
    }

    if (mounted) {
      _navigate();
    }
  }

  void _navigate() {
    if (_authController.authenticated.value) {
      Get.offAllNamed(AppRoutes.MAIN);
    } else {
      Get.offAllNamed(AppRoutes.LOGIN);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: AppColors.primaryGradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96.0,
                height: 96.0,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(32.0),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.people,
                  size: 47.0,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 22.0),
              const Text(
                'VibeCircle',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 38.0,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 7.0),
              const Text(
                'Talk. Connect. Learn. Belong.',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 15.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
