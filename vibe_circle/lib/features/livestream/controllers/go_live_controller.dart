import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:vibe_circle/core/constants/api_urls.dart';
import 'package:vibe_circle/core/constants/app_colors.dart';
import 'package:vibe_circle/core/network/network_api_service.dart';
import 'package:vibe_circle/features/auth/controllers/auth_controller.dart';

class GoLiveController extends GetxController {
  final AuthController authController = Get.find<AuthController>();
  final NetworkApiService _api = NetworkApiService.instance;

  final TextEditingController titleCtrl = TextEditingController();
  final TextEditingController chatCtrl = TextEditingController();
  final ScrollController chatScroll = ScrollController();

  final RxString category = 'General'.obs;
  final RxBool starting = false.obs;

  final RxBool isLive = false.obs;
  final RxnString streamId = RxnString();
  final RxInt viewers = 0.obs;
  final RxInt totalGifts = 0.obs;
  final RxInt duration = 0.obs;
  Timer? _durationTimer;

  final RxList<Map<String, dynamic>> chatMessages =
      <Map<String, dynamic>>[].obs;

  RtcEngine? engine;
  int? dataStreamId;
  final RxBool cameraEnabled = true.obs;
  final RxBool muted = false.obs;
  final RxBool agoraReady = false.obs;

  final List<String> categories = const [
    'General',
    'Gaming',
    'Music',
    'Fitness',
    'Talk',
    'Art',
    'Education',
  ];

  @override
  void onInit() {
    super.onInit();
    initPreview();
  }

  Future<void> initPreview() async {
    try {
      final cam = await Permission.camera.request();
      final mic = await Permission.microphone.request();
      if (!cam.isGranted) return;

      if (engine == null) {
        engine = createAgoraRtcEngine();
        await engine!.initialize(const RtcEngineContext(
          appId: 'dev_preview_app_id',
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));
        await engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
        await engine!.enableVideo();
        await engine!.startPreview();
        agoraReady.value = true;
      }
    } catch (e) {
      debugPrint('Live preview error: $e');
    }
  }

  @override
  void onClose() {
    titleCtrl.dispose();
    chatCtrl.dispose();
    chatScroll.dispose();
    _durationTimer?.cancel();
    releaseAgora();
    if (streamId.value != null && streamId.value!.isNotEmpty) {
      _api.post(ApiUrls.livestreamEnd(streamId.value!)).catchError((_) => null);
    }
    super.onClose();
  }

  Future<void> startStream() async {
    final title = titleCtrl.text.trim().isEmpty
        ? 'Live Stream'
        : titleCtrl.text.trim();
    starting.value = true;

    try {
      final cam = await Permission.camera.request();
      final mic = await Permission.microphone.request();
      if (!cam.isGranted || !mic.isGranted) {
        Get.snackbar(
          'Permissions Required',
          'Camera and microphone access is needed to go live.',
        );
        starting.value = false;
        return;
      }

      final res = await _api.post(
        ApiUrls.livestreamStart,
        data: {'title': title, 'category': category.value},
      );

      final data = res.data as Map<String, dynamic>;
      final sId = data['stream']?['id']?.toString() ?? data['id']?.toString() ?? '';
      final agoraToken = data['agora_token'] as String? ?? '';
      final channelName = data['channel_name'] as String? ?? '';
      final agoraAppId = data['agora_app_id'] as String? ?? '';

      streamId.value = sId;
      isLive.value = true;

      _startDurationTimer();

      chatMessages.add({
        'sender': 'System',
        'text': '🎉 Your live stream has started!',
        'isGift': false,
      });

      await initAgora(
        appId: agoraAppId,
        token: agoraToken,
        channel: channelName,
      );
    } catch (e) {
      Get.snackbar('Start Stream Failed', e.toString());
      isLive.value = false;
    } finally {
      starting.value = false;
    }
  }

  Future<void> initAgora({
    required String appId,
    required String token,
    required String channel,
  }) async {
    try {
      if (engine == null) {
        engine = createAgoraRtcEngine();
        await engine!.initialize(RtcEngineContext(
          appId: appId.isNotEmpty ? appId : 'mock_app_id',
          channelProfile: ChannelProfileType.channelProfileLiveBroadcasting,
        ));
      }

      engine!.registerEventHandler(
        RtcEngineEventHandler(
          onJoinChannelSuccess: (connection, elapsed) async {
            agoraReady.value = true;
            try {
              dataStreamId = await engine!.createDataStream(
                const DataStreamConfig(syncWithAudio: false, ordered: true),
              );
            } catch (_) {}
          },
          onStreamMessage: (connection, uid, sId, data, length, sentTs) {
            try {
              final text = utf8.decode(data);
              final msg = jsonDecode(text) as Map<String, dynamic>;
              _onRemoteMessage(msg);
            } catch (_) {}
          },
          onUserJoined: (connection, remoteUid, elapsed) {
            viewers.value = viewers.value + 1;
          },
          onUserOffline: (connection, remoteUid, reason) {
            if (viewers.value > 0) viewers.value = viewers.value - 1;
          },
        ),
      );

      await engine!.enableVideo();
      await engine!.startPreview();
      agoraReady.value = true;

      await engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);
      if (appId.isNotEmpty && token.isNotEmpty && channel.isNotEmpty) {
        await engine!.joinChannel(
          token: token,
          channelId: channel,
          uid: 0,
          options: const ChannelMediaOptions(
            clientRoleType: ClientRoleType.clientRoleBroadcaster,
            publishCameraTrack: true,
            publishMicrophoneTrack: true,
          ),
        );
      }
    } catch (e) {
      debugPrint('Agora init error: $e');
    }
  }

  void _onRemoteMessage(Map<String, dynamic> msg) {
    chatMessages.add(msg);
    if (msg['isGift'] == true && msg['coins'] != null) {
      totalGifts.value = totalGifts.value + (msg['coins'] as num).toInt();
    }
    _scrollChat();
  }

  void sendChatMessage(String text) {
    final t = text.trim();
    if (t.isEmpty) return;

    final myName = authController.profile.value?.name ?? 'Host';
    final msg = {'sender': myName, 'text': t, 'isGift': false};

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

  void toggleMute() {
    muted.value = !muted.value;
    engine?.muteLocalAudioStream(muted.value);
  }

  void toggleCamera() {
    cameraEnabled.value = !cameraEnabled.value;
    engine?.enableLocalVideo(cameraEnabled.value);
  }

  void switchCamera() {
    engine?.switchCamera();
  }

  void _startDurationTimer() {
    _durationTimer?.cancel();
    duration.value = 0;
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      duration.value = duration.value + 1;
    });
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

  Future<void> endStream() async {
    Get.defaultDialog(
      title: 'End Stream?',
      middleText: 'Are you sure you want to stop this live broadcast?',
      textConfirm: 'End Stream',
      textCancel: 'Cancel',
      confirmTextColor: Colors.white,
      buttonColor: AppColors.danger,
      onConfirm: () async {
        Get.back();
        if (streamId.value != null) {
          try {
            await _api.post(ApiUrls.livestreamEnd(streamId.value!));
          } catch (_) {}
        }
        await releaseAgora();
        isLive.value = false;
        Get.back();
      },
    );
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
