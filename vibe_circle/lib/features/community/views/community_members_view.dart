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
import '../../../core/widgets/app_pill.dart';
import '../controllers/community_controller.dart';
import '../../discovery/models/person.dart';
import '../../discovery/controllers/discovery_controller.dart';
import '../../../routes/app_routes.dart';

class CommunityMembersView extends StatefulWidget {
  const CommunityMembersView({super.key});

  @override
  State<CommunityMembersView> createState() => _CommunityMembersViewState();
}

class _CommunityMembersViewState extends State<CommunityMembersView> {
  final CommunityController _communityController = Get.find<CommunityController>();
  final DiscoveryController _discoveryController = Get.find<DiscoveryController>();

  final List<Person> _members = [];
  bool _loading = true;
  String _search = '';
  String _filter = 'All'; // 'All' | 'Online' | 'Moderators'

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  void _loadMembers() async {
    final Map args = Get.arguments ?? {};
    final String? communityId = args['communityId']?.toString();

    if (communityId != null) {
      try {
        await _communityController.loadMembers(communityId);
        setState(() {
          _members.clear();
          _members.addAll(_communityController.membersList.map((x) => Person.fromJson(Map<String, dynamic>.from(x as Map))));
        });
      } catch (_) {
        setState(() {
          _members.clear();
          _members.addAll(_discoveryController.people);
        });
      }
    }

    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _members.where((person) {
      final matchesSearch = person.name.toLowerCase().contains(_search.toLowerCase()) ||
          person.username.toLowerCase().contains(_search.toLowerCase());
      if (_filter == 'Online') return matchesSearch && person.online;
      return matchesSearch;
    }).toList();

    return AppScreen(
      header: AppHeader(
        title: 'Community members',
        subtitle: '${_members.length} people in community',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppSearchField(
              value: _search,
              placeholder: 'Search members or interests',
              onChanged: (val) => setState(() => _search = val),
            ),
            const SizedBox(height: 12.0),

            Row(
              children: ['All', 'Online', 'Moderators'].map((f) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: AppPill(
                    label: f,
                    selected: _filter == f,
                    onPressed: () => setState(() => _filter = f),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16.0),

            _loading
                ? const Center(child: CircularProgressIndicator())
                : filtered.isNotEmpty
                    ? Column(
                        children: filtered.map((person) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10.0),
                            child: AppCard(
                              onPressed: () => Get.toNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': person.id}),
                              child: Row(
                                children: [
                                  AppAvatar(
                                    name: person.name,
                                    avatarUrl: person.avatarUrl,
                                    size: 46.0,
                                    online: person.online,
                                  ),
                                  const SizedBox(width: 12.0),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${person.name}, ${person.age}',
                                          style: const TextStyle(
                                            color: AppColors.text,
                                            fontSize: 14.0,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 2.0),
                                        Text(
                                          '@${person.username}',
                                          style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                                        ),
                                      ],
                                    ),
                                  ),
                                  AppButton(
                                    title: 'Message',
                                    compact: true,
                                    tone: AppButtonTone.secondary,
                                    onPressed: () => Get.toNamed(AppRoutes.NEW_MESSAGE_REQUEST, arguments: {
                                      'personId': person.id,
                                      'name': person.name,
                                    }),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      )
                    : const AppEmptyState(
                        title: 'No members found',
                        text: 'Try adjusting your search filters.',
                      ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }
}
