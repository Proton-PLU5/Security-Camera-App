import 'package:camera_application/models/camera.dart';
import 'package:camera_application/models/detection.dart';
import 'package:camera_application/utils/detection_overlay_painter.dart';
import 'package:camera_application/utils/detection_stream.dart';
import 'package:camera_application/utils/webrtc_stream.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:camera_application/utils/api/network.dart';

class CameraPreview extends StatefulWidget {
  final Camera camera;

  const CameraPreview({super.key, required this.camera});

  @override
  State<CameraPreview> createState() => _CameraPreviewState();
}

class _CameraPreviewState extends State<CameraPreview> {
  late final WebRTCStream _webRTCStream;
  late final DetectionStream _detectionStream;
  bool _hasStream = false;
  List<Detection> _detections = [];
  NetworkUtils? _networkUtils;

  @override
  void initState() {
    super.initState();
    _networkUtils = NetworkUtils(
      'http://${widget.camera.ipAddress}:${widget.camera.port}'
    );

    _webRTCStream = WebRTCStream(
      networkUtils: _networkUtils!,
      cameraId: widget.camera.uuid,
    )
      ..onRemoteStream = (stream) {
        if (mounted) setState(() => _hasStream = true);
      };
    _webRTCStream.connect('http://${widget.camera.ipAddress}:${widget.camera.port}');

    _detectionStream = DetectionStream(networkUtils:_networkUtils!, cameraId: widget.camera.uuid)
      ..connect('ws://${widget.camera.ipAddress}:${widget.camera.port}/websocket/detections');

    _detectionStream.detections.listen((detections) {
      print('Received ${detections.length} detections');
      if (mounted) setState(() => _detections = detections);
    }); 
  }

  @override
  void dispose() {
    _webRTCStream.dispose();
    _detectionStream.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: (960 / 544),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _hasStream
              ? RTCVideoView(
                  _webRTCStream.remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                )
              : Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  AspectRatio(
                    aspectRatio: (960 / 544),
                    child: Image.asset(widget.camera.imagePath, fit: BoxFit.cover)
                  ),
                  Center(
                    child: CircularProgressIndicator(
                      color: Colors.blue,
                    ),
                  ),
                ]
              ),
          if (_hasStream)
            CustomPaint(painter: DetectionOverlayPainter(_detections)),
        ],
      ),
    );
  }
}