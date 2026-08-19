import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:dating_app/core/constants/app_colors.dart';
import 'package:dating_app/core/constants/api_urls.dart';
import 'package:dating_app/core/constants/app_text_styles.dart';
import 'package:dating_app/core/network/network_api_service.dart';
import 'package:dating_app/core/widgets/app_button.dart';
import 'package:dating_app/core/widgets/app_field.dart';
import 'package:dating_app/core/widgets/app_header.dart';
import 'package:dating_app/core/widgets/app_screen.dart';
import 'package:dating_app/core/widgets/app_pill.dart';
import 'package:dating_app/features/auth/controllers/auth_controller.dart';

const _giftOptions = [
  {'name': 'Heart', 'emoji': '❤️', 'coins': 5},
  {'name': 'Star', 'emoji': '⭐', 'coins': 10},
  {'name': 'Fire', 'emoji': '🔥', 'coins': 20},
  {'name': 'Diamond', 'emoji': '💎', 'coins': 50},
  {'name': 'Crown', 'emoji': '👑', 'coins': 100},
  {'name': 'Rocket', 'emoji': '🚀', 'coins': 200},
];

const _categories = [
  'General',
  'Gaming',
  'Music',
  'Fitness',
  'Talk',
  'Art',
  'Education',
];

class GoLiveView extends StatefulWidget {
  const GoLiveView({super.key});

  @override
  State<GoLiveView> createState() => _GoLiveViewState();
}

class _GoLiveViewState extends State<GoLiveView> {
  final AuthController _authController = Get.find<AuthController>();
  final NetworkApiService _api = NetworkApiService.instance;
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  // Setup state
  String _category = 'General';
  bool _starting = false;

  // Live state
  bool _isLive = false;
  String? _streamId;
  int _viewers = 0;
  int _totalGifts = 0;
  int _duration = 0;
  Timer? _durationTimer;

  // Chat messages
  final List<Map<String, dynamic>> _chatMessages = [];

