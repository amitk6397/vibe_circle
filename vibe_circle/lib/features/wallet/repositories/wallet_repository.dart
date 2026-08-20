import '../../../core/network/network_api_service.dart';
import '../../../core/constants/api_urls.dart';
import '../models/wallet_dashboard_model.dart';
import '../models/wallet_transaction_model.dart';
import '../models/coin_package_model.dart';
import '../models/referral_info_model.dart';

class WalletRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<List<CoinPackage>> packages() async {
    final response = await _apiService.get(ApiUrls.coinPackages);
    final list = response.data as List? ?? [];
    return list.map((e) => CoinPackage.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<Map<String, dynamic>> buyCoins(String packageId, String transactionId) async {
    final response = await _apiService.post(ApiUrls.buyCoins, data: {
      'package_id': packageId,
      'transaction_id': transactionId,
    });
    return response.data is Map ? Map<String, dynamic>.from(response.data as Map) : {};
  }

  Future<Map<String, dynamic>> getWallet() async {
    final response = await _apiService.get(ApiUrls.wallet);
    return response.data is Map ? Map<String, dynamic>.from(response.data as Map) : {};
  }

  Future<Map<String, dynamic>> claimDailyReward() async {
    final response = await _apiService.post(ApiUrls.claimDailyReward);
    return response.data is Map ? Map<String, dynamic>.from(response.data as Map) : {};
  }

  Future<WalletDashboard> dashboard(String period) async {
    final response = await _apiService.get(ApiUrls.walletDashboard, queryParameters: {'period': period});
    final map = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};
    return WalletDashboard.fromJson(map);
  }

  Future<List<WalletTransaction>> transactions({String? before}) async {
    final response = await _apiService.get(
      ApiUrls.walletTransactions,
      queryParameters: before != null ? {'before': before} : null,
    );
    final list = response.data as List? ?? [];
    return list.map((e) => WalletTransaction.fromJson(Map<String, dynamic>.from(e as Map))).toList();
  }

  Future<ReferralInfo> getReferralInfo() async {
    final response = await _apiService.get(ApiUrls.referralInfo);
    final map = response.data is Map ? Map<String, dynamic>.from(response.data as Map) : <String, dynamic>{};
    return ReferralInfo.fromJson(map);
  }
}
