import '../../core/network/network_api_service.dart';
import '../../core/constants/api_urls.dart';

class WalletRepository {
  final NetworkApiService _apiService = NetworkApiService.instance;

  Future<List<dynamic>> packages() async {
    final response = await _apiService.get(ApiUrls.coinPackages);
    return response.data as List? ?? [];
  }

  Future<Map<String, dynamic>> buyCoins(String packageId, String transactionId) async {
    final response = await _apiService.post(ApiUrls.buyCoins, data: {
      'package_id': packageId,
      'transaction_id': transactionId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getWallet() async {
    final response = await _apiService.get(ApiUrls.wallet);
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> claimDailyReward() async {
    final response = await _apiService.post(ApiUrls.claimDailyReward);
    return response.data as Map<String, dynamic>;
  }
}
