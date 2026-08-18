import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../constants/api_urls.dart';
import '../storage/local_storage.dart';

class WebSocketService {
  WebSocketService._();
  static final WebSocketService instance = WebSocketService._();

  final Map<String, WebSocketChannel> _channels = {};

  Future<WebSocketChannel?> connectChannel(String key, String path) async {
    // If channel already active, close it first to reconnect fresh
    if (_channels.containsKey(key)) {
      closeChannel(key);
    }

    final token = await LocalStorage.instance.getAccessToken();
    if (token == null) return null;

    final uri = Uri.parse('${ApiUrls.wsBaseUrl}$path?token=${Uri.encodeComponent(token)}');
    try {
      final channel = WebSocketChannel.connect(uri);
      _channels[key] = channel;
      return channel;
    } catch (_) {
      return null;
    }
  }

  WebSocketChannel? connect(
    String url, {
    required void Function(dynamic) onMessage,
    required void Function(dynamic) onError,
    void Function()? onDone,
  }) {
    try {
      final uri = Uri.parse(url);
      final channel = WebSocketChannel.connect(uri);
      channel.stream.listen(
        onMessage,
        onError: onError,
        onDone: () {
          closeChannel(url);
          if (onDone != null) onDone();
        },
      );
      _channels[url] = channel;
      return channel;
    } catch (_) {
      return null;
    }
  }

  void closeChannel(String key) {
    if (_channels.containsKey(key)) {
      _channels[key]?.sink.close();
      _channels.remove(key);
    }
  }

  bool send(String key, Map<String, dynamic> data) {
    final channel = _channels[key];
    if (channel != null) {
      try {
        channel.sink.add(jsonEncode(data));
        return true;
      } catch (_) {
        return false;
      }
    }
    return false;
  }

  void closeAll() {
    final keys = List<String>.from(_channels.keys);
    for (final key in keys) {
      closeChannel(key);
    }
  }
}
