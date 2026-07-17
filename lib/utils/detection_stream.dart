import 'dart:async';
import 'dart:convert';
import 'package:camera_application/models/detection.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class DetectionStream {
  WebSocketChannel? _channel;
  final _controller = StreamController<List<Detection>>.broadcast();
  Stream<List<Detection>> get detections => _controller.stream;
  bool _disposed = false;
  int _retryDelaySeconds = 5;

  void connect(String wsUrl) {
    _disposed = false;
    _connectLoop(wsUrl);
  }

  Future<void> _connectLoop(String wsUrl) async {
    while (!_disposed) {
      try {
        _channel = WebSocketChannel.connect(Uri.parse(wsUrl));
        await _channel!.ready;
        _retryDelaySeconds = 5;

        await for (final message in _channel!.stream) {
          final List<dynamic> raw = jsonDecode(message as String);
          _controller.add(raw
              .map((e) => Detection.fromJson(e as Map<String, dynamic>))
              .toList());
        }
      } catch (e) {
        // fall through to retry
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