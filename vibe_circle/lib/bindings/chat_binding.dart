import 'package:get/get.dart';
import '../features/chat/controllers/chat_controller.dart';
import '../features/chat/controllers/inbox_controller.dart';

class ChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatController>(() => ChatController());
    Get.lazyPut<InboxController>(() => InboxController());
  }
}
