import 'package:get/get.dart';
import '../features/discovery/controllers/discovery_controller.dart';

class DiscoveryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<DiscoveryController>(() => DiscoveryController());
  }
}
