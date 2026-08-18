import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_pill.dart';
import '../controllers/discovery_controller.dart';
import '../../chat/controllers/chat_controller.dart';
import '../models/person.dart';
import '../../../routes/app_routes.dart';

class PublicProfileView extends StatefulWidget {
  const PublicProfileView({super.key});

  @override
  State<PublicProfileView> createState() => _PublicProfileViewState();
}

class _PublicProfileViewState extends State<PublicProfileView> {
  final DiscoveryController _discoveryController = Get.find<DiscoveryController>();
  final ChatController _chatController = Get.find<ChatController>();

  String _personId = '';
  Person? _user;
  Map<String, dynamic>? _relationship;
  bool _loading = true;
  String _error = '';
  bool _actionLoading = false;
  bool _blocked = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _personId = args?['personId'] ?? '';
    _loadProfile();
  }

  void _loadProfile() async {
    setState(() {
      _loading = true;
      _error = '';
    });

    try {
      final userProfile = await _discoveryController.fetchPublicProfile(_personId);
      final connectionsList = await _discoveryController.fetchConnections();
      
      // Find active relation
      Map<String, dynamic>? relation;
      for (var conn in connectionsList) {
        if ((conn['requester_id'].toString() == userProfile.id || conn['receiver_id'].toString() == userProfile.id)) {
          relation = Map<String, dynamic>.from(conn as Map);
          break;
        }
      }

      setState(() {
        _user = userProfile;
        _relationship = relation;
        _blocked = false;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  void _onFollow() async {
    setState(() => _actionLoading = true);
    try {
      if (_relationship != null) {
        final String connId = _relationship!['id'].toString();
        await _discoveryController.unfollowUser(connId);
        setState(() => _relationship = null);
        Get.snackbar('Connection removed', 'You stopped following ${_user!.name}.');
      } else {
        final data = await _discoveryController.followUser(_personId);
        setState(() {
          _relationship = data;
        });
        final bool isAccepted = data['status'] == 'accepted';
        Get.snackbar(
          isAccepted ? 'Following' : 'Request sent',
          isAccepted
              ? 'You are now following ${_user!.name}.'
              : '${_user!.name} can now accept your connection request.',
          backgroundColor: AppColors.primary,
          colorText: Colors.white,
        );
      }
    } catch (e) {
      Get.snackbar('Action failed', e.toString());
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  void _onMessage() async {
    setState(() => _actionLoading = true);
    try {
      final data = await _chatController.createConversation(_personId);
      Get.toNamed(AppRoutes.PRIVATE_CHAT, arguments: {
        'chatId': data['id'].toString(),
        'name': _user!.name,
        'personId': _user!.id,
      });
    } catch (e) {
      Get.snackbar('Could not open chat', e.toString());
    } finally {
      setState(() => _actionLoading = false);
    }
  }

  void _onBlockToggle() {
    setState(() {
      _blocked = !_blocked;
    });
    Get.snackbar(
      _blocked ? 'Blocked' : 'Unblocked',
      _blocked
          ? '${_user!.name} will no longer find, connect, or message you.'
          : '${_user!.name} is visible again.',
    );
  }

  void _showReportOptions() {
    Get.bottomSheet(
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(20.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Report Safely',
                style: TextStyle(color: AppColors.text, fontSize: 16.0, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Select a reason for reporting. Evidence will be reviewed by safety team.',
                style: TextStyle(color: AppColors.muted, fontSize: 12.0),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.warning_amber, color: AppColors.text),
                title: const Text('Spam or scam', style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Get.back();
                  Get.snackbar('Report submitted', 'Thank you. Our safety team will review it.');
                },
              ),
              ListTile(
                leading: const Icon(Icons.gavel, color: AppColors.danger),
                title: const Text('Harassment', style: TextStyle(color: AppColors.danger)),
                onTap: () {
                  Get.back();
                  Get.snackbar('Report submitted', 'Thank you. Our safety team will review it.');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return AppScreen(
        header: const AppHeader(title: 'Loading profile…'),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty || _user == null) {
      return AppScreen(
        header: const AppHeader(title: 'Error'),
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: 'Profile unavailable',
          text: _error.isNotEmpty ? _error : 'This member profile is private or does not exist.',
        ),
      );
    }

    final hasRequested = _relationship != null && _relationship!['status'] == 'pending';
    final isFollowing = _relationship != null && _relationship!['status'] == 'accepted';

    return AppScreen(
      header: AppHeader(
        title: _user!.name,
        subtitle: '@${_user!.username}',
        onBack: () => Get.back(),
        right: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showReportOptions,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Avatar profile card
            AppCard(
              child: Column(
                children: [
                  AppAvatar(name: _user!.name, avatarUrl: _user!.avatarUrl, size: 76.0),
                  const SizedBox(height: 12.0),
                  Text(_user!.name, style: AppTextStyles.title),
                  Text('@${_user!.username}', style: const TextStyle(color: AppColors.primary, fontSize: 13.0, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10.0),
                  if (_user!.bio != null && _user!.bio!.isNotEmpty)
                    Text(
                      _user!.bio!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.text, fontSize: 13.0, height: 1.3),
                    )
                  else
                    const Text('No bio provided yet.', style: TextStyle(color: AppColors.muted, fontSize: 12.0, fontStyle: FontStyle.italic)),
                ],
              ),
            ),
            const SizedBox(height: 16.0),

            // Profile info pills
            Row(
              children: [
                Expanded(child: _buildInfoCard(Icons.cake_outlined, 'Age', '${_user!.age}')),
                const SizedBox(width: 8.0),
                Expanded(child: _buildInfoCard(Icons.map_outlined, 'City', _user!.city ?? 'Unknown')),
                const SizedBox(width: 8.0),
                Expanded(
                  child: _buildInfoCard(
                    Icons.circle,
                    'Status',
                    _user!.online ? 'Online' : 'Offline',
                    textColor: _user!.online ? const Color(0xFF10B981) : AppColors.muted,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16.0),

            // Languages
            if (_user!.languages.isNotEmpty) ...[
              const Text('Languages', style: AppTextStyles.h2),
              const SizedBox(height: 6.0),
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: _user!.languages.map((lang) => AppPill(label: lang, selected: false)).toList(),
              ),
              const SizedBox(height: 16.0),
            ],

            // Interests
            if (_user!.interests.isNotEmpty) ...[
              const Text('Interests', style: AppTextStyles.h2),
              const SizedBox(height: 6.0),
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: _user!.interests.map((interest) => AppPill(label: interest, selected: false)).toList(),
              ),
              const SizedBox(height: 22.0),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: isFollowing
                        ? 'Following'
                        : hasRequested
                            ? 'Requested'
                            : 'Follow',
                    tone: isFollowing ? AppButtonTone.secondary : AppButtonTone.primary,
                    loading: _actionLoading,
                    onPressed: _onFollow,
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: AppButton(
                    title: 'Message',
                    tone: AppButtonTone.secondary,
                    loading: _actionLoading,
                    onPressed: _onMessage,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    title: 'Voice Call',
                    tone: AppButtonTone.secondary,
                    onPressed: () {
                      final String dummyCallId = 'call_${DateTime.now().millisecondsSinceEpoch}';
                      Get.toNamed(AppRoutes.AUDIO_CALL, arguments: {
                        'callId': dummyCallId,
                        'name': _user!.name,
                        'personId': _user!.id,
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10.0),
                Expanded(
                  child: AppButton(
                    title: 'Video Call',
                    tone: AppButtonTone.secondary,
                    onPressed: () {
                      final String dummyCallId = 'call_${DateTime.now().millisecondsSinceEpoch}';
                      Get.toNamed(AppRoutes.VIDEO_CALL, arguments: {
                        'callId': dummyCallId,
                        'name': _user!.name,
                        'personId': _user!.id,
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12.0),
            AppButton(
              title: _blocked ? 'Unblock member' : 'Block member',
              tone: AppButtonTone.danger,
              onPressed: _onBlockToggle,
            ),
            const SizedBox(height: 30.0),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String label, String value, {Color? textColor}) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18.0, color: AppColors.primary),
          const SizedBox(height: 6.0),
          Text(label, style: const TextStyle(color: AppColors.muted, fontSize: 10.0)),
          Text(
            value,
            style: TextStyle(color: textColor ?? AppColors.text, fontSize: 13.0, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
