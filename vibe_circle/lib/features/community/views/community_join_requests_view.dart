import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../repositories/community_repository.dart';
import '../../chat/widgets/chat_skeleton.dart';

class CommunityJoinRequestsView extends StatefulWidget {
  const CommunityJoinRequestsView({super.key});

  @override
  State<CommunityJoinRequestsView> createState() => _CommunityJoinRequestsViewState();
}

class _CommunityJoinRequestsViewState extends State<CommunityJoinRequestsView> {
  final CommunityRepository _repo = CommunityRepository();

  String? _communityId;
  final List<dynamic> _requests = [];
  bool _loading = true;
  String _busyId = '';

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  void _loadRequests() async {
    final Map args = Get.arguments ?? {};
    _communityId = args['communityId']?.toString();

    if (_communityId != null) {
      try {
        final list = await _repo.joinRequests(_communityId!);
        setState(() {
          _requests.clear();
          _requests.addAll(list);
        });
      } catch (_) {}
    }

    setState(() => _loading = false);
  }

  void _respond(dynamic request, String action) async {
    final String reqId = request['id'].toString();
    setState(() => _busyId = '$reqId:$action');

    try {
      await _repo.respondJoinRequest(_communityId!, reqId, action);
      setState(() {
        _requests.removeWhere((item) => item['id'].toString() == reqId);
      });
      Get.snackbar(
        action == 'accept' ? 'Approved 🎉' : 'Declined',
        action == 'accept' ? 'Member added to community.' : 'Request declined.',
        backgroundColor: action == 'accept' ? AppColors.primary : AppColors.surfaceAlt,
        colorText: Colors.white,
      );
    } catch (e) {
      Get.snackbar('Action failed', e.toString());
    } finally {
      setState(() => _busyId = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: 'Join requests',
        subtitle: 'Approve people before they enter this community',
        onBack: () => Get.back(),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: _loading
            ? const ChatSkeleton(rows: 3)
            : _requests.isNotEmpty
                ? Column(
                    children: _requests.map((item) {
                      final String reqId = item['id'].toString();
                      final String userName = item['user_name'] ?? 'User';
                      final bool isAccepting = _busyId == '$reqId:accept';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10.0),
                        child: AppCard(
                          child: Row(
                            children: [
                              AppAvatar(name: userName, size: 44.0),
                              const SizedBox(width: 12.0),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      userName,
                                      style: const TextStyle(
                                        color: AppColors.text,
                                        fontSize: 14.0,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 2.0),
                                    const Text('Wants to join your community', style: TextStyle(color: AppColors.muted, fontSize: 11.5)),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.close, color: AppColors.muted),
                                onPressed: () => _respond(item, 'reject'),
                              ),
                              AppButton(
                                title: 'Approve',
                                compact: true,
                                loading: isAccepting,
                                onPressed: () => _respond(item, 'accept'),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  )
                : const AppEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No pending requests',
                    text: 'New join requests will appear here.',
                  ),
      ),
    );
  }
}
