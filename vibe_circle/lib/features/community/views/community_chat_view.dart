import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/constants/api_urls.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/network_api_service.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/utils/helpers.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_header.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../chat/widgets/chat_skeleton.dart';
import '../controllers/community_controller.dart';
import '../models/community.dart';
import '../models/community_message.dart';

class CommunityChatView extends StatefulWidget {
  const CommunityChatView({super.key});

  @override
  State<CommunityChatView> createState() => _CommunityChatViewState();
}

class _CommunityChatViewState extends State<CommunityChatView> {
  final CommunityController _communityController = Get.find<CommunityController>();
  final AuthController _authController = Get.find<AuthController>();
  final NetworkApiService _api = NetworkApiService.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Community? _community;
  final List<CommunityMessage> _messages = [];
  bool _loading = true;
  bool _connected = false;
  bool _someoneTyping = false;
  Timer? _typingTimer;
  Timer? _sendTypingDebounce;
  dynamic _channel;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadChat();
  }

  void _loadChat() async {
    final Map args = Get.arguments is Map ? Get.arguments : {};
    final String? communityId = args['communityId']?.toString();

    if (communityId != null) {
      try {
        _community = await _communityController.fetchCommunityDetails(communityId);
      } catch (_) {
        _community = _communityController.communities.firstWhereOrNull((c) => c.id == communityId);
      }

      if (_isJoined) {
        try {
          await _communityController.loadCommunityMessages(communityId);
          final msgs = _communityController.communityMessages[communityId] ?? [];
          _messages.clear();
          _messages.addAll(msgs);
        } catch (_) {}
        _connectWebSocket(communityId);
      }
    }

    if (mounted) {
      setState(() => _loading = false);
      _scrollToBottom();
    }
  }

  bool get _isJoined {
    if (_community == null) return false;
    return _communityController.joinedCommunities.contains(_community!.id) ||
        _community!.isJoined ||
        _community!.joined;
  }

  void _connectWebSocket(String communityId) {
    final String wsUrl = ApiUrls.wsBaseUrl + ApiUrls.communityWs(communityId);
    try {
      _channel = WebSocketService.instance.connect(
        wsUrl,
        onMessage: (message) {
          try {
            final data = jsonDecode(message);
            _handleWsEvent(data);
          } catch (_) {}
        },
        onError: (err) {
          if (mounted) setState(() => _connected = false);
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
        },
      );
      if (mounted) setState(() => _connected = true);
    } catch (_) {
      if (mounted) setState(() => _connected = false);
    }
  }

  void _handleWsEvent(Map<String, dynamic> data) {
    if (!mounted) return;
    final event = data['event'];
    final userId = data['user_id']?.toString();
    final myId = _authController.currentUserId.value;

    if (event == 'typing' && userId != myId) {
      setState(() => _someoneTyping = data['typing'] == true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _someoneTyping = false);
      });
    } else if (event == 'message') {
      final msg = CommunityMessage.fromJson(data['message'], currentUserId: myId);
      setState(() {
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
      });
      _scrollToBottom();
    }
  }

  void _sendWs(Map<String, dynamic> payload) {
    if (_connected && _channel != null) {
      try {
        _channel.sink.add(jsonEncode(payload));
      } catch (_) {}
    }
  }

  void _onTextChanged(String val) {
    _sendTypingDebounce?.cancel();
    _sendWs({'event': 'typing', 'typing': true});
    _sendTypingDebounce = Timer(const Duration(seconds: 2), () {
      _sendWs({'event': 'typing', 'typing': false});
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty || _community == null) return;

    _textController.clear();
    _sendWs({
      'event': 'message',
      'data': {'text': text},
    });

    try {
      await _communityController.sendCommunityMessage(_community!.id, text);
      final msgs = _communityController.communityMessages[_community!.id] ?? [];
      setState(() {
        _messages.clear();
        _messages.addAll(msgs);
      });
      _scrollToBottom();
    } catch (e) {
      Get.snackbar('Send failed', e.toString());
    }
  }

  Future<void> _pickAndSendImage() async {
    if (_community == null) return;
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploading = true);
      final res = await _api.uploadFile(ApiUrls.upload, File(picked.path));
      final uploadedUrl = (res.data as Map<String, dynamic>?)?['url']?.toString() ?? '';

      if (uploadedUrl.isNotEmpty) {
        _sendWs({
          'event': 'message',
          'data': {
            'text': '',
            'media_url': uploadedUrl,
            'media_name': picked.name,
          },
        });

        await _communityController.sendCommunityMessage(
          _community!.id,
          '',
        );

        final msgs = _communityController.communityMessages[_community!.id] ?? [];
        setState(() {
          _messages.clear();
          _messages.addAll(msgs);
        });
        _scrollToBottom();
      }
    } catch (e) {
      Get.snackbar('Upload failed', e.toString());
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _joinAndEnter() async {
    if (_community == null) return;
    try {
      await _communityController.joinCommunity(_community!.id);
      final updated = await _communityController.fetchCommunityDetails(_community!.id);
      setState(() => _community = updated);
      _connectWebSocket(_community!.id);
      await _communityController.loadCommunityMessages(_community!.id);
      final msgs = _communityController.communityMessages[_community!.id] ?? [];
      setState(() {
        _messages.clear();
        _messages.addAll(msgs);
      });
      Get.snackbar('Joined 🎉', 'Welcome to ${_community!.name} chat.');
    } catch (e) {
      Get.snackbar('Join failed', e.toString());
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _sendTypingDebounce?.cancel();
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_community == null) {
      return AppScreen(
        header: AppHeader(
          title: 'Community chat',
          onBack: () => Get.back(),
        ),
        child: const AppEmptyState(
          title: 'Community unavailable',
          text: 'Refresh and try again.',
        ),
      );
    }

    // Join Gate if not joined
    if (!_isJoined) {
      return AppScreen(
        header: AppHeader(
          title: _community!.name,
          onBack: () => Get.back(),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40.0),
              Container(
                width: 80.0,
                height: 80.0,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chat_bubble_outline, color: AppColors.primary, size: 40.0),
              ),
              const SizedBox(height: 20.0),
              const Text(
                'Join to enter the conversation',
                style: TextStyle(color: AppColors.text, fontSize: 18.0, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              const Text(
                'Read the rules, join the community, and then message its members.',
                style: TextStyle(color: AppColors.muted, fontSize: 13.0),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28.0),
              AppButton(
                title: 'Join community',
                icon: Icons.person_add_alt_outlined,
                onPressed: _joinAndEnter,
              ),
            ],
          ),
        ),
      );
    }

    final String? myId = _authController.currentUserId.value;

    return AppScreen(
      scroll: false,
      header: AppHeader(
        title: _community!.name,
        subtitle: '${_community!.memberCount} members · ${_someoneTyping ? "Someone is typing..." : _connected ? "Live chat" : "Connected"}',
        onBack: () => Get.back(),
        right: AppIconButton(
          icon: Icons.people_outline,
          onPressed: () => Get.toNamed(AppRoutes.COMMUNITY_MEMBERS, arguments: {'communityId': _community!.id}),
        ),
      ),
      child: Column(
        children: [
          // Safety Banner
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A2F),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.success.withValues(alpha: 0.3)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_outlined, color: AppColors.success, size: 16.0),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'Be respectful. Avoid sharing phone numbers or private information.',
                    style: TextStyle(color: Color(0xFF81C784), fontSize: 11.0),
                  ),
                ),
              ],
            ),
          ),

          // Messages List
          Expanded(
            child: _loading
                ? const SingleChildScrollView(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: ChatSkeleton(rows: 5),
                    ),
                  )
                : _messages.isNotEmpty
                    ? ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        itemCount: _messages.length,
                        itemBuilder: (context, idx) {
                          final msg = _messages[idx];
                          final bool isMine = msg.authorId == myId || msg.senderId == myId || msg.mine;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12.0),
                            child: Row(
                              mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (!isMine) ...[
                                  AppAvatar(name: msg.authorName, avatarUrl: msg.authorAvatar, size: 32.0),
                                  const SizedBox(width: 8.0),
                                ],
                                Container(
                                  constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
                                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                                  decoration: BoxDecoration(
                                    color: isMine ? AppColors.primary : AppColors.surfaceAlt,
                                    borderRadius: BorderRadius.only(
                                      topLeft: const Radius.circular(16.0),
                                      topRight: const Radius.circular(16.0),
                                      bottomLeft: Radius.circular(isMine ? 16.0 : 4.0),
                                      bottomRight: Radius.circular(isMine ? 4.0 : 16.0),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      if (!isMine) ...[
                                        Text(
                                          msg.authorName,
                                          style: const TextStyle(color: AppColors.primary, fontSize: 11.5, fontWeight: FontWeight.bold),
                                        ),
                                        const SizedBox(height: 3.0),
                                      ],
                                      if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) ...[
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(8.0),
                                          child: Image.network(
                                            Helpers.resolveImageUrl(msg.mediaUrl!) ?? msg.mediaUrl!,
                                            height: 140.0,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (c, e, s) => const SizedBox.shrink(),
                                          ),
                                        ),
                                        if (msg.text.isNotEmpty) const SizedBox(height: 6.0),
                                      ],
                                      if (msg.text.isNotEmpty)
                                        Text(
                                          msg.text,
                                          style: TextStyle(color: isMine ? Colors.white : AppColors.text, fontSize: 13.5, height: 1.35),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      )
                    : const AppEmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'No messages yet',
                        text: 'Be the first to say hello to the group!',
                      ),
          ),

          // Message Composer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
            color: AppColors.surface,
            child: Row(
              children: [
                _isUploading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: SizedBox(
                          width: 20.0,
                          height: 20.0,
                          child: CircularProgressIndicator(strokeWidth: 2.0),
                        ),
                      )
                    : AppIconButton(
                        icon: Icons.add_photo_alternate_outlined,
                        onPressed: _pickAndSendImage,
                      ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14.0),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceAlt,
                      borderRadius: BorderRadius.circular(20.0),
                    ),
                    child: TextField(
                      controller: _textController,
                      onChanged: _onTextChanged,
                      style: const TextStyle(color: AppColors.text, fontSize: 14.0),
                      decoration: const InputDecoration(
                        hintText: 'Message the community...',
                        hintStyle: TextStyle(color: AppColors.muted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8.0),
                GestureDetector(
                  onTap: _send,
                  child: Container(
                    width: 40.0,
                    height: 40.0,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.send_rounded, color: Colors.white, size: 18.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

