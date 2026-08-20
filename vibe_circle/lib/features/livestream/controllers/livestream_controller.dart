import 'package:get/get.dart';
import '../../../core/constants/api_urls.dart';
import '../../../core/network/network_api_service.dart';

class LivestreamController extends GetxController {
  final NetworkApiService _api = NetworkApiService.instance;

  final RxList<Map<String, dynamic>> streams = <Map<String, dynamic>>[].obs;
  final RxBool loading = true.obs;
  final RxBool refreshing = false.obs;
  final RxString activeCategory = 'All'.obs;

  final List<String> categories = const [
    'All',
    'Gaming',
    'Music',
    'Fitness',
    'Talk',
    'Art',
    'Education',
  ];

  @override
  void onInit() {
    super.onInit();
    loadStreams();
  }

  Future<void> loadStreams({bool isRefresh = false}) async {
    if (isRefresh) {
      refreshing.value = true;
    } else {
      loading.value = true;
    }

    try {
      final res = await _api.get(ApiUrls.livestreamActive);
      final data = res.data;
      if (data is List) {
        streams.assignAll(data.map((e) => Map<String, dynamic>.from(e as Map)).toList());
      } else {
        streams.clear();
      }
    } catch (_) {
      streams.clear();
    } finally {
      loading.value = false;
      refreshing.value = false;
    }
  }

  List<Map<String, dynamic>> get filteredStreams {
    if (activeCategory.value == 'All') return streams;
    return streams.where((s) => s['category'] == activeCategory.value).toList();
  }

  void setCategory(String category) {
    activeCategory.value = category;
  }
}
