import 'package:get/get.dart';
import '../repositories/notification_repository.dart';

class NotificationsController extends GetxController {
  final NotificationRepository _notificationRepo = NotificationRepository();

  final RxList items = [].obs;
  final RxBool loading = false.obs;

  @override
  void onInit() {
    super.onInit();
    loadNotifications();
  }

  Future<void> loadNotifications() async {
    loading.value = true;
    try {
      final list = await _notificationRepo.list();
      items.assignAll(list);
    } catch (e) {
      Get.snackbar('Notifications unavailable', e.toString());
    } finally {
      loading.value = false;
    }
  }

  Future<void> markAllAsRead() async {
    try {
      await _notificationRepo.markAllRead();
      for (var item in items) {
        if (item is Map) {
          item['is_read'] = true;
        }
      }
      items.refresh();
      Get.snackbar('Success', 'All notifications marked as read.');
    } catch (e) {
      Get.snackbar('Action failed', e.toString());
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      await _notificationRepo.markRead(notificationId);
      final idx = items.indexWhere((item) => item['id']?.toString() == notificationId);
      if (idx != -1) {
        if (items[idx] is Map) {
          items[idx]['is_read'] = true;
          items.refresh();
        }
      }
    } catch (e) {
      Get.snackbar('Action failed', e.toString());
    }
  }

  Future<void> removeNotification(String id) async {
    try {
      await _notificationRepo.remove(id);
      items.removeWhere((item) => item['id']?.toString() == id);
      items.refresh();
    } catch (e) {
      Get.snackbar('Delete failed', e.toString());
      rethrow;
    }
  }
}
