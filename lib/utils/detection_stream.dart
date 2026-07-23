import 'dart:async';
import 'dart:convert';
import 'package:camera_application/models/detection.dart';
import 'package:camera_application/utils/api/network.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DetectionStream {
  final NetworkUtils networkUtils;
  final String cameraId;

  WebSocketChannel? _channel;
  final _controller = StreamController<List<Detection>>.broadcast();
  Stream<List<Detection>> get detections => _controller.stream;
  bool _disposed = false;
  int _retryDelaySeconds = 5;

  DetectionStream({required this.networkUtils, required this.cameraId});

  void connect(String wsUrl) {
    _disposed = false;
    _connectLoop(wsUrl);
  }

  Future<void> _connectLoop(String wsUrl) async {
    // Once true, the next iteration forces a brand new session token
    // instead of reusing whatever's cached (used after an auth failure).
    bool forceRefresh = false;

    while (!_disposed) {
      try {
        final token = forceRefresh
            ? await networkUtils.requestToken(cameraId)
            : await networkUtils.getSessionToken(cameraId);
        forceRefresh = false;

        // The server checks the Authorization header on the websocket
        // handshake, so we need IOWebSocketChannel (which supports custom
        // headers) rather than the generic WebSocketChannel.connect().
        _channel = IOWebSocketChannel.connect(
          Uri.parse(wsUrl),
          headers: {'Authorization': 'Bearer $token'},
        );
        await _channel!.ready;
        _retryDelaySeconds = 5;

        await for (final message in _channel!.stream) {
          final List<dynamic> raw = jsonDecode(message as String);
          _controller.add(raw
              .map((e) => Detection.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      } catch (e) {
        // A failed handshake here (rejected auth included) or a dropped
        // connection both land here. Since we can't cheaply tell "expired
        // token" apart from "network blip", just force a token refresh
        // before the next retry - worst case it's a harmless extra call.
        forceRefresh = true;
      }

      if (_disposed) return;
      await Future.delayed(Duration(seconds: _retryDelaySeconds));
    }
  }

  void dispose() {
    _disposed = true;
    _channel?.sink.close();
    _controller.close();
  }
}