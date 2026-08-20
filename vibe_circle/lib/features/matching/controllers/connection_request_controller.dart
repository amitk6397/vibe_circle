import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/connection_request_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../../profile/repositories/user_repository.dart';
import '../../../core/constants/app_colors.dart';

class ConnectionRequestController extends GetxController {
  final UserRepository _userRepo = UserRepository();
  final AuthController _authController = Get.isRegistered<AuthController>()
      ? Get.find<AuthController>()
      : Get.put(AuthController());
  final DiscoveryController _discoveryController = Get.isRegistered<DiscoveryController>()
      ? Get.find<DiscoveryController>()
      : Get.put(DiscoveryController());

  final RxList<ConnectionRequestItem> requests = <ConnectionRequestItem>[].obs;
  final RxBool loading = false.obs;
  final RxString error = ''.obs;
  final RxString busyAction = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadRequests();
  }

  Future<void> loadRequests() async {
    loading.value = true;
    error.value = '';

    final String? myId = _authController.currentUserId.value;
    if (myId == null) {
      error.value = 'Session missing. Log in again.';
      loading.value = false;
      return;
    }

    try {
      final list = await _userRepo.connections();
      final pending = list
          .where(
            (item) =>
                item['status'] == 'pending' &&
                item['receiver_id'].toString() == myId,
          )
          .map((item) => ConnectionRequestItem.fromJson(item as Map<String, dynamic>))
          .toList();

      requests.assignAll(pending);

      // Enrich missing requesters from repository / discovery
      for (int i = 0; i < requests.length; i++) {
        final req = requests[i];
        final person = _discoveryController.people.firstWhereOrNull((p) => p.id == req.requesterId);
        if (person != null) {
          requests[i] = req.copyWith(
            requesterName: person.name,
            requesterAvatar: person.avatarUrl,
            requesterBio: person.bio,
            requesterCity: person.city,
            requesterInterests: person.interests,
          );
        } else {
          try {
            final u = await _userRepo.publicProfile(req.requesterId);
            requests[i] = req.copyWith(
              requesterName: u.name,
              requesterAvatar: u.avatarUrl,
              requesterBio: u.bio,
              requesterCity: u.city,
              requesterInterests: u.interests,
            );
          } catch (_) {}
        }
      }
    } catch (e) {
      error.value = e.toString();
    } finally {
      loading.value = false;
    }
  }

  Future<void> respond(ConnectionRequestItem request, String action) async {
    busyAction.value = '${request.id}:$action';

    try {
      await _userRepo.connectionAction(request.id, action);
      requests.removeWhere((item) => item.id == request.id);

      Get.snackbar(
        action == 'accept' ? 'Request Accepted' : 'Request Declined',
        action == 'accept'
            ? 'You accepted their follow request.'
            : 'Request removed.',
        backgroundColor: action == 'accept'
            ? AppColors.primary
            : AppColors.surfaceAlt,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Could not update request', e.toString());
    } finally {
      busyAction.value = '';
    }
  }
}
