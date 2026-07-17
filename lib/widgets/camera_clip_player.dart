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

class CameraClipPlayer extends StatefulWidget {
  final Camera camera;
  final CameraClip clip;

  const CameraClipPlayer({
    super.key,
    required this.camera,
    required this.clip,
  });

  @override
  State<CameraClipPlayer> createState() => _CameraClipPlayerState();
}

class _CameraClipPlayerState extends State<CameraClipPlayer> {
  late VideoPlayerController _controller;
  
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';

  // Timing metadata state
  List<TimedDetection> _allDetections = [];
  List<Detection> _activeDetections = [];

  @override
  void initState() {
    super.initState();
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

    final url = Uri.parse('http://${widget.camera.ipAddress}:${widget.camera.port}/clip/${widget.clip.id}/detections');
    print('Fetching detections from: $url');
    final response = await http.get(url).timeout(const Duration(seconds: 10));

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
    
    final urlString = 'http://${widget.camera.ipAddress}:${widget.camera.port}/clip/$clipNameCleaned';
    
    _controller = VideoPlayerController.networkUrl(Uri.parse(urlString));
    await _controller.initialize();
    
    _controller.addListener(_onVideoTick);
  }

  void _onVideoTick() {
    if (!mounted || !_controller.value.isInitialized) return;

    final currentSeconds = _controller.value.position.inMilliseconds / 1000.0;

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