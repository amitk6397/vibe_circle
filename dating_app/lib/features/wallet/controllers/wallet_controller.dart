import 'package:get/get.dart';
import '../repositories/wallet_repository.dart';
import '../../auth/controllers/auth_controller.dart';

class WalletController extends GetxController {
  final WalletRepository _walletRepo = WalletRepository();
  final AuthController _authController = Get.find<AuthController>();

  final RxMap dashboard = {}.obs;
  final RxBool loading = false.obs;
  final RxString period = '30d'.obs;
  final RxList packages = [].obs;
  final RxString buyingId = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadDashboard();
    loadPackages();
  }

  Future<void> loadDashboard() async {
    loading.value = true;
    try {
      final res = await _walletRepo.dashboard(period.value);
      dashboard.value = res;
    } catch (_) {
      // Setup mock default fallback
      dashboard.value = {
        'currentCoins': _authController.coins.value,
        'totalSpent': 0,
        'totalEarned': 0,
        'availableToWithdraw': 0,
        'purchasedCoins': _authController.coins.value,
        'bonusCoins': 0,
        'history': [],
      };
    } finally {
      loading.value = false;
    }
  }

  Future<void> loadPackages() async {
    try {
      final list = await _walletRepo.packages();
      packages.value = list;
    } catch (_) {
      // Fallback fallback mock list
      packages.value = [
        {
          'id': 'pack_100',
          'name': 'Starter Pack',
          'purchasedCoins': 100,
          'bonusCoins': 0,
          'price': '0.99',
          'currency': '\$',
        },
        {
          'id': 'pack_500',
          'name': 'Value Pack',
          'purchasedCoins': 500,
          'bonusCoins': 50,
          'price': '4.99',
          'currency': '\$',
        },
        {
          'id': 'pack_1000',
          'name': 'Super Pack',
          'purchasedCoins': 1000,
          'bonusCoins': 150,
          'price': '9.99',
          'currency': '\$',
        },
        {
          'id': 'pack_5000',
          'name': 'Mega Pack',
          'purchasedCoins': 5000,
          'bonusCoins': 1000,
          'price': '49.99',
          'currency': '\$',
        }
      ];
    }
  }

  Future<void> buyPackage(String packageId) async {
    buyingId.value = packageId;
    try {
      final String dummyTx = 'dummy_${DateTime.now().millisecondsSinceEpoch}_$packageId';
      await _walletRepo.buyCoins(packageId, dummyTx);
      await _authController.bootstrap(); // Reload wallet/profile coins
      await loadDashboard();
    } finally {
      buyingId.value = '';
    }
  }

  void changePeriod(String newPeriod) {
    period.value = newPeriod;
    loadDashboard();
  }
}
