import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../../../routes/app_routes.dart';
import '../../discovery/widgets/person_card.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../controllers/profile_controller.dart';
import '../../discovery/models/person.dart';

class ConnectionsView extends StatefulWidget {
  const ConnectionsView({super.key});

  @override
  State<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends State<ConnectionsView> {
  final ProfileController _profileController = Get.find<ProfileController>();
  final AuthController _authController = Get.find<AuthController>();
  final DiscoveryController _discoveryController =
      Get.find<DiscoveryController>();

  String _activeTab = 'Followers'; // 'Followers' | 'Following'

  @override
  void initState() {
    super.initState();
    _profileController.loadConnections();
  }

  @override
  Widget build(BuildContext context) {
    final String? myId = _authController.currentUserId.value;

    return AppScreen(
      header: AppHeader(
        title: 'Connections',
        subtitle: 'People you follow or listen to',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Tabs followers vs following
            Row(
              children: [
                Expanded(
                  child: AppPill(
                    label: 'Followers',
                    selected: _activeTab == 'Followers',
                    onPressed: () => setState(() => _activeTab = 'Followers'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: AppPill(
                    label: 'Following',
                    selected: _activeTab == 'Following',
                    onPressed: () => setState(() => _activeTab = 'Following'),
                  ),
                ),
                const SizedBox(width: 8.0),
                Expanded(
                  child: AppPill(
                    label: 'Requests',
                    selected: false,
                    onPressed: () => Get.toNamed(AppRoutes.CONNECTION_REQUEST),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            Obx(() {
              if (_profileController.loading.value) {
                return const Center(child: CircularProgressIndicator());
              }

              final List<Person> connectedPeople = _profileController
                  .connections
                  .where((item) {
                    if (_activeTab == 'Followers') {
                      return item['receiver_id'].toString() == myId;
                    } else {
                      return item['requester_id'].toString() == myId;
                    }
                  })
                  .map((item) {
                    final otherId = item['requester_id'].toString() == myId
                        ? item['receiver_id'].toString()
                        : item['requester_id'].toString();

                    final p = _discoveryController.people.firstWhereOrNull(
                      (person) => person.id == otherId,
                    );
                    if (p != null) return p;

                    return Person(
                      id: otherId,
                      name: item['name'] ?? 'User',
                      username: 'user_$otherId',
                      age: 18,
                      interests: const [],
                      languages: const [],
                      online: false,
                      avatarColor: '#5B5CE2',
                    );
                  })
                  .toList();

              if (_profileController.error.isNotEmpty) {
                return Center(
                  child: Text(
                    _profileController.error.value,
                    style: const TextStyle(color: AppColors.danger),
                  ),
                );
              }

              return connectedPeople.isNotEmpty
                  ? Column(
                      children: connectedPeople.map((person) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: PersonCard(person: person),
                        );
                      }).toList(),
                    )
                  : AppEmptyState(
                      icon: Icons.people_outline,
                      title: _activeTab == 'Followers'
                          ? 'No followers yet'
                          : 'Not following anyone',
                      text: _activeTab == 'Followers'
                          ? 'Conversations you accept will connect you.'
                          : 'Discover members in the directory to follow.',
                    );
            }),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
