import 'package:get/get.dart';
import '../models/api_user.dart';
import '../repositories/auth_repository.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/network/websocket_service.dart';
import '../../wallet/repositories/wallet_repository.dart';

class AuthController extends GetxController {
  final AuthRepository _authRepo = AuthRepository();
  final WalletRepository _walletRepo = WalletRepository();

  // Reactive State variables
  final RxBool authenticated = false.obs;
  final RxnString currentUserId = RxnString();
  final Rxn<ApiUser> profile = Rxn<ApiUser>();
  final RxBool loading = false.obs;
  final RxnString apiError = RxnString();
  final RxList<String> blockedUsers = <String>[].obs;
  final RxInt coins = 0.obs;

  @override
  void onInit() {
    super.onInit();
    currentUserId.value = LocalStorage.instance.getCurrentUserId();
    bootstrap();
  }

  // Bootstrap logic
  Future<void> bootstrap() async {
    loading.value = true;
    apiError.value = null;
    try {
      final user = await _authRepo.restore();
      if (user == null) {
        authenticated.value = false;
        loading.value = false;
        return;
      }

      authenticated.value = true;
      currentUserId.value = user.id;
      await LocalStorage.instance.setCurrentUserId(user.id);
      profile.value = user;

      try {
        final walletData = await _walletRepo.getWallet();
        coins.value = (walletData['coins'] as num?)?.toInt() ?? 0;
      } catch (_) {}

      loading.value = false;
    } catch (e) {
      if (e.toString().contains('unauthorized')) {
        authenticated.value = false;
      }
      loading.value = false;
      apiError.value = e.toString();
    }
  }

  // Login action
  Future<void> login(String email, String password) async {
    loading.value = true;
    apiError.value = null;
    try {
      final data = await _authRepo.login(email, password);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      await LocalStorage.instance.saveTokens(accessToken, refreshToken);
      
      authenticated.value = true;
      await bootstrap();
    } catch (e) {
      loading.value = false;
      apiError.value = e.toString();
      rethrow;
    }
  }

  // Register action
  Future<void> register(Map<String, dynamic> payload) async {
    loading.value = true;
    apiError.value = null;
    try {
      final data = await _authRepo.register(payload);
      final accessToken = data['access_token'] as String;
      final refreshToken = data['refresh_token'] as String;
      await LocalStorage.instance.saveTokens(accessToken, refreshToken);
      
      authenticated.value = true;
      await bootstrap();
    } catch (e) {
      loading.value = false;
      apiError.value = e.toString();
      rethrow;
    }
  }

  // Logout action
  Future<void> logout() async {
    loading.value = true;
    try {
      final refreshToken = await LocalStorage.instance.getRefreshToken();
      if (refreshToken != null) {
        await _authRepo.logout(refreshToken);
      }
    } catch (_) {
      // Ignore network errors on logout
    } finally {
      await LocalStorage.instance.clearAll();
      WebSocketService.instance.closeAll();
      authenticated.value = false;
      currentUserId.value = null;
      profile.value = null;
      loading.value = false;
    }
  }

  void updateProfile(ApiUser newUser) {
    profile.value = newUser;
  }
}
