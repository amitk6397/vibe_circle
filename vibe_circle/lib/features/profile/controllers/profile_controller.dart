import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../repositories/user_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/repositories/auth_repository.dart';

class ProfileController extends GetxController {
  final UserRepository _userRepo = UserRepository();
  final AuthRepository _authRepo = AuthRepository();
  final AuthController _authController = Get.find<AuthController>();

  final RxList connections = [].obs;
  final RxList reports = [].obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final RxString busyAction = ''.obs;
  final RxMap referralInfo = {}.obs;

  @override
  void onInit() {
    super.onInit();
    loadConnections();
  }

  Future<void> loadConnections() async {
    loading.value = true;
    error.value = '';
    try {
      final data = await _userRepo.connections();
      connections.value = data.where((item) => item['status'] == 'accepted').toList();
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadReferralInfo() async {
    loading.value = true;
    try {
      final res = await _authRepo.getReferralInfo();
      referralInfo.value = {
        'referralCode': res['referralCode'] ?? res['code'] ?? 'VIBE890',
        'totalReferrals': res['totalReferrals'] ?? res['invitedCount'] ?? 0,
        'totalCoinsEarned': res['totalCoinsEarned'] ?? res['earnedCoins'] ?? 0,
        'rewardPerReferral': res['rewardPerReferral'] ?? 50,
        'inviteeBonus': res['inviteeBonus'] ?? 20,
      };
    } catch (_) {
      referralInfo.value = {
        'referralCode': 'VIBE890',
        'totalReferrals': 4,
        'totalCoinsEarned': 200,
        'rewardPerReferral': 50,
        'inviteeBonus': 20,
      };
    } finally {
      loading.value = false;
    }
  }

  Future<void> unblockUser(String personId) async {
    try {
      await _userRepo.unblockUser(personId);
      _authController.blockedUsers.remove(personId);
      Get.snackbar('User Unblocked', 'They can now discover your profile.');
    } catch (e) {
      Get.snackbar('Action Failed', e.toString());
    }
  }

  Future<void> reportUser(String targetType, String targetId, String reason) async {
    try {
      await _userRepo.submitReport(targetType, targetId, reason);
      Get.snackbar('Report Submitted', 'Our safety team will review this report.');
    } catch (e) {
      Get.snackbar('Report Failed', e.toString());
    }
  }

  Future<void> exportAccountData() async {
    try {
      await _userRepo.exportData();
    } catch (e) {
      Get.snackbar('Error', 'Export failed: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  Future<void> logoutAllDevices() async {
    try {
      await _userRepo.logoutAll();
    } catch (e) {
      Get.snackbar('Error', 'Revoke failed: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  Future<void> deleteAccountPermanently() async {
    try {
      await _userRepo.deleteAccount();
      await _authController.logout();
      Get.offAllNamed('/login');
    } catch (e) {
      Get.snackbar('Error', 'Account deletion failed: $e',
          backgroundColor: Colors.red.withValues(alpha: 0.8), colorText: Colors.white);
    }
  }

  Future<void> loadReports() async {
    loading.value = true;
    error.value = '';
    try {
      final list = await _userRepo.myReports();
      reports.assignAll(list);
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }
}
