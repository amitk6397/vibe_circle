import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../../profile/repositories/user_repository.dart';

class ConnectionRequestView extends StatefulWidget {
  const ConnectionRequestView({super.key});

  @override
  State<ConnectionRequestView> createState() => _ConnectionRequestViewState();
}

class _ConnectionRequestViewState extends State<ConnectionRequestView> {
  final UserRepository _userRepo = UserRepository();
  final AuthController _authController = Get.find<AuthController>();
  final DiscoveryController _discoveryController =
      Get.find<DiscoveryController>();

  final List<dynamic> _requests = [];
  final Map<String, dynamic> _requesters = {};
  bool _loading = true;
  String _error = '';
  String _busyAction = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    final String? myId = _authController.currentUserId.value;
    if (myId == null) {
      setState(() {
        _error = 'Session missing. Log in again.';
        _loading = false;
      });
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
          .toList();

      setState(() {
        _requests.clear();
        _requests.addAll(pending);
      });

      // Enrich missing requesters in background
      for (var req in pending) {
        final reqId = req['requester_id'].toString();
        // Check if already in cache/controller
        final exists = _discoveryController.people.any((p) => p.id == reqId);
        if (!exists && !_requesters.containsKey(reqId)) {
          try {
            final u = await _userRepo.publicProfile(reqId);
            setState(() {
              _requesters[reqId] = u;
            });
          } catch (_) {}
        }
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _respond(dynamic request, String action) async {
    final String reqId = request['id'].toString();
    setState(() => _busyAction = '$reqId:$action');

    try {
      await _userRepo.connectionAction(reqId, action);
      setState(() {
        _requests.removeWhere((item) => item['id'].toString() == reqId);
      });
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
      setState(() => _busyAction = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Follow requests',
        subtitle: 'People who want to follow you',
        onBack: () => Get.back(),
      ),
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error.isNotEmpty
          ? AppEmptyState(
              icon: Icons.cloud_off,
              title: 'Could not load requests',
              text: _error,
              action: 'Try again',
              onAction: _load,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ..._requests.map((item) {
                  final reqId = item['requester_id'].toString();
                  final String? requestId = item['id']?.toString();

                  // Get enriched sender details
                  final localPerson = _discoveryController.people
                      .firstWhereOrNull((p) => p.id == reqId);
                  final String name =
                      localPerson?.name ?? _requesters[reqId]?.name ?? 'User';
                  final String age =
                      localPerson?.age.toString() ??
                      _requesters[reqId]?.age?.toString() ??
                      '18';
                  final String location =
                      localPerson?.city ?? _requesters[reqId]?.city ?? 'Local';

                  final bool isAccepting = _busyAction == '$requestId:accept';
                  final bool isRejecting = _busyAction == '$requestId:reject';

                  return Padding(
                    padding: const EdgeInsets.only(
                      bottom: 12.0,
                      left: 16.0,
                      right: 16.0,
                    ),
                    child: AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              AppAvatar(name: name, size: 40.0),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$name, $age',
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    Text(
                                      location,
                                      style: const TextStyle(
                                        color: AppColors.muted,
                                        fontSize: 12.0,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12.0),
                          Row(
                            children: [
                              Expanded(
                                child: AppButton(
                                  title: 'Accept',
                                  tone: AppButtonTone.primary,
                                  loading: isAccepting,
                                  onPressed: () => _respond(item, 'accept'),
                                ),
                              ),
                              const SizedBox(width: 8.0),
                              Expanded(
                                child: AppButton(
                                  title: 'Reject',
                                  tone: AppButtonTone.secondary,
                                  loading: isRejecting,
                                  onPressed: () => _respond(item, 'reject'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                if (_requests.isEmpty)
                  const AppEmptyState(
                    icon: Icons.people_outline,
                    title: 'No follow requests',
                    text: 'New follow requests will appear here.',
                  ),
              ],
            ),
    );
  }
}