  // Agora
  RtcEngine? _engine;
  int? _dataStreamId;
  bool _cameraEnabled = true;
  bool _muted = false;
  bool _agoraReady = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _durationTimer?.cancel();
    _releaseAgora();
    if (_streamId != null) {
      _api
          .post(ApiUrls.livestreamEnd(_streamId!))
          .catchError((_) => Future.value(null));
    }
    super.dispose();
  }

  // ── Agora Init (broadcaster) ──────────────────────────────────────────────

  Future<void> _initAgora({
    required String appId,
    required String token,
    required String channel,
    required int uid,
  }) async {
    final engine = createAgoraRtcEngine();
    _engine = engine;

    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.setChannelProfile(
      ChannelProfileType.channelProfileLiveBroadcasting,
    );
    await engine.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

    // Data stream for chat & gifts
    final streamId = await engine.createDataStream(
      const DataStreamConfig(syncWithAudio: false, ordered: false),
    );
    _dataStreamId = streamId;

    engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          if (mounted) setState(() => _agoraReady = true);
        },
        onUserJoined: (connection, remoteUid, elapsed) {
          if (mounted) setState(() => _viewers++);
        },
        onUserOffline: (connection, remoteUid, reason) {
          if (mounted) setState(() => _viewers = (_viewers - 1).clamp(0, 999));
        },
        onStreamMessage:
            (connection, remoteUid, streamId, data, length, sentTs) {
              _handleStreamMessage(data);
            },
        onError: (err, msg) {
          if (mounted) Get.snackbar('Stream error', msg);
        },
      ),
    );

    await engine.enableAudio();
    await engine.enableVideo();
    await engine.enableLocalVideo(true);
    await engine.muteLocalVideoStream(false);
    await engine.muteLocalAudioStream(false);
    await engine.startPreview();

    await engine.joinChannel(
      token: token,
      channelId: channel,
      uid: uid,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleBroadcaster,
        publishMicrophoneTrack: true,
        publishCameraTrack: true,
        autoSubscribeAudio: true,
        autoSubscribeVideo: true,
      ),
    );
  }

  void _handleStreamMessage(Uint8List data) {
    try {
      final str = utf8.decode(data);
      final msgObj = jsonDecode(str) as Map<String, dynamic>;
      if (!mounted) return;
      setState(() {
        if (msgObj['type'] == 'chat') {
          _chatMessages.add({
            'sender': msgObj['sender'] ?? 'Viewer',
            'text': msgObj['text'] ?? '',
            'isGift': false,
          });
        } else if (msgObj['type'] == 'gift') {
          _chatMessages.add({
            'sender': msgObj['sender'] ?? 'Viewer',
            'text': 'sent a ${msgObj['giftName']}! ${msgObj['giftEmoji']}',
            'isGift': true,
          });
          _totalGifts += (msgObj['coins'] as num?)?.toInt() ?? 0;
        }
      });
      _scrollChatToBottom();
    } catch (_) {}
  }

  Future<void> _releaseAgora() async {
    final engine = _engine;
    if (engine != null) {
      await engine.stopPreview();
      await engine.leaveChannel();
      await engine.release();
      _engine = null;
    }
  }

  // ── Start stream ──────────────────────────────────────────────────────────

  Future<void> _startStream() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      Get.snackbar(
        'Add a title',
        'Give your stream a title to attract viewers.',
      );
      return;
    }

    // Request permissions
    final perms = await [Permission.microphone, Permission.camera].request();
    if (perms.values.any((s) => !s.isGranted)) {
      Get.snackbar(
        'Permissions required',
        'Camera and microphone permissions are required.',
      );
      return;
    }

    setState(() => _starting = true);
    try {
      final res = await _api.post(
        ApiUrls.livestreamStart,
        data: {'title': title, 'description': '', 'category': _category},
      );
      final data = res.data as Map<String, dynamic>;
      _streamId = data['stream']['id'] as String?;
      final channelName = data['channel_name'] as String? ?? '';
      final agoraToken = data['agora_token'] as String? ?? '';
      final agoraAppId = data['agora_app_id'] as String? ?? '';
      final uid = (data['uid'] as num?)?.toInt() ?? 0;

      await _initAgora(
        appId: agoraAppId,
        token: agoraToken,
        channel: channelName,
        uid: uid,
      );

      setState(() {
        _isLive = true;
        _chatMessages.add({
          'sender': 'System',
          'text': '🎉 Your stream is live! Share the link to get viewers.',
          'isGift': false,
        });
      });

      _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        if (mounted) setState(() => _duration++);
      });
    } catch (e) {
      Get.snackbar('Could not start stream', e.toString());
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }

  // ── End stream ─────────────────────────────────────────────────────────────

  void _endStream() {
    Get.defaultDialog(
      title: 'End Stream?',
      middleText: 'Are you sure you want to end your live stream?',
      textCancel: 'Cancel',
      textConfirm: 'End Stream',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        if (_streamId != null) {
          await _api
              .post(ApiUrls.livestreamEnd(_streamId!))
              .catchError((_) => Future.value(null));
          _streamId = null;
        }
        _durationTimer?.cancel();
        await _releaseAgora();
        Get.back();
      },
    );
  }

  // ── Controls ───────────────────────────────────────────────────────────────

  void _toggleMute() {
    setState(() => _muted = !_muted);
    _engine?.muteLocalAudioStream(_muted);
  }

  void _toggleCamera() {
    setState(() => _cameraEnabled = !_cameraEnabled);
    _engine?.muteLocalVideoStream(!_cameraEnabled);
  }

  void _flipCamera() => _engine?.switchCamera();

  // ── Chat & gifts ───────────────────────────────────────────────────────────

  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();

    final name = _authController.profile.value?.name ?? 'Host';
    setState(() {
      _chatMessages.add({'sender': name, 'text': text, 'isGift': false});
    });
    _scrollChatToBottom();

    // Broadcast over Agora DataStream
    if (_engine != null && _dataStreamId != null) {
      final payload = jsonEncode({
        'type': 'chat',
        'sender': name,
        'text': text,
      });
      _engine!.sendStreamMessage(
        streamId: _dataStreamId!,
        data: Uint8List.fromList(utf8.encode(payload)),
        length: utf8.encode(payload).length,
      );
    }
  }

  void _scrollChatToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_chatScroll.hasClients) {
        _chatScroll.animateTo(
          _chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  String _formatDuration(int s) {
    final m = s ~/ 60;
    final sec = s % 60;
    return '${m.toString().padLeft(2, '0')}:${sec.toString().padLeft(2, '0')}';
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isLive,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && _isLive) _endStream();
      },
      child: _isLive ? _buildLiveScreen() : _buildSetupScreen(),
    );
  }

  // ── Setup Screen ───────────────────────────────────────────────────────────

  Widget _buildSetupScreen() {
    return AppScreen(
      child: Column(
        children: [
          const AppHeader(
            title: 'Go Live',
            subtitle: 'Start broadcasting to your followers',
          ),
          const SizedBox(height: 20.0),
          AppField(
            controller: _titleCtrl,
            label: 'Stream title',
            placeholder: 'What are you streaming today?',
          ),
          const SizedBox(height: 16.0),
          Text('Category', style: AppTextStyles.label),
          const SizedBox(height: 8.0),
          Wrap(
            spacing: 8.0,
            runSpacing: 8.0,
            children: _categories.map((c) {
              return AppPill(
                label: c,
                selected: _category == c,
                onPressed: () => setState(() => _category = c),
              );
            }).toList(),
          ),
          const SizedBox(height: 32.0),
          AppButton(
            title: _starting ? 'Starting...' : '🔴 Go Live',
            onPressed: _starting ? () {} : _startStream,
            loading: _starting,
            disabled: _starting,
          ),
        ],
      ),
    );
  }

  // ── Live Screen ────────────────────────────────────────────────────────────

  Widget _buildLiveScreen() {
    final engine = _engine;
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Local camera preview (full screen)
          Positioned.fill(
            child: engine != null && _agoraReady && _cameraEnabled
                ? AgoraVideoView(
                    controller: VideoViewController(
                      rtcEngine: engine,
                      canvas: const VideoCanvas(uid: 0),
                    ),
                  )
                : Container(
                    color: const Color(0xFF1A1A2E),
                    child: const Center(
                      child: Icon(
                        Icons.videocam_off,
                        color: Colors.white54,
                        size: 64,
                      ),
                    ),
                  ),
          ),

          // Top stats bar
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      _liveChip(),
                      const SizedBox(width: 10.0),
                      _statChip(Icons.remove_red_eye, '$_viewers'),
                      const Spacer(),
                      _statChip(
                        Icons.card_giftcard,
                        '$_totalGifts🪙',
                        color: Colors.amber,
                      ),
                      const SizedBox(width: 8.0),
                      _statChip(Icons.timer, _formatDuration(_duration)),
                      const SizedBox(width: 8.0),
                      GestureDetector(
                        onTap: _endStream,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12.0,
                            vertical: 6.0,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: const Text(
                            'End',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Bottom: chat + controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // Chat messages
                Container(
                  height: 160.0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 6.0,
                  ),
                  child: ListView.builder(
                    controller: _chatScroll,
                    itemCount: _chatMessages.length,
                    itemBuilder: (context, idx) {
                      final msg = _chatMessages[idx];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 3.0),
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: '${msg['sender']}: ',
                                style: TextStyle(
                                  color: msg['isGift'] == true
                                      ? Colors.amber
                                      : Colors.white70,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12.0,
                                ),
                              ),
                              TextSpan(
                                text: msg['text'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.0,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Controls row
                Container(
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 10.0,
                  ),
                  child: Row(
                    children: [
                      _controlBtn(
                        _muted ? Icons.mic_off : Icons.mic,
                        _toggleMute,
                        active: _muted,
                      ),
                      const SizedBox(width: 8.0),
                      _controlBtn(
                        _cameraEnabled ? Icons.videocam : Icons.videocam_off,
                        _toggleCamera,
                        active: !_cameraEnabled,
                      ),
                      const SizedBox(width: 8.0),
                      _controlBtn(Icons.flip_camera_ios, _flipCamera),
                      const SizedBox(width: 8.0),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.white12,
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: TextField(
                            controller: _chatCtrl,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.0,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Say something…',
                              hintStyle: TextStyle(color: Colors.white38),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            onSubmitted: (_) => _sendChat(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8.0),
                      CircleAvatar(
                        backgroundColor: AppColors.primary,
                        radius: 20.0,
                        child: IconButton(
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                            size: 16.0,
                          ),
                          onPressed: _sendChat,
                        ),
                      ),
                    ],
                  ),
                ),

                // Gift options
                Container(
                  height: 60.0,
                  color: Colors.black54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12.0,
                    vertical: 6.0,
                  ),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _giftOptions.map((g) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: InkWell(
                          onTap: () => _showGiftOptions(g),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10.0,
                              vertical: 4.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white10,
                              borderRadius: BorderRadius.circular(14.0),
                              border: Border.all(color: Colors.white24),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  g['emoji'] as String,
                                  style: const TextStyle(fontSize: 16.0),
                                ),
                                const SizedBox(width: 4.0),
                                Text(
                                  '${g['coins']}🪙',
                                  style: const TextStyle(
                                    color: Colors.amber,
                                    fontSize: 11.0,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: MediaQuery.of(context).padding.bottom),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showGiftOptions(Map<String, dynamic> gift) {
    Get.snackbar(
      'Viewers can send gifts!',
      '${gift['emoji']} ${gift['name']} (${gift['coins']} coins) will appear here.',
    );
  }

  Widget _liveChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: const Text(
        'LIVE',
        style: TextStyle(
          color: Colors.white,
          fontSize: 11.0,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _statChip(IconData icon, String label, {Color? color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: Row(
        children: [
          Icon(icon, color: color ?? Colors.white70, size: 13.0),
          const SizedBox(width: 4.0),
          Text(
            label,
            style: TextStyle(
              color: color ?? Colors.white,
              fontSize: 12.0,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, VoidCallback onTap, {bool active = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40.0,
        height: 40.0,
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white24,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          color: active ? Colors.black : Colors.white,
          size: 18.0,
        ),
      ),
    );
  }
}
