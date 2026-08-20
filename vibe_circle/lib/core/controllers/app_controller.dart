import 'package:get/get.dart';
import '../storage/local_storage.dart';

class AppController extends GetxController {
  final RxBool darkMode = true.obs;
  final RxBool sessionReady = false.obs;

  @override
  void onInit() {
    super.onInit();
    darkMode.value = LocalStorage.instance.getDarkMode();
    bootstrap();
  }

  void setDarkMode(bool val) {
    darkMode.value = val;
    LocalStorage.instance.setDarkMode(val);
  }

  Future<void> bootstrap() async {
    sessionReady.value = false;
    // Simulate initial system setup, database check, local key loading
    await Future.delayed(const Duration(milliseconds: 600));
    sessionReady.value = true;
  }
}
