import 'dart:convert';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dating_app/core/constants/app_colors.dart';
import 'package:dating_app/core/constants/api_urls.dart';
import 'package:dating_app/core/network/network_api_service.dart';
import 'package:dating_app/features/auth/controllers/auth_controller.dart';

const _giftOptions = [
  {'name': 'Heart', 'emoji': '❤️', 'coins': 5},
  {'name': 'Star', 'emoji': '⭐', 'coins': 10},
  {'name': 'Fire', 'emoji': '🔥', 'coins': 20},
  {'name': 'Diamond', 'emoji': '💎', 'coins': 50},
  {'name': 'Crown', 'emoji': '👑', 'coins': 100},
  {'name': 'Rocket', 'emoji': '🚀', 'coins': 200},
];

class WatchStreamView extends StatefulWidget {
  const WatchStreamView({super.key});

  @override
  State<WatchStreamView> createState() => _WatchStreamViewState();
}

class _WatchStreamViewState extends State<WatchStreamView> {
  final AuthController _authController = Get.find<AuthController>();
  final NetworkApiService _api = NetworkApiService.instance;
  final TextEditingController _chatCtrl = TextEditingController();
  final ScrollController _chatScroll = ScrollController();

  // Arguments
  String _streamId = '';
  String _title = 'Live Broadcast';

  // Stream metadata
  Map<String, dynamic>? _stream;
  bool _loading = true;
  int _viewers = 0;
  int _giftsReceived = 0;

  // Chat
  final List<Map<String, dynamic>> _chatMessages = [];

  // Agora
  RtcEngine? _engine;
  String _channelName = '';
  int? _dataStreamId;
  int? _remoteUid;
  bool _joined = false;
  bool _sendingGift = false;

  @override
  void initState() {
    super.initState();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    _streamId = args['streamId'] as String? ?? '';
    _title = args['title'] as String? ?? 'Live Broadcast';
    _joinStream();
  }

  @override
  void dispose() {
    _chatCtrl.dispose();
    _chatScroll.dispose();
    _releaseAgora();
    if (_streamId.isNotEmpty) {
      _api.post(ApiUrls.livestreamLeave(_streamId)).catchError((_) {});
    }
    super.dispose();
  }

  // ── Join stream & init Agora ───────────────────────────────────────────────

  Future<void> _joinStream() async {
    try {
      final res = await _api.post(ApiUrls.livestreamJoin(_streamId));
      final data = res.data as Map<String, dynamic>;

      final streamData = data['stream'] as Map<String, dynamic>? ?? {};
      final agoraToken = data['agora_token'] as String? ?? '';
      final channelName = data['channel_name'] as String? ?? '';
      final agoraAppId = data['agora_app_id'] as String? ?? '';

      setState(() {
        _stream = streamData;
        _title = streamData['title'] as String? ?? _title;
        _viewers = (streamData['viewer_count'] as num?)?.toInt() ?? 0;
        _giftsReceived = (streamData['total_gifts_received'] as num?)?.toInt() ?? 0;
        _chatMessages.add({
          'sender': 'System',
          'text': '👋 You joined $_title',
          'isGift': false,
        });
      });

      await _initAgora(appId: agoraAppId, token: agoraToken, channel: channelName);
    } catch (e) {
      Get.defaultDialog(
        title: 'Cannot join stream',
        middleText: 'Stream may have ended.',
        textConfirm: 'Go back',
        onConfirm: () => Get.back(),
        barrierDismissible: false,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _initAgora({
    required String appId,
    required String token,
    required String channel,
  }) async {
    _channelName = channel;
    final engine = createAgoraRtcEngine();
    _engine = engine;

    await engine.initialize(RtcEngineContext(appId: appId));
    await engine.setChannelProfile(ChannelProfileType.channelProfileLiveBroadcasting);
    await engine.setClientRole(role: ClientRoleType.clientRoleAudience);

    // Data stream for receiving chat & gift messages from broadcaster
    final streamId = await engine.createDataStream(
      const DataStreamConfig(syncWithAudio: false, ordered: false),
    );
    _dataStreamId = streamId;

    engine.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (connection, elapsed) {
        if (mounted) setState(() => _joined = true);
      },
      onUserJoined: (connection, remoteUid, elapsed) {
        // Broadcaster joined
        if (mounted) setState(() => _remoteUid = remoteUid);
      },
      onUserOffline: (connection, remoteUid, reason) {
        // Broadcaster went offline
        if (mounted) {
          setState(() => _remoteUid = null);
          Get.defaultDialog(
            title: 'Stream Ended',
            middleText: 'The broadcaster has ended the stream.',
            textConfirm: 'Go Back',
            onConfirm: () => Get.back(),
            barrierDismissible: false,
          );
        }
      },
      onStreamMessage: (connection, remoteUid, streamId, data, length, sentTs) {
        _handleStreamMessage(data);
      },
      onError: (err, msg) {
        if (mounted) debugPrint('Agora Viewer Error: $msg');
      },
    ));

    await engine.enableVideo();

    await engine.joinChannel(
      token: token,
      channelId: channel,
      uid: 0,
      options: const ChannelMediaOptions(
        channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        clientRoleType: ClientRoleType.clientRoleAudience,
        publishMicrophoneTrack: false,
        publishCameraTrack: false,
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
            'sender': msgObj['sender'] ?? 'Host',
            'text': msgObj['text'] ?? '',
            'isGift': false,
          });
        } else if (msgObj['type'] == 'gift') {
          _chatMessages.add({
            'sender': msgObj['sender'] ?? 'Viewer',
            'text': 'sent a ${msgObj['giftName']}! ${msgObj['giftEmoji']}',
            'isGift': true,
          });
          _giftsReceived += (msgObj['coins'] as num?)?.toInt() ?? 0;
        }
      });
      _scrollChatToBottom();
    } catch (_) {}
  }

  Future<void> _releaseAgora() async {
    final engine = _engine;
    if (engine != null) {
      await engine.leaveChannel();
      await engine.release();
      _engine = null;
    }
  }

  // ── Send gift ──────────────────────────────────────────────────────────────

  Future<void> _sendGift(Map<String, dynamic> gift) async {
    if (_sendingGift) return;
    setState(() => _sendingGift = true);

    try {
      await _api.post(ApiUrls.livestreamSendGift(_streamId), data: {
        'gift_name': gift['name'],
        'gift_emoji': gift['emoji'],
        'coins': gift['coins'],
      });

      setState(() {
        _giftsReceived += (gift['coins'] as int);
      });

      // Broadcast gift over Agora DataStream to host & other viewers
      if (_engine != null && _dataStreamId != null) {
        final myName = _authController.profile.value?.name ?? 'Viewer';
        final payload = jsonEncode({
          'type': 'gift',
          'sender': myName,
          'giftName': gift['name'],
          'giftEmoji': gift['emoji'],
          'coins': gift['coins'],
        });
        await _engine!.sendStreamMessage(
          streamId: _dataStreamId!,
          data: Uint8List.fromList(utf8.encode(payload)),
          length: utf8.encode(payload).length,
        );
      }

      final myName = _authController.profile.value?.name ?? 'You';
      setState(() {
        _chatMessages.add({
          'sender': myName,
          'text': 'sent a ${gift['name']}! ${gift['emoji']}',
          'isGift': true,
        });
      });
      _scrollChatToBottom();
      Get.snackbar('Gift Sent ${gift['emoji']}', 'You sent a ${gift['name']} for ${gift['coins']} coins.');
    } catch (e) {
      Get.snackbar('Gift failed', e.toString());
    } finally {
      if (mounted) setState(() => _sendingGift = false);
    }
  }

  // ── Send chat ──────────────────────────────────────────────────────────────

  void _sendChat() {
    final text = _chatCtrl.text.trim();
    if (text.isEmpty) return;
    _chatCtrl.clear();

    final myName = _authController.profile.value?.name ?? 'You';
    setState(() {
      _chatMessages.add({'sender': myName, 'text': text, 'isGift': false});
    });
    _scrollChatToBottom();

    // Send over Agora DataStream
    if (_engine != null && _dataStreamId != null) {
      final payload = jsonEncode({'type': 'chat', 'sender': myName, 'text': text});
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1020),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SafeArea(
              child: Column(
                children: [
                  // Top bar
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => Get.back(),
                        ),
                        _liveChip(),
                        const SizedBox(width: 10.0),
                        Row(
                          children: [
                            const Icon(Icons.remove_red_eye, color: Colors.white, size: 14.0),
                            const SizedBox(width: 4.0),
                            Text('$_viewers',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.8),
                            borderRadius: BorderRadius.circular(10.0),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.card_giftcard, color: Colors.white, size: 14.0),
                              const SizedBox(width: 4.0),
                              Text('$_giftsReceived',
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Remote Video (host's stream)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E2540),
                        borderRadius: BorderRadius.circular(20.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: _engine != null && _remoteUid != null
                          ? AgoraVideoView(
                              controller: VideoViewController.remote(
                                rtcEngine: _engine!,
                                canvas: VideoCanvas(uid: _remoteUid!),
                                connection: RtcConnection(channelId: _channelName),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(color: Colors.white54),
                                  const SizedBox(height: 14.0),
                                  Text(
                                    _title,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 18.0, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 6.0),
                                  const Text('Waiting for host…',
                                      style: TextStyle(color: Colors.white54, fontSize: 13.0)),
                                ],
                              ),
                            ),
                    ),
                  ),

                  // Gift options row
                  Container(
                    height: 60.0,
                    padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: _giftOptions.map((g) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: InkWell(
                            onTap: _sendingGift ? null : () => _sendGift(g),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14.0),
                              ),
                              child: Row(
                                children: [
                                  Text(g['emoji'] as String, style: const TextStyle(fontSize: 16.0)),
                                  const SizedBox(width: 6.0),
                                  Text(
                                    '${g['coins']}🪙',
                                    style: const TextStyle(
                                        color: Colors.amber, fontWeight: FontWeight.bold, fontSize: 12.0),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Chat messages
                  Container(
                    height: 130.0,
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 6.0),
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
                                    color: msg['isGift'] == true ? Colors.amber : Colors.white70,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12.0,
                                  ),
                                ),
                                TextSpan(
                                  text: msg['text'],
                                  style: const TextStyle(color: Colors.white, fontSize: 12.0),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Chat composer
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14.0),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20.0),
                            ),
                            child: TextField(
                              controller: _chatCtrl,
                              style: const TextStyle(color: Colors.white, fontSize: 14.0),
                              decoration: const InputDecoration(
                                hintText: 'Say something...',
                                hintStyle: TextStyle(color: Colors.white38),
                                border: InputBorder.none,
                              ),
                              onSubmitted: (_) => _sendChat(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8.0),
                        CircleAvatar(
                          backgroundColor: AppColors.primary,
                          child: IconButton(
                            icon: const Icon(Icons.send, color: Colors.white, size: 18.0),
                            onPressed: _sendChat,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _liveChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppColors.danger,
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: const Text('LIVE',
          style: TextStyle(color: Colors.white, fontSize: 11.0, fontWeight: FontWeight.bold)),
    );
  }
}
