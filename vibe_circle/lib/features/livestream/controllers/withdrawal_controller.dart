import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/api_urls.dart';
import '../../../core/network/network_api_service.dart';

class WithdrawalController extends GetxController {
  final NetworkApiService _api = NetworkApiService.instance;

  final TextEditingController amountController = TextEditingController();
  final TextEditingController referenceController = TextEditingController();

  final RxBool saving = false.obs;
  final RxBool loading = false.obs;
  final RxList<Map<String, dynamic>> withdrawals = <Map<String, dynamic>>[].obs;
  final RxDouble availableBalance = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadWithdrawals();
  }

  @override
  void onClose() {
    amountController.dispose();
    referenceController.dispose();
    super.onClose();
  }

  Future<void> loadWithdrawals() async {
    loading.value = true;
    try {
      final res = await _api.get(ApiUrls.withdrawals);
      if (res.data is Map) {
        final map = res.data as Map;
        availableBalance.value = (map['available_balance'] as num?)?.toDouble() ?? 0.0;
        final list = map['withdrawals'] as List? ?? [];
        withdrawals.assignAll(list.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else if (res.data is List) {
        withdrawals.assignAll((res.data as List).map((e) => Map<String, dynamic>.from(e as Map)).toList());
      }
    } catch (_) {} finally {
      loading.value = false;
    }
  }

  Future<void> submit() async {
    final amt = double.tryParse(amountController.text.trim());
    final ref = referenceController.text.trim();
    if (amt == null || amt <= 0 || ref.isEmpty) {
      Get.snackbar('Invalid Input', 'Please enter a valid amount and payout reference.');
      return;
    }

    saving.value = true;
    try {
      await _api.post(ApiUrls.withdrawals, data: {
        'amount': amt,
        'reference': ref,
      });
      amountController.clear();
      referenceController.clear();
      Get.snackbar('Withdrawal Requested! 💰', 'Your request has been submitted for review.');
      await loadWithdrawals();
    } catch (e) {
      Get.snackbar('Withdrawal Failed', e.toString());
    } finally {
      saving.value = false;
    }
  }
}
