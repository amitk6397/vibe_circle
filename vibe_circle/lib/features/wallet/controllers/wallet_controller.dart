import 'package:get/get.dart';
import '../models/wallet_dashboard_model.dart';
import '../models/wallet_transaction_model.dart';
import '../models/coin_package_model.dart';
import '../models/referral_info_model.dart';
import '../repositories/wallet_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class WalletController extends GetxController {
  final WalletRepository _walletRepo = WalletRepository();
  final AuthController _authController = Get.find<AuthController>();

  final Rxn<WalletDashboard> dashboard = Rxn<WalletDashboard>();
  final RxBool loading = false.obs;
  final RxString period = '30d'.obs;
  final RxnString selectedDay = RxnString();
  final RxList<CoinPackage> packages = <CoinPackage>[].obs;
  final RxString buyingId = ''.obs;

  final RxList<WalletTransaction> transactions = <WalletTransaction>[].obs;
  final RxBool transactionsLoading = false.obs;
  final RxBool hasMoreTransactions = false.obs;
  final Rxn<ReferralInfo> referralInfo = Rxn<ReferralInfo>();

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    loadPackages();
    loadTransactions();
  }

  Future<void> loadDashboard() async {
    loading.value = true;
    try {
      final dashRes = await _walletRepo.dashboard(period.value);
      dashboard.value = dashRes;
      
      try {
        final refRes = await _walletRepo.getReferralInfo();
        referralInfo.value = refRes;
      } catch (_) {}
    } catch (e) {
      // In case dashboard API error occurs, populate empty model
      dashboard.value ??= WalletDashboard(
        currentCoins: _authController.coins.value,
      );
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadTransactions({bool refresh = true}) async {
    if (refresh) transactionsLoading.value = true;
    try {
      final list = await _walletRepo.transactions();
      transactions.assignAll(list);
      hasMoreTransactions.value = list.length >= 20;
    } catch (_) {
      // Keep existing transactions or empty
    } finally {
      transactionsLoading.value = false;
    }
  }

  Future<void> loadPackages() async {
    try {
      final list = await _walletRepo.packages();
      packages.assignAll(list);
    } catch (_) {}
  }

  Future<void> buyPackage(String packageId) async {
    buyingId.value = packageId;
    try {
      final String dummyTx = 'tx_${DateTime.now().millisecondsSinceEpoch}_$packageId';
      await _walletRepo.buyCoins(packageId, dummyTx);
      await _authController.bootstrap();
      await loadDashboard();
      await loadTransactions();
      Get.snackbar('Coins Added! 🪙', 'Your coin balance has been updated.');
    } catch (e) {
      Get.snackbar('Purchase Failed', e.toString());
    } finally {
      buyingId.value = '';
    }
  }

  void changePeriod(String newPeriod) {
    period.value = newPeriod;
    selectedDay.value = null;
    loadDashboard();
  }
}
