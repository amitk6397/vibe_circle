import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_circle/features/auth/controllers/auth_controller.dart';

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
  final DiscoveryController _discoveryController =
      Get.find<DiscoveryController>();
  final ChatController _chatController = Get.find<ChatController>();
  final AuthController _authController = Get.find<AuthController>();

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
      final userProfile = await _discoveryController.fetchPublicProfile(
        _personId,
      );
      final connectionsList = await _discoveryController.fetchConnections();

      // Find active relation
      Map<String, dynamic>? relation;
      for (var conn in connectionsList) {
        if ((conn['requester_id'].toString() == userProfile.id ||
            conn['receiver_id'].toString() == userProfile.id)) {
          relation = Map<String, dynamic>.from(conn as Map);
          break;
        }
      }

      setState(() {
        _user = userProfile;
        _relationship = relation;
        _blocked = _authController.blockedUsers.contains(_personId);
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
        Get.snackbar(
          'Connection removed',
          'You stopped following ${_user!.name}.',
        );
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
      Get.toNamed(
        AppRoutes.PRIVATE_CHAT,
        arguments: {
          'chatId': data['id'].toString(),
          'name': _user!.name,
          'personId': _user!.id,
        },
      );
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
    if (_blocked) {
      _authController.blockedUsers.add(_personId);
    } else {
      _authController.blockedUsers.remove(_personId);
    }
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
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6.0),
              const Text(
                'Select a reason for reporting. Evidence will be reviewed by safety team.',
                style: TextStyle(color: AppColors.muted, fontSize: 12.0),
              ),
              const SizedBox(height: 16.0),
              ListTile(
                leading: const Icon(Icons.warning_amber, color: AppColors.text),
                title: const Text(
                  'Spam or scam',
                  style: TextStyle(color: AppColors.text),
                ),
                onTap: () {
                  Get.back();
                  Get.snackbar(
                    'Report submitted',
                    'Thank you. Our safety team will review it.',
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.gavel, color: AppColors.danger),
                title: const Text(
                  'Harassment',
                  style: TextStyle(color: AppColors.danger),
                ),
                onTap: () {
                  Get.back();
                  Get.snackbar(
                    'Report submitted',
                    'Thank you. Our safety team will review it.',
                  );
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
        header: const AppHeader(title: 'Profile'),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error.isNotEmpty || _user == null) {
      return AppScreen(
        header: const AppHeader(title: 'Profile'),
        child: AppEmptyState(
          icon: Icons.error_outline,
          title: 'Profile unavailable',
          text: _error.isNotEmpty
              ? _error
              : 'This member profile is private or does not exist.',
        ),
      );
    }

    final hasRequested =
        _relationship != null && _relationship!['status'] == 'pending';
    final isFollowing =
        _relationship != null && _relationship!['status'] == 'accepted';

    return AppScreen(
      header: AppHeader(
        title: 'Profile',
        onBack: () => Get.back(),
        right: IconButton(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onPressed: _showReportOptions,
        ),
      ),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Centered Hero section
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20.0),
              child: Column(
                children: [
                  AppAvatar(
                    name: _user!.name,
                    avatarUrl: _user!.avatarUrl,
                    online: _user!.online,
                    size: 92.0,
                  ),
                  const SizedBox(height: 12.0),
                  Text(
                    '${_user!.name}, ${_user!.age}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4.0),
                  Text(
                    '@${_user!.username} · ${_user!.city ?? 'Unknown'}',
                    style: const TextStyle(
                      color: AppColors.muted,
                      fontSize: 13.0,
                    ),
                  ),
                  const SizedBox(height: 10.0),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.shield_outlined,
                        size: 17.0,
                        color: Color(0xFF3B82F6),
                      ),
                      SizedBox(width: 4.0),
                      Text(
                        'Identity signals reviewed',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bio Card
            AppCard(
              child: Text(
                _user!.bio != null && _user!.bio!.isNotEmpty
                    ? _user!.bio!
                    : 'No bio provided yet.',
                style: TextStyle(
                  color: _user!.bio != null && _user!.bio!.isNotEmpty
                      ? AppColors.text
                      : AppColors.muted,
                  fontSize: 13.0,
                  height: 1.3,
                  fontStyle: _user!.bio != null && _user!.bio!.isNotEmpty
                      ? FontStyle.normal
                      : FontStyle.italic,
                ),
              ),
            ),
            const SizedBox(height: 16.0),

            // Interests
            if (_user!.interests.isNotEmpty) ...[
              const Text('Interests', style: AppTextStyles.h2),
              const SizedBox(height: 6.0),
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: _user!.interests
                    .map(
                      (interest) => AppPill(label: interest, selected: false),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16.0),
            ],

            // Languages
            if (_user!.languages.isNotEmpty) ...[
              const Text('Languages', style: AppTextStyles.h2),
              const SizedBox(height: 6.0),
              Wrap(
                spacing: 6.0,
                runSpacing: 6.0,
                children: _user!.languages
                    .map((lang) => AppPill(label: lang, selected: false))
                    .toList(),
              ),
              const SizedBox(height: 16.0),
            ],

            // Performance Rate button
            AppButton(
              title: 'View performance & coin rates',
              icon: Icons.star_border_outlined,
              tone: AppButtonTone.secondary,
              onPressed: () => Get.toNamed(
                AppRoutes.USER_PERFORMANCE,
                arguments: {'userId': _user!.id},
              ),
            ),
            const SizedBox(height: 16.0),

            // Follow / Message actions or Block Notice
            if (!_blocked)
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      title: isFollowing
                          ? 'Unfollow'
                          : hasRequested
                          ? 'Requested'
                          : 'Follow',
                      tone: isFollowing
                          ? AppButtonTone.secondary
                          : AppButtonTone.primary,
                      icon: Icons.person_add_outlined,
                      loading: _actionLoading,
                      onPressed: _onFollow,
                    ),
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: AppButton(
                      title: 'Message',
                      tone: AppButtonTone.secondary,
                      icon: Icons.chat_bubble_outline,
                      loading: _actionLoading,
                      onPressed: _onMessage,
                    ),
                  ),
                ],
              )
            else
              AppCard(
                child: Row(
                  children: const [
                    Icon(
                      Icons.block_flipped,
                      color: AppColors.danger,
                      size: 20.0,
                    ),
                    SizedBox(width: 10.0),
                    Expanded(
                      child: Text(
                        'You cannot follow or message each other while this account is blocked.',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12.0),

            AppButton(
              title: _blocked ? 'Unblock user' : 'Block user',
              tone: AppButtonTone.danger,
              onPressed: _onBlockToggle,
            ),
            const SizedBox(height: 12.0),

            Center(
              child: TextButton(
                onPressed: _showReportOptions,
                child: const Text(
                  'Report profile',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 13.0,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20.0),
          ],
        ),
      ),
    );
  }
}
