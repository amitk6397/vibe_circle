import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_search_field.dart';
import '../controllers/community_controller.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../../discovery/models/person.dart';

class InviteCircleMembersView extends StatefulWidget {
  const InviteCircleMembersView({super.key});

  @override
  State<InviteCircleMembersView> createState() => _InviteCircleMembersViewState();
}

class _InviteCircleMembersViewState extends State<InviteCircleMembersView> {
  final CommunityController _communityController = Get.find<CommunityController>();
  final DiscoveryController _discoveryController = Get.find<DiscoveryController>();

  String _communityId = '';
  String _query = '';
  final List<String> _invitedIds = [];

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _communityId = args?['communityId'] ?? '';
  }

  void _inviteUser(String personId) async {
    try {
      await _communityController.inviteToCircle(_communityId, personId);
      setState(() {
        _invitedIds.add(personId);
      });
      Get.snackbar('Invitation Sent', 'They must accept before joining the circle.');
    } catch (e) {
      Get.snackbar('Could not invite', e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Person> visiblePeople = _discoveryController.people.where((person) {
      final String fullName = '${person.name} ${person.username}'.toLowerCase();
      return fullName.contains(_query.toLowerCase());
    }).toList();

    return AppScreen(
      header: AppHeader(
        title: 'Invite trusted people',
        subtitle: 'They must accept before the circle becomes visible.',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchField(
              value: _query,
              placeholder: 'Search people',
              onChanged: (val) => setState(() => _query = val),
            ),
            const SizedBox(height: 16.0),

            if (visiblePeople.isNotEmpty) ...[
              ...visiblePeople.map((person) {
                final isInvited = _invitedIds.contains(person.id);
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10.0),
                  child: AppCard(
                    child: Row(
                      children: [
                        AppAvatar(
                          name: person.name,
                          size: 48.0,
                        ),
                        const SizedBox(width: 12.0),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                person.name,
                                style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 14.5),
                              ),
                              const SizedBox(height: 2.0),
                              Text(
                                '@${person.username}',
                                style: const TextStyle(color: AppColors.muted, fontSize: 12.0),
                              ),
                            ],
                          ),
                        ),
                        AppButton(
                          title: isInvited ? 'Invited' : 'Invite',
                          compact: true,
                          disabled: isInvited,
                          tone: isInvited ? AppButtonTone.secondary : AppButtonTone.primary,
                          onPressed: () => _inviteUser(person.id),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else ...[
              const AppEmptyState(
                icon: Icons.people_outline,
                title: 'No people found',
                text: 'Try searching for another connection or username.',
              ),
            ],
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
