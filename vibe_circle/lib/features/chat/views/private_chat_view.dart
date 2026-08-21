import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../core/widgets/app_icon_button.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/chat_controller.dart';
import '../models/message.dart';
import '../widgets/chat_skeleton.dart';

class PrivateChatView extends StatefulWidget {
  const PrivateChatView({super.key});

  @override
  State<PrivateChatView> createState() => _PrivateChatViewState();
}

class _PrivateChatViewState extends State<PrivateChatView> {
  final AuthController _authController = Get.find<AuthController>();
  final ChatController _chatController = Get.find<ChatController>();
  final NetworkApiService _api = NetworkApiService.instance;
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _inputController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

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
  Message? _editingMessage;
  bool _showEmojiPicker = false;
  bool _isUploadingMedia = false;

  Map<String, dynamic>? _chatLimit;
  int? _sessionSeconds;
  Timer? _countdownTimer;
  Timer? _typingTimer;
  Timer? _sendTypingDebounce;

  static const List<String> _quickReactions = ['❤️', '😂', '🔥', '👍', '😮', '😢', '🙏'];
  static const List<String> _emojiCategorySmilies = [
    '😀', '😃', '😄', '😁', '😆', '😅', '😂', '🤣', '😊', '😇',
    '🙂', '🙃', '😉', '😌', '😍', '🥰', '😘', '😗', '😙', '😚',
    '😋', '😛', '😜', '🤪', '😝', '🤑', '🤗', '🤭', '🤫', '🤔',
    '🤐', '🤨', '😐', '😑', '😶', '😏', '😒', '🙄', '😬', '🤥',
  ];
  static const List<String> _emojiCategoryGestures = [
    '👍', '👎', '👊', '✊', '🤛', '🤜', '🤞', '✌️', '🤟', '🤘',
    '👌', '🤌', '🤏', '👈', '👉', '👆', '👇', '☝️', '✋', '🤚',
    '🖐', '🖖', '👋', '🤙', '💪', '🦾', '🖕', '✍️', '🙏', '🤝',
  ];
  static const List<String> _emojiCategoryHearts = [
    '❤️', '🧡', '💛', '💚', '💙', '💜', '🖤', '🤍', '🤎', '💔',
    '❣️', '💕', '💞', '💓', '💗', '💖', '💘', '💝', '💟', '🔥',
    '✨', '⭐', '🌟', '💫', '🎉', '🎊', '🎁', '🎈', '🏆', '👑',
  ];

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
      if (mounted) {
        setState(() {
          _messages.clear();
          _messages.addAll(_chatController.messages);
          _loading = false;
        });
        await _chatController.markRead(_chatId);
        _scrollToBottom();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _realtimeError = e.toString();
          _loading = false;
        });
      }
    }
  }

  void _connectWebSocket() {
    final String wsUrl = ApiUrls.wsBaseUrl + ApiUrls.privateChatWs(_chatId);
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
          if (mounted) {
            setState(() {
              _connected = false;
              _realtimeError = 'Connection offline. Retrying...';
            });
          }
        },
        onDone: () {
          if (mounted) setState(() => _connected = false);
        },
      );
      if (mounted) {
        setState(() {
          _connected = true;
          _realtimeError = '';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _connected = false;
          _realtimeError = 'WebSocket connection failed';
        });
      }
    }
  }

  void _sendWs(Map<String, dynamic> payload) {
    if (_connected && _channel != null) {
      try {
        _channel.sink.add(jsonEncode(payload));
      } catch (_) {}
    }
  }

  void _handleWsEvent(Map<String, dynamic> data) {
    if (!mounted) return;
    final event = data['event'];
    final userId = data['user_id']?.toString();
    final myId = _authController.currentUserId.value;

    if (event == 'typing' && userId != myId) {
      setState(() => _typing = data['typing'] == true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 4), () {
        if (mounted) setState(() => _typing = false);
      });
    } else if (event == 'presence' && userId != myId) {
      setState(() => _online = data['online'] == true);
    } else if (event == 'message') {
      final msg = Message.fromJson(data['message']);
      setState(() {
        final existingIdx = _messages.indexWhere((m) => m.id == msg.id);
        if (existingIdx != -1) {
          _messages[existingIdx] = msg;
        } else {
          _messages.add(msg);
        }
      });
      _scrollToBottom();
      if (!msg.mine) {
        _chatController.markRead(_chatId);
      }
    } else if (event == 'edit') {
      final messageId = data['message_id']?.toString();
      final newText = data['text']?.toString() ?? '';
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(text: newText, edited: true);
        }
      });
    } else if (event == 'delete') {
      final messageId = data['message_id']?.toString();
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(text: '', deleted: true);
        }
      });
    } else if (event == 'react') {
      final messageId = data['message_id']?.toString();
      final reactionsMap = <String, String>{};
      if (data['reactions'] is Map) {
        (data['reactions'] as Map).forEach((k, v) {
          reactionsMap[k.toString()] = v.toString();
        });
      }
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == messageId);
        if (idx != -1) {
          _messages[idx] = _messages[idx].copyWith(reactions: reactionsMap);
        }
      });
    } else if (event == 'read') {
      setState(() {
        for (int i = 0; i < _messages.length; i++) {
          if (_messages[i].mine && _messages[i].readAt == null) {
            _messages[i] = _messages[i].copyWith(readAt: DateTime.now());
          }
        }
      });
    }
  }

  void _loadLimits() async {
    try {
      final limits = await _chatController.loadChatLimits(_chatId);
      if (mounted) setState(() => _chatLimit = limits);
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
          if (mounted) {
            setState(() => _sessionSeconds = 0);
            _showSessionEndedPrompt();
          }
        } else {
          if (mounted) setState(() => _sessionSeconds = diff);
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
        Get.offNamed(
          AppRoutes.PUBLIC_PROFILE,
          arguments: {'personId': _personId},
        );
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

  void _onTextChanged(String value) {
    _sendTypingDebounce?.cancel();
    _sendWs({'event': 'typing', 'typing': true});
    _sendTypingDebounce = Timer(const Duration(seconds: 2), () {
      _sendWs({'event': 'typing', 'typing': false});
    });
  }

  void _handleSend() async {
    final text = _inputController.text.trim();
    if (text.isEmpty && !_isUploadingMedia) return;

    // If we are currently editing a message
    if (_editingMessage != null) {
      final msgToEdit = _editingMessage!;
      setState(() => _editingMessage = null);
      _inputController.clear();
      try {
        _sendWs({'event': 'edit', 'message_id': msgToEdit.id, 'text': text});
        await _chatController.editMessage(msgToEdit.id, text);
        setState(() {
          final idx = _messages.indexWhere((m) => m.id == msgToEdit.id);
          if (idx != -1) {
            _messages[idx] = _messages[idx].copyWith(text: text, edited: true);
          }
        });
      } catch (e) {
        Get.snackbar('Edit failed', e.toString());
      }
      return;
    }

    _inputController.clear();
    final replyId = _replyTo?.id;
    final replyText = _replyTo?.text;
    final replySender = _replyTo?.mine == true ? 'You' : _name;
    setState(() => _replyTo = null);

    try {
      // Send through WebSocket for instant delivery
      _sendWs({
        'event': 'message',
        'data': {
          'text': text,
          'type': 'text',
          'reply_to_id': ?replyId,
        },
      });

      final msg = await _chatController.sendMessage(
        _chatId,
        text,
        replyToId: replyId,
      );

      setState(() {
        if (!_messages.any((m) => m.id == msg.id)) {
          _messages.add(
            msg.copyWith(
              replyToText: replyText,
              replyToSender: replySender,
            ),
          );
        }
      });

      _scrollToBottom();
      _loadLimits();
    } catch (e) {
      Get.snackbar('Send failed', e.toString(), snackPosition: SnackPosition.BOTTOM);
    }
  }

  Future<void> _pickAndSendImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked == null) return;

      setState(() => _isUploadingMedia = true);
      final res = await _api.uploadFile(ApiUrls.upload, File(picked.path));
      final uploadedUrl = (res.data as Map<String, dynamic>?)?['url']?.toString() ?? '';

      if (uploadedUrl.isNotEmpty) {
        _sendWs({
          'event': 'message',
          'data': {
            'text': '',
            'type': 'image',
            'media_url': uploadedUrl,
            'media_name': picked.name,
            if (_replyTo != null) 'reply_to_id': _replyTo!.id,
          },
        });

        final sentMsg = await _chatController.sendMessage(
          _chatId,
          '',
          replyToId: _replyTo?.id,
        );

        setState(() {
          _replyTo = null;
          final updated = sentMsg.copyWith(mediaUrl: uploadedUrl, mediaType: 'image');
          if (!_messages.any((m) => m.id == sentMsg.id)) {
            _messages.add(updated);
          }
        });
        _scrollToBottom();
      }
    } catch (e) {
      Get.snackbar('Upload failed', e.toString());
    } finally {
      if (mounted) setState(() => _isUploadingMedia = false);
    }
  }

  void _onMessageLongPress(Message msg) {
    if (msg.deleted) return;
    HapticFeedback.mediumImpact();

    Get.bottomSheet(
      Container(
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 14.0),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Quick Emoji Reactions Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ..._quickReactions.map((emoji) {
                        final myId = _authController.currentUserId.value ?? 'me';
                        final isSelected = msg.reactions[myId] == emoji;
                        return GestureDetector(
                          onTap: () {
                            Get.back();
                            _toggleReaction(msg, emoji);
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6.0),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withValues(alpha: 0.3) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(emoji, style: const TextStyle(fontSize: 26.0)),
                          ),
                        );
                      }),
                      GestureDetector(
                        onTap: () {
                          Get.back();
                          _showAllEmojiPicker(msg);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6.0),
                          decoration: const BoxDecoration(
                            color: Colors.white12,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 22.0),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(color: AppColors.border, height: 16.0),

              // Reply
              ListTile(
                leading: const Icon(Icons.reply, color: AppColors.text),
                title: const Text('Reply', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                onTap: () {
                  Get.back();
                  setState(() => _replyTo = msg);
                  _focusNode.requestFocus();
                },
              ),

              // Copy text
              if (msg.text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.copy, color: AppColors.text),
                  title: const Text('Copy text', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Get.back();
                    Clipboard.setData(ClipboardData(text: msg.text));
                    Get.snackbar('Copied', 'Message copied to clipboard', snackPosition: SnackPosition.BOTTOM);
                  },
                ),

              // Forward message
              ListTile(
                leading: const Icon(Icons.forward, color: AppColors.text),
                title: const Text('Forward', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                onTap: () {
                  Get.back();
                  _showForwardDialog(msg);
                },
              ),

              // Edit message (only for my messages)
              if (msg.mine && !msg.deleted && msg.text.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.edit_outlined, color: AppColors.primary),
                  title: const Text('Edit message', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Get.back();
                    setState(() {
                      _editingMessage = msg;
                      _inputController.text = msg.text;
                    });
                    _focusNode.requestFocus();
                  },
                ),

              // Delete message (only for my messages)
              if (msg.mine && !msg.deleted)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.danger),
                  title: const Text('Delete message', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w600)),
                  onTap: () {
                    Get.back();
                    _confirmDeleteMessage(msg);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _toggleReaction(Message msg, String emoji) async {
    final myId = _authController.currentUserId.value ?? 'me';
    _sendWs({'event': 'react', 'message_id': msg.id, 'emoji': emoji});

    try {
      await _chatController.reactToMessage(_chatId, msg.id, emoji);
      setState(() {
        final idx = _messages.indexWhere((m) => m.id == msg.id);
        if (idx != -1) {
          final reactions = Map<String, String>.from(msg.reactions);
          if (reactions[myId] == emoji) {
            reactions.remove(myId);
          } else {
            reactions[myId] = emoji;
          }
          _messages[idx] = msg.copyWith(reactions: reactions);
        }
      });
    } catch (e) {
      Get.snackbar('Reaction failed', e.toString());
    }
  }

  void _showAllEmojiPicker(Message msg) {
    Get.bottomSheet(
      Container(
        height: 320.0,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Choose Reaction', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 12.0),
            Expanded(
              child: GridView.count(
                crossAxisCount: 7,
                children: [..._emojiCategorySmilies, ..._emojiCategoryHearts, ..._emojiCategoryGestures].map((emoji) {
                  return GestureDetector(
                    onTap: () {
                      Get.back();
                      _toggleReaction(msg, emoji);
                    },
                    child: Center(child: Text(emoji, style: const TextStyle(fontSize: 28.0))),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteMessage(Message msg) {
    Get.defaultDialog(
      title: 'Delete Message?',
      middleText: 'This message will be deleted for everyone in this chat.',
      textConfirm: 'Delete',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        _sendWs({'event': 'delete', 'message_id': msg.id});
        try {
          await _chatController.deleteMessage(msg.id);
          setState(() {
            final idx = _messages.indexWhere((m) => m.id == msg.id);
            if (idx != -1) {
              _messages[idx] = msg.copyWith(text: '', deleted: true);
            }
          });
        } catch (e) {
          Get.snackbar('Delete failed', e.toString());
        }
      },
    );
  }

  void _showForwardDialog(Message msg) {
    Get.bottomSheet(
      Container(
        height: 400.0,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Forward Message To', style: TextStyle(color: AppColors.text, fontWeight: FontWeight.bold, fontSize: 16.0)),
            const SizedBox(height: 12.0),
            Expanded(
              child: Obx(() {
                final chatList = _chatController.chats;
                if (chatList.isEmpty) {
                  return const Center(child: Text('No other chats available', style: TextStyle(color: AppColors.muted)));
                }
                return ListView.builder(
                  itemCount: chatList.length,
                  itemBuilder: (context, idx) {
                    final c = chatList[idx];
                    final String displayName = c.name?.isNotEmpty == true ? c.name! : 'Member';
                    return ListTile(
                      leading: AppAvatar(name: displayName, avatarUrl: c.avatarUrl, size: 40.0),
                      title: Text(displayName, style: const TextStyle(color: AppColors.text, fontWeight: FontWeight.bold)),
                      subtitle: Text(c.preview, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: AppColors.muted)),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0))),
                        onPressed: () async {
                          Get.back();
                          try {
                            await _chatController.sendMessage(
                              c.id,
                              msg.text.isNotEmpty ? msg.text : 'Forwarded media',
                            );
                            Get.snackbar('Forwarded', 'Message forwarded to $displayName', snackPosition: SnackPosition.BOTTOM);
                          } catch (e) {
                            Get.snackbar('Forward failed', e.toString());
                          }
                        },
                        child: const Text('Forward', style: TextStyle(color: Colors.white, fontSize: 12.0)),
                      ),
                    );
                  },
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  void _initiateCall(String type) {
    Get.snackbar(
      'Calling...',
      'Starting video call with $_name',
      backgroundColor: AppColors.primary,
      colorText: Colors.white,
    );
    Get.toNamed(
      AppRoutes.VIDEO_CALL,
      arguments: {
        'callId': 'call-${DateTime.now().millisecondsSinceEpoch}',
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
    _sendTypingDebounce?.cancel();
    _inputController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
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
            // Chat Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
              color: AppColors.surface,
              child: Row(
                children: [
                  AppIconButton(icon: Icons.arrow_back, onPressed: () => Get.back()),
                  AppAvatar(name: _name, avatarUrl: _avatarUrl, size: 38.0),
                  const SizedBox(width: 10.0),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _name,
                          style: const TextStyle(color: AppColors.text, fontSize: 14.0, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _typing
                              ? 'Typing...'
                              : _connected
                                  ? (_online ? 'Online' : 'Active')
                                  : 'Reconnecting...',
                          style: TextStyle(
                            color: _typing ? AppColors.primary : AppColors.muted,
                            fontSize: 11.0,
                            fontWeight: _typing ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  AppIconButton(
                    icon: Icons.videocam_outlined,
                    onPressed: () => _initiateCall('video'),
                  ),
                ],
              ),
            ),

            // Offline / Realtime Status Banner
            if (_realtimeError.isNotEmpty)
              Container(
                color: AppColors.danger.withValues(alpha: 0.15),
                padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.cloud_off, color: AppColors.danger, size: 14.0),
                    const SizedBox(width: 6.0),
                    Text(_realtimeError, style: const TextStyle(color: AppColors.danger, fontSize: 11.0)),
                  ],
                ),
              ),

            // Paid Chat Limits Banner
            if (_chatLimit != null && (_chatLimit!['chatCoinsPerMessage'] ?? 0) > 0)
              Container(
                color: const Color(0xFFFFF3E0),
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFE65100), size: 16.0),
                    const SizedBox(width: 6.0),
                    Expanded(
                      child: Text(
                        'Paid Chat: ${_chatLimit!['chatCoinsPerMessage']} coins every ${_chatLimit!['chatMessageDeductionInterval']} msgs',
                        style: const TextStyle(color: Color(0xFFE65100), fontSize: 11.5, fontWeight: FontWeight.bold),
                      ),
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
                      '${(_sessionSeconds! ~/ 60).toString().padLeft(2, '0')}:${(_sessionSeconds! % 60).toString().padLeft(2, '0')} focused Connect',
                      style: const TextStyle(color: AppColors.primary, fontSize: 12.0, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),

            // Messages Scroll Body
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
                      : GestureDetector(
                          onTap: () {
                            if (_showEmojiPicker) setState(() => _showEmojiPicker = false);
                            FocusScope.of(context).unfocus();
                          },
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                            itemCount: _messages.length,
                            itemBuilder: (context, idx) {
                              final msg = _messages[idx];
                              return _buildMessageBubble(msg);
                            },
                          ),
                        ),
            ),

            // Replying Banner
            if (_replyTo != null)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
                ),
                child: Row(
                  children: [
                    Container(width: 4.0, height: 36.0, color: AppColors.primary),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${_replyTo!.mine ? "yourself" : _name}',
                            style: const TextStyle(color: AppColors.primary, fontSize: 12.0, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            _replyTo!.text.isNotEmpty ? _replyTo!.text : 'Attachment',
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(icon: Icons.close, onPressed: () => setState(() => _replyTo = null)),
                  ],
                ),
              ),

            // Editing Banner
            if (_editingMessage != null)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border, width: 0.8)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.edit, color: AppColors.primary, size: 18.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Editing message', style: TextStyle(color: AppColors.primary, fontSize: 12.0, fontWeight: FontWeight.bold)),
                          Text(
                            _editingMessage!.text,
                            style: const TextStyle(color: AppColors.muted, fontSize: 11.5),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    AppIconButton(
                      icon: Icons.close,
                      onPressed: () {
                        setState(() => _editingMessage = null);
                        _inputController.clear();
                      },
                    ),
                  ],
                ),
              ),

            // Bottom Input Bar
            if (isSessionExpired)
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    const Text('Your chat time is complete', style: TextStyle(color: AppColors.text, fontSize: 14.0, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10.0),
                    AppButton(title: 'View subscription plans', onPressed: () => Get.toNamed(AppRoutes.SUBSCRIPTION_PLANS)),
                  ],
                ),
              )
            else
              Container(
                color: AppColors.surface,
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
                child: Row(
                  children: [
                    // Attachment Picker Button (+)
                    AppIconButton(
                      icon: Icons.add_circle_outline,
                      onPressed: () => _showMediaBottomSheet(),
                    ),

                    // Emoji Toggle Button
                    AppIconButton(
                      icon: _showEmojiPicker ? Icons.keyboard : Icons.sentiment_satisfied_alt_outlined,
                      onPressed: () {
                        setState(() => _showEmojiPicker = !_showEmojiPicker);
                        if (_showEmojiPicker) {
                          FocusScope.of(context).unfocus();
                        } else {
                          _focusNode.requestFocus();
                        }
                      },
                    ),

                    // Input Text Field
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(24.0),
                        ),
                        child: TextField(
                          controller: _inputController,
                          focusNode: _focusNode,
                          onChanged: _onTextChanged,
                          style: const TextStyle(color: AppColors.text, fontSize: 14.0),
                          maxLines: 4,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: _editingMessage != null ? 'Edit message...' : 'Message...',
                            hintStyle: const TextStyle(color: AppColors.muted),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6.0),

                    // Send Button
                    GestureDetector(
                      onTap: _handleSend,
                      child: Container(
                        width: 42.0,
                        height: 42.0,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: const Icon(Icons.send_rounded, color: Colors.white, size: 20.0),
                      ),
                    ),
                  ],
                ),
              ),

            // Built-in Categorized Emoji Picker Grid
            if (_showEmojiPicker) _buildEmojiPickerKeyboard(),
          ],
        ),
      ),
    );
  }

  void _showMediaBottomSheet() {
    Get.bottomSheet(
      Container(
        color: AppColors.surface,
        padding: const EdgeInsets.symmetric(vertical: 16.0),
        child: SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined, color: AppColors.primary),
                title: const Text('Camera', style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Get.back();
                  _pickAndSendImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined, color: AppColors.primary),
                title: const Text('Photo Gallery', style: TextStyle(color: AppColors.text)),
                onTap: () {
                  Get.back();
                  _pickAndSendImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmojiPickerKeyboard() {
    return Container(
      height: 250.0,
      color: AppColors.surfaceAlt,
      child: DefaultTabController(
        length: 3,
        child: Column(
          children: [
            const TabBar(
              indicatorColor: AppColors.primary,
              tabs: [
                Tab(text: '😀 Smileys'),
                Tab(text: '👍 Gestures'),
                Tab(text: '❤️ Hearts'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _buildEmojiGrid(_emojiCategorySmilies),
                  _buildEmojiGrid(_emojiCategoryGestures),
                  _buildEmojiGrid(_emojiCategoryHearts),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmojiGrid(List<String> emojis) {
    return GridView.builder(
      padding: const EdgeInsets.all(8.0),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 8,
        crossAxisSpacing: 4.0,
        mainAxisSpacing: 4.0,
      ),
      itemCount: emojis.length,
      itemBuilder: (context, idx) {
        final emoji = emojis[idx];
        return GestureDetector(
          onTap: () {
            _inputController.text = _inputController.text + emoji;
            _onTextChanged(_inputController.text);
          },
          child: Center(child: Text(emoji, style: const TextStyle(fontSize: 24.0))),
        );
      },
    );
  }

  Widget _buildMessageBubble(Message msg) {
    final bool isMine = msg.mine;
    final alignment = isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final bubbleColor = isMine ? AppColors.primary : AppColors.surfaceAlt;
    final textColor = isMine ? Colors.white : AppColors.text;

    // Build unique reactions list with count
    final Map<String, int> reactionCounts = {};
    msg.reactions.forEach((_, emoji) {
      reactionCounts[emoji] = (reactionCounts[emoji] ?? 0) + 1;
    });

    return Padding(
      padding: const EdgeInsets.only(bottom: 10.0),
      child: Column(
        crossAxisAlignment: alignment,
        children: [
          GestureDetector(
            onLongPress: () => _onMessageLongPress(msg),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.78,
                  ),
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18.0),
                      topRight: const Radius.circular(18.0),
                      bottomLeft: Radius.circular(isMine ? 18.0 : 4.0),
                      bottomRight: Radius.circular(isMine ? 4.0 : 18.0),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 4.0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Deleted Message Display
                      if (msg.deleted)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, size: 14.0, color: isMine ? Colors.white70 : AppColors.muted),
                            const SizedBox(width: 4.0),
                            Text(
                              'This message was deleted',
                              style: TextStyle(
                                color: isMine ? Colors.white70 : AppColors.muted,
                                fontSize: 13.0,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        )
                      else ...[
                        // Reply Quote Block Inside Bubble
                        if (msg.replyToId != null)
                          Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 6.0),
                            decoration: BoxDecoration(
                              color: isMine ? Colors.black.withValues(alpha: 0.18) : AppColors.surface,
                              borderRadius: BorderRadius.circular(8.0),
                              border: Border(
                                left: BorderSide(
                                  color: isMine ? Colors.white70 : AppColors.primary,
                                  width: 3.0,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  msg.replyToSender ?? 'Reply',
                                  style: TextStyle(
                                    color: isMine ? Colors.white : AppColors.primary,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2.0),
                                Text(
                                  msg.replyToText ?? 'Original message',
                                  style: TextStyle(
                                    color: isMine ? Colors.white70 : AppColors.muted,
                                    fontSize: 11.0,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                        // Media Image
                        if (msg.mediaUrl != null && msg.mediaUrl!.isNotEmpty) ...[
                          GestureDetector(
                            onTap: () {
                              Get.dialog(
                                Dialog(
                                  backgroundColor: Colors.transparent,
                                  insetPadding: EdgeInsets.zero,
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: Image.network(
                                          Helpers.resolveImageUrl(msg.mediaUrl!) ?? msg.mediaUrl!,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                      Positioned(
                                        top: 40.0,
                                        right: 20.0,
                                        child: IconButton(
                                          icon: const Icon(Icons.close, color: Colors.white, size: 30.0),
                                          onPressed: () => Get.back(),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10.0),
                              child: Image.network(
                                Helpers.resolveImageUrl(msg.mediaUrl!) ?? msg.mediaUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: 180.0,
                                errorBuilder: (c, e, s) => Container(
                                  height: 120.0,
                                  color: Colors.white12,
                                  child: const Center(child: Icon(Icons.broken_image, color: Colors.white54)),
                                ),
                              ),
                            ),
                          ),
                          if (msg.text.isNotEmpty) const SizedBox(height: 6.0),
                        ],

                        // Message Text Body
                        if (msg.text.isNotEmpty)
                          Text(
                            msg.text,
                            style: TextStyle(
                              color: textColor,
                              fontSize: 14.0,
                              height: 1.35,
                            ),
                          ),
                      ],

                      // Message Footer: Time + (edited) + Checks
                      const SizedBox(height: 4.0),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (msg.edited) ...[
                            Text(
                              '(edited) ',
                              style: TextStyle(
                                color: isMine ? Colors.white60 : AppColors.muted,
                                fontSize: 9.5,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                          Text(
                            msg.time,
                            style: TextStyle(
                              color: isMine ? Colors.white70 : AppColors.muted,
                              fontSize: 10.0,
                            ),
                          ),
                          if (isMine) ...[
                            const SizedBox(width: 4.0),
                            Icon(
                              msg.readAt != null ? Icons.done_all : Icons.done,
                              size: 14.0,
                              color: msg.readAt != null ? const Color(0xFF64B5F6) : Colors.white70,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Floating Reactions Pill at bottom edge of bubble
                if (reactionCounts.isNotEmpty)
                  Positioned(
                    bottom: -10.0,
                    right: isMine ? null : -6.0,
                    left: isMine ? -6.0 : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(12.0),
                        border: Border.all(color: AppColors.border, width: 0.8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 4.0,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: reactionCounts.entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 2.0),
                            child: Text(
                              '${e.key}${e.value > 1 ? " ${e.value}" : ""}',
                              style: const TextStyle(fontSize: 11.0),
                            ),
                          );
                        }).toList(),
                      ),
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

