import 'dart:async';
import 'dart:convert';
import 'package:camera_application/models/timed_detection.dart';
import 'package:camera_application/utils/detection_overlay_painter.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';
import 'package:camera_application/models/camera.dart';
import 'package:camera_application/models/camera_clip.dart';
import 'package:camera_application/models/detection.dart';
import 'package:camera_application/utils/api/network.dart';

class CameraClipPlayer extends StatefulWidget {
  final Camera camera;
  final CameraClip clip;
  final void Function(double currentSeconds)? updateTimeCallback;

  const CameraClipPlayer({
    super.key,
    required this.camera,
    required this.clip,
    required this.updateTimeCallback,
  });

  @override
  State<CameraClipPlayer> createState() => _CameraClipPlayerState();
}

class _CameraClipPlayerState extends State<CameraClipPlayer> {
  late VideoPlayerController _controller;

  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  late final NetworkUtils _networkUtils;

  // Timing metadata state
  List<TimedDetection> _allDetections = [];
  List<Detection> _activeDetections = [];

  @override
  void initState() {
    super.initState();
    _networkUtils = NetworkUtils(
      'http://${widget.camera.ipAddress}:${widget.camera.port}'
    );
    _initializePlayerAndMetadata();
  }

  Future<void> _initializePlayerAndMetadata() async {
    try {
      await Future.wait([
        _fetchDetections(),
        _setupVideoPlayer(),
      ]);

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
        _controller.play();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
        });
      }
    }
  }

  Future<void> _fetchDetections() async {
    // 1. Fetch metadata from your new python endpoint

    final endpoint = '/clip/${widget.clip.id}/detections';
    final http.Response response = await _networkUtils.get(endpoint, widget.camera.uuid);

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = jsonDecode(response.body);
      
      // Extract sizes dynamically 
      final List<dynamic> lowresSize = data['lowres_size'] ?? [960, 544];
      final double frameWidth = lowresSize[0].toDouble();
      final double frameHeight = lowresSize[1].toDouble();
      
      final List<dynamic> detectionsJson = data['detections'];

      // 2. Map JSON utilizing your coordinate system calculations
      _allDetections = detectionsJson
          .map((json) => TimedDetection.fromClipJson(json, frameWidth, frameHeight))
          .toList();
    } else {
      throw Exception('Failed to fetch detections: ${response.statusCode}');
    }
  }

  Future<void> _setupVideoPlayer() async {
    final clipNameCleaned = widget.clip.fileName
        .replaceFirst("clip_", "")
        .replaceFirst(".mp4", "");

    final uri = Uri.parse('${_networkUtils.baseUrl}/clip/$clipNameCleaned');

    await _initVideoController(uri, isRetry: false);

    _controller.addListener(_onVideoTick);
  }

  /// Builds a fresh VideoPlayerController pointed at [uri] with the
  /// Authorization header the server requires. Uses the cached session
  /// token on the first attempt; if that gets rejected, forces a token
  /// refresh and tries exactly once more.
  Future<void> _initVideoController(Uri uri, {required bool isRetry}) async {
    final token = isRetry
        ? await _networkUtils.requestToken(widget.camera.uuid)
        : await _networkUtils.getSessionToken(widget.camera.uuid);

    _controller = VideoPlayerController.networkUrl(
      uri,
      httpHeaders: {'Authorization': 'Bearer $token'},
    );

    try {
      await _controller.initialize();
    } catch (e) {
      if (isRetry) rethrow;
      await _controller.dispose();
      await _initVideoController(uri, isRetry: true);
    }
  }

  void _onVideoTick() {
    if (!mounted || !_controller.value.isInitialized) return;

    final currentSeconds = _controller.value.position.inMilliseconds / 1000.0;

    // Call the updateTimeCallback if provided
    widget.updateTimeCallback?.call(currentSeconds);

    // Find the latest detection timestamp at or before playhead, and keep
    // all detections sharing that timestamp visible until the next one arrives.
    double? latestOffset;
    final List<TimedDetection> group = [];
    for (final d in _allDetections) {
      if (d.offsetSeconds > currentSeconds) break;
      if (latestOffset == null || d.offsetSeconds > latestOffset) {
        latestOffset = d.offsetSeconds;
        group.clear();
      }
      if (d.offsetSeconds == latestOffset) {
        group.add(d);
      }
    }
    final List<Detection> visible = group;

    if (visible.length != _activeDetections.length || !_listsAreEqual(visible, _activeDetections)) {
      setState(() {
        _activeDetections = visible;
      });
    }
  }

  bool _listsAreEqual(List<Detection> a, List<Detection> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].className != b[i].className || a[i].x != b[i].x) {
        return false;
      }
    }
    return true;
  }

  @override
  void dispose() {
    _controller.removeListener(_onVideoTick);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return AspectRatio(
        aspectRatio: 960 / 544,
        child: Container(
          color: Colors.black,
          child: Center(
            child: Text(
              'Error: $_errorMessage',
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return AspectRatio(
        aspectRatio: 960 / 544,
        child: Container(
          color: Colors.black,
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 960 / 544,
      child: Stack(
        children: [
          Positioned.fill(
            child: VideoPlayer(_controller),
          ),

          // 4. Overlay layer running your existing DetectionOverlayPainter!
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: DetectionOverlayPainter(_activeDetections),
              ),
            ),
          ),
          
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller,
              allowScrubbing: true,
              colors: const VideoProgressColors(
                playedColor: Colors.red,
                bufferedColor: Colors.white24,
                backgroundColor: Colors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}