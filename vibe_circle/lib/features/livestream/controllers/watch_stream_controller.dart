import 'dart:convert';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:vibe_circle/core/constants/api_urls.dart';
import 'package:vibe_circle/core/network/network_api_service.dart';
import 'package:vibe_circle/features/auth/controllers/auth_controller.dart';

class WatchStreamController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final NetworkApiService _api = NetworkApiService.instance;
  final TextEditingController chatCtrl = TextEditingController();
  final ScrollController chatScroll = ScrollController();

  final RxString streamId = ''.obs;
  final RxString title = 'Live Broadcast'.obs;

  final Rxn<Map<String, dynamic>> stream = Rxn<Map<String, dynamic>>();
  final RxBool loading = true.obs;
  final RxInt viewers = 0.obs;
  final RxInt giftsReceived = 0.obs;

  final RxList<Map<String, dynamic>> chatMessages = <Map<String, dynamic>>[].obs;

  RtcEngine? engine;
  final RxString channelName = ''.obs;
  final RxnInt remoteUid = RxnInt();
  final RxBool joined = false.obs;
  final RxBool sendingGift = false.obs;
  int? dataStreamId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments as Map<String, dynamic>? ?? {};
    streamId.value = args['streamId'] as String? ?? '';
    title.value = args['title'] as String? ?? 'Live Broadcast';
    joinStream();
  }

  @override
  void onClose() {
    chatCtrl.dispose();
    chatScroll.dispose();
    releaseAgora();
    if (streamId.value.isNotEmpty) {
      _api.post(ApiUrls.livestreamLeave(streamId.value)).catchError((_) {});
    }
    super.onClose();
  }

  Future<void> joinStream() async {
    try {
      final res = await _api.post(ApiUrls.livestreamJoin(streamId.value));
      final data = res.data as Map<String, dynamic>;

      final streamData = data['stream'] as Map<String, dynamic>? ?? {};
      final agoraToken = data['agora_token'] as String? ?? '';
      final cName = data['channel_name'] as String? ?? '';
      final agoraAppId = data['agora_app_id'] as String? ?? '';

      stream.value = streamData;
      title.value = streamData['title'] as String? ?? title.value;
      viewers.value = (streamData['viewer_count'] as num?)?.toInt() ?? 0;
      giftsReceived.value = (streamData['total_gifts_received'] as num?)?.toInt() ?? 0;
      
      chatMessages.add({
        'sender': 'System',
        'text': '👋 You joined ${title.value}',
        'isGift': false,
      });

      await initAgora(
        appId: agoraAppId,
        token: agoraToken,
        channel: cName,
      );
    } catch (_) {
      loading.value = false;
    }
  }

  Future<void> initAgora({
    required String appId,
    required String token,
    required String channel,
  }) async {
    try {
      if (appId.isEmpty) {
        loading.value = false;
        return;
      }

      channelName.value = channel;
      engine = createAgoraRtcEngine();
      await engine!.initialize(RtcEngineContext(appId: appId));

      engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) async {
            joined.value = true;
            loading.value = false;
            try {
              dataStreamId = await engine!.createDataStream(
                const DataStreamConfig(syncWithAudio: false, ordered: true),
              );
            } catch (_) {}
          },
          onUserJoined: (connection, rUid, elapsed) {
            remoteUid.value = rUid;
          },
          onUserOffline: (connection, rUid, reason) {
            if (remoteUid.value == rUid) {
              remoteUid.value = null;
            }
          },
          onStreamMessage: (connection, uid, streamId, data, length, sentTs) {
            try {
              final text = utf8.decode(data);
              final msg = jsonDecode(text) as Map<String, dynamic>;
              _onRemoteMessage(msg);
            } catch (_) {}
          },
        ),
      );

      await engine!.enableVideo();
      await engine!.setClientRole(role: ClientRoleType.clientRoleAudience);
      await engine!.joinChannel(
        token: token,
        channelId: channel,
        uid: 0,
        options: const ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleAudience,
          autoSubscribeAudio: true,
          autoSubscribeVideo: true,
        ),
      );
    } catch (_) {
      loading.value = false;
    }
  }

  void _onRemoteMessage(Map<String, dynamic> msg) {
    chatMessages.add(msg);
    _scrollChat();
  }

  void sendChatMessage(String text) {
    final t = text.trim();
    if (t.isEmpty) return;

    final myName = authController.profile.value?.name ?? 'Viewer';
    final msg = {
      'sender': myName,
      'text': t,
      'isGift': false,
    };

    chatMessages.add(msg);
    _scrollChat();
    chatCtrl.clear();

    if (dataStreamId != null && engine != null) {
      try {
        final bytes = Uint8List.fromList(utf8.encode(jsonEncode(msg)));
        engine!.sendStreamMessage(
          streamId: dataStreamId!,
          data: bytes,
          length: bytes.length,
        );
      } catch (_) {}
    }
  }

  Future<void> sendGift(Map<String, dynamic> gift) async {
    if (sendingGift.value) return;
    final cost = gift['coins'] as int? ?? 10;
    final currentCoins = authController.coins.value;

    if (currentCoins < cost) {
      Get.snackbar('Not enough coins', 'You need $cost coins to send this gift.');
      return;
    }

    sendingGift.value = true;
    try {
      final res = await _api.post(
        ApiUrls.sendGift,
        data: {
          'target_type': 'stream',
          'target_id': streamId.value,
          'gift_type': gift['name'],
          'coins': cost,
        },
      );

      final myName = authController.profile.value?.name ?? 'Viewer';
      final giftMsg = {
        'sender': myName,
        'text': 'sent ${gift['emoji']} ${gift['name']} ($cost coins)',
        'isGift': true,
        'emoji': gift['emoji'],
      };

      chatMessages.add(giftMsg);
      giftsReceived.value = giftsReceived.value + 1;
      _scrollChat();

      if (res.data is Map && res.data['remaining_coins'] != null) {
        authController.coins.value = (res.data['remaining_coins'] as num).toInt();
      } else {
        authController.coins.value = currentCoins - cost;
      }

      if (dataStreamId != null && engine != null) {
        try {
          final bytes = Uint8List.fromList(utf8.encode(jsonEncode(giftMsg)));
          engine!.sendStreamMessage(
            streamId: dataStreamId!,
            data: bytes,
            length: bytes.length,
          );
        } catch (_) {}
      }
    } catch (e) {
      Get.snackbar('Gift Failed', e.toString());
    } finally {
      sendingGift.value = false;
    }
  }

  void _scrollChat() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (chatScroll.hasClients) {
        chatScroll.animateTo(
          chatScroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> releaseAgora() async {
    try {
      if (engine != null) {
        await engine!.leaveChannel();
        await engine!.release();
        engine = null;
      }
    } catch (_) {}
  }
}
