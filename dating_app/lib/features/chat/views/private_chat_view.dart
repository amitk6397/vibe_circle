import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../../core/network/websocket_service.dart';
import '../../../core/constants/api_urls.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_icon_button.dart';
import '../../../core/widgets/app_screen.dart';
import '../../../core/widgets/app_button.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../widgets/chat_skeleton.dart';
import '../../../routes/app_routes.dart';

class PrivateChatView extends StatefulWidget {
  const PrivateChatView({super.key});

  @override
  State<PrivateChatView> createState() => _PrivateChatViewState();
}

class _PrivateChatViewState extends State<PrivateChatView> {
  final AuthController _authController = Get.find<AuthController>();
  final ChatController _chatController = Get.find<ChatController>();
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();

  String _chatId = '';
  String _name = '';
  String _personId = '';
  String? _avatarUrl;

  dynamic _channel;
  bool _connected = false;
  bool _typing = false;
  bool _online = false;
  bool _loading = true;
  String _realtimeError = '';

  final List<Message> _messages = [];
  Message? _replyTo;
  Map<String, dynamic>? _chatLimit;
  int? _sessionSeconds;
  Timer? _countdownTimer;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>?;
    _chatId = args?['chatId'] ?? '';
    _name = args?['name'] ?? '';
    _personId = args?['personId'] ?? '';
    _avatarUrl = args?['avatarUrl'];

    _syncMessages();
    _connectWebSocket();
    _loadLimits();
    _setupTimer(args?['sessionEndsAt']);
  }

  void _syncMessages() async {
    try {
      await _chatController.loadMessages(_chatId);
      setState(() {
        _messages.clear();
        _messages.addAll(_chatController.messages.reversed);
        _loading = false;
      });
      await _chatController.markRead(_chatId);
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _realtimeError = e.toString();
        _loading = false;
      });
    }
  }

  void _connectWebSocket() {
    final String wsUrl = ApiUrls.wsBaseUrl + ApiUrls.privateChatWs(_chatId);
    try {
      _channel = WebSocketService.instance.connect(
        wsUrl,
        onMessage: (message) {
          final data = jsonDecode(message);
          _handleWsEvent(data);
        },
        onError: (err) {
          setState(() {
            _connected = false;
            _realtimeError = 'Connection offline. Retrying...';
          });
        },
        onDone: () {
          setState(() => _connected = false);
        },
      );
      setState(() {
        _connected = true;
        _realtimeError = '';
      });
    } catch (e) {
      setState(() {
        _connected = false;
        _realtimeError = 'WebSocket connection failed';
      });
    }
  }

  void _handleWsEvent(Map<String, dynamic> data) {
    final event = data['event'];
    final userId = data['user_id']?.toString();
    final myId = _authController.currentUserId.value;

    if (event == 'typing' && userId != myId) {
      setState(() => _typing = data['typing'] == true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 4), () {
        setState(() => _typing = false);
      });
    } else if (event == 'presence' && userId != myId) {
      setState(() => _online = data['online'] == true);
    } else if (event == 'message') {
      final msg = Message.fromJson(data['message']);
      setState(() {
        // Prevent duplicate insertion
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(msg);
        }
      });
      _scrollToBottom();
    }
  }

  void _loadLimits() async {
    try {
      final limits = await _chatController.loadChatLimits(_chatId);
      setState(() {
        _chatLimit = limits;
      });
    } catch (_) {}
  }

  void _setupTimer(String? endsAtStr) {
    if (endsAtStr == null) return;
    try {
      final endsAt = DateTime.parse(endsAtStr);
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        final diff = endsAt.difference(DateTime.now()).inSeconds;
        if (diff <= 0) {
          timer.cancel();
          setState(() => _sessionSeconds = 0);
          _showSessionEndedPrompt();
        } else {
          setState(() => _sessionSeconds = diff);
        }
      });
    } catch (_) {}
  }

  void _showSessionEndedPrompt() {
    Get.defaultDialog(
      title: 'Chat time complete',
      middleText: 'Your paid Connect session has ended.',
      barrierDismissible: false,
      textConfirm: 'Leave feedback',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.primary,
      onConfirm: () {
        Get.back();
        Get.offNamed(AppRoutes.PUBLIC_PROFILE, arguments: {'personId': _personId});
      },
    );
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty) return;

    _inputController.clear();
    setState(() => _typing = false);

    try {
      final payload = {
        'text': text,
        if (_replyTo != null) 'reply_to_id': _replyTo!.id,
      };

      final msg = await _chatController.sendMessage(_chatId, text, replyToId: _replyTo?.id);

      setState(() {
        _replyTo = null;
      });

      _scrollToBottom();
      _loadLimits();
    } catch (e) {
      Get.snackbar('Send failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  void _onMessageLongPress(Message msg) {
    Get.bottomSheet(
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 12.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.text),
                title: const Text('Reply', style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Get.back();
                  setState(() => _replyTo = msg);
                },
              ),
              ListTile(
                leading: const Icon(Icons.sentiment_satisfied, color: AppColors.text),
                title: const Text('React', style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Get.back();
                  _showEmojiPicker(msg);
                },
              ),
              if (msg.mine)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text('Delete message', style: TextStyle(color: AppColors.danger)),
                  onTap: () async {
                    Get.back();
                    try {
                      await _chatController.deleteMessage(msg.id);
                      setState(() {
                        final idx = _messages.indexWhere((m) => m.id == msg.id);
                        if (idx != -1) {
                          _messages[idx] = msg.copyWith(
                            text: '',
                            deleted: true,
                          );
                        }
                      });
                    } catch (e) {
                      Get.snackbar('Delete failed', e.toString());
                    }
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEmojiPicker(Message msg) {
    final emojis = ['❤️', '😂', '🔥', '👍', '😮', '😢'];
    Get.bottomSheet(
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Select reaction emoji',
              style: TextStyle(color: AppColors.text, fontSize: 16.0, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: emojis.map((emoji) {
                return GestureDetector(
                  onTap: () async {
                    Get.back();
                    try {
                      await _chatController.reactToMessage(_chatId, msg.id, emoji);
                      setState(() {
                        final idx = _messages.indexWhere((m) => m.id == msg.id);
                        if (idx != -1) {
                          final currentReactions = Map<String, String>.from(msg.reactions ?? {});
                          currentReactions[_authController.currentUserId.value ?? 'me'] = emoji;
                          _messages[idx] = msg.copyWith(
                            reactions: currentReactions,
                          );
                        }
                      });
                    } catch (e) {
                      Get.snackbar('Reaction failed', e.toString());
                    }
                  },
                  child: Text(
                    emoji,
                    style: const TextStyle(fontSize: 32.0),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12.0),
          ],
        ),
      ),
    );
  }

  void _initiateCall(String type) {
    Get.snackbar(
      'Calling...',
      'Starting $type call with $_name',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
    // Redirect to call setup screen with params
    Get.toNamed(
      type == 'audio' ? AppRoutes.AUDIO_CALL : AppRoutes.VIDEO_CALL,
      arguments: {
        'callId': 'mock-call-id-${DateTime.now().millisecondsSinceEpoch}',
        'name': _name,
        'chatId': _chatId,
        'personId': _personId,
        'avatarUrl': _avatarUrl,
      },
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _typingTimer?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isSessionExpired = _sessionSeconds == 0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // Chat Custom Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              color: AppColors.surface,
              child: Row(
                children: [
                  AppIconButton(
                    icon: Icons.arrow_back,
                    onPressed: () => Get.back(),
                  ),
                  AppAvatar(
                    name: _name,
                    avatarUrl: _avatarUrl,
                    size: 38.0,
                  ),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 14.0,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _typing
                              ? 'Typing...'
                              : _connected
                                  ? (_online ? 'Online · live' : 'Connected')
                                  : 'Reconnecting...',
                          style: const TextStyle(color: AppColors.primary, fontSize: 11.0),
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.call_outlined,
                    onPressed: () => _initiateCall('audio'),
                  ),
                  AppIconButton(
                    icon: Icons.videocam_outlined,
                    onPressed: () => _initiateCall('video'),
                  ),
                ],
              ),
            ),

            // Focus Connect Timer Banner
            if (_sessionSeconds != null)
              Container(
                color: AppColors.surfaceAlt,
                padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.primary, size: 16.0),
                    const SizedBox(width: 6.0),
                    Text(
                      '${(_sessionSeconds! ~/ 60).toString().padLeft(2, '0')}:'
                      '${(_sessionSeconds! % 60).toString().padLeft(2, '0')} focused Connect',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Messages scroll body
            Expanded(
              child: _loading
                  ? const SingleChildScrollView(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: ChatSkeleton(rows: 5),
                      ),
                    )
                  : _messages.isEmpty
                      ? const AppEmptyState(
                          icon: Icons.chat_bubble_outline,
                          title: 'Start the conversation',
                          text: 'Say hello and mention why you wanted to connect.',
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                          itemCount: _messages.length,
                          itemBuilder: (context, idx) {
                            final msg = _messages[idx];
                            return _buildMessageBubble(msg);
                          },
                        ),
            ),

            // Reply Quote preview header
            if (_replyTo != null)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${_replyTo!.mine ? "your message" : _name}',
                            style: const TextStyle(color: AppColors.text, fontSize: 12.0, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _replyTo!.text.isNotEmpty ? _replyTo!.text : 'Photo/Attachment',
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.close,
                      onPressed: () => setState(() => _replyTo = null),
                    ),
                  ],
                ),
              ),

            // Bottom entry panel
            if (isSessionExpired)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text(
                      'Your chat time is complete',
                      style: TextStyle(color: AppColors.text, fontSize: 14.0, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10.0),
                    AppButton(
                      title: 'View subscription plans',
                      onPressed: () => Get.toNamed(AppRoutes.SUBSCRIPTION_PLANS),
                    ),
                  ],
                ),
              )
            else
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
                child: Row(
                  children: [
                    AppIconButton(
                      icon: Icons.add,
                      onPressed: () {
                        Get.snackbar('Attach media', 'Attachments are supported in private chats.');
                      },
                    ),
                    Expanded(
                      child: TextField(
                        controller: _inputController,
                        style: const TextStyle(color: AppColors.text, fontSize: 14.0),
                        decoration: const InputDecoration(
                          hintText: 'Write a message...',
                          hintStyle: TextStyle(color: AppColors.muted),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 10.0),
                        ),
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.send,
                      onPressed: _handleSend,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(Message msg) {
    final bool isMine = msg.mine;
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine ? AppColors.primary : AppColors.surfaceAlt;
    final textColor = isMine ? Colors.white : AppColors.text;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          GestureDetector(
            onLongPress: () => _onMessageLongPress(msg),
            child: Container(
              padding: const EdgeInsets.all(12.0),
              constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
              decoration: BoxDecoration(
                color: bubbleColor,
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
                  // Deleted warning
                  if (msg.deleted == true)
                    Text(
                      'This message was deleted',
                      style: TextStyle(color: isMine ? Colors.white70 : AppColors.muted, fontSize: 13.0, fontStyle: FontStyle.italic),
                    )
                  else ...[
                    // Reply header indicator
                    if (msg.replyToId != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6.0),
                        padding: const EdgeInsets.only(left: 6.0),
                        decoration: const BoxDecoration(
                          border: Border(left: BorderSide(color: Colors.white30, width: 2.0)),
                        ),
                        child: const Text(
                          'Reply to a previous message',
                          style: TextStyle(color: Colors.white60, fontSize: 10.0),
                        ),
                      ),

                    // Attachment photo
                    if (msg.attachment != null && msg.attachment!.kind == 'image') ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          msg.attachment!.uri,
                          fit: BoxFit.cover,
                          height: 150.0,
                          width: double.infinity,
                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white70),
                        ),
                      ),
                      const SizedBox(height: 6.0),
                    ],

                    // Text body
                    if (msg.text.isNotEmpty)
                      Text(
                        msg.text,
                        style: TextStyle(color: textColor, fontSize: 13.5, height: 1.4),
                      ),
                  ],
                ],
              ),
            ),
          ),

          // Message Status details (Time + Reactions)
          const SizedBox(height: 3.0),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                msg.time,
                style: const TextStyle(color: AppColors.muted, fontSize: 10.0),
              ),
              if (msg.reactions.isNotEmpty) ...[
                const SizedBox(width: 6.0),
                Text(
                  msg.reactions.values.join(' '),
                  style: const TextStyle(fontSize: 10.0),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
