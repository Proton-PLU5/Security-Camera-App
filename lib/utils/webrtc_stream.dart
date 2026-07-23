import 'dart:async';
import 'dart:convert';
import 'package:camera_application/utils/api/network.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:http/http.dart' as http;

class WebRTCStream {
  RTCPeerConnection? peerConnection;
  MediaStream? remoteStream;
  final RTCVideoRenderer remoteRenderer = RTCVideoRenderer();
  void Function(MediaStream stream)? onRemoteStream;
  bool _disposed = false;
  int _retryDelaySeconds = 5;

  NetworkUtils networkUtils;
  String cameraId;

  WebRTCStream({required this.networkUtils, required this.cameraId});

  Future<void> connect(String serverUrl) async {
    _disposed = false;
    await remoteRenderer.initialize();
    await _connectLoop(serverUrl);
  }

  Future<void> _connectLoop(String serverUrl) async {
    while (!_disposed) {
      try {
        await _attemptConnection(serverUrl);
        _retryDelaySeconds = 5; // reset backoff on success
        return;
      } catch (e) {
        print('WebRTC connection attempt failed: $e');
        await _cleanupPeerConnection();

        if (_disposed) return;

        print('Retrying in $_retryDelaySeconds s...');
        await Future.delayed(Duration(seconds: _retryDelaySeconds));
      }
    }
  }

  Future<void> _attemptConnection(String serverUrl) async {
    final config = {
      'iceServers': [
        {'urls': 'stun:stun.l.google.com:19302'},
      ],
    };

    peerConnection = await createPeerConnection(config);

    await peerConnection!.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.RecvOnly),
    );

    peerConnection!.onTrack = (RTCTrackEvent event) async {
      if (event.track.kind == 'video') {
        final stream = event.streams.isNotEmpty
            ? event.streams[0]
            : await createLocalMediaStream('remote-video');
        if (event.streams.isEmpty) {
          await stream.addTrack(event.track);
        }
        remoteRenderer.srcObject = stream;
        remoteStream = stream;
        onRemoteStream?.call(stream);
      }
    };

    // If the connection drops after a successful handshake, reconnect.
    peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('Connection state changed: $state');
      if (!_disposed &&
          (state ==
                  RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
              state ==
                  RTCPeerConnectionState
                      .RTCPeerConnectionStateDisconnected)) {
        _cleanupPeerConnection().then((_) {
          if (!_disposed) _connectLoop(serverUrl);
        });
      }
    };

    // Wait for ICE gathering to finish (server has no trickle-ICE endpoint)
    final offer = await peerConnection!.createOffer();
    await peerConnection!.setLocalDescription(offer);

    final completer = Completer<void>();

    peerConnection!.onIceGatheringState = (state) {
      if (state == RTCIceGatheringState.RTCIceGatheringStateComplete) {
        if (!completer.isCompleted) completer.complete();
      }
    };

    peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      if (candidate.candidate == null || candidate.candidate!.isEmpty) {
        if (!completer.isCompleted) completer.complete();
      }
    };

    if (peerConnection!.iceGatheringState ==
        RTCIceGatheringState.RTCIceGatheringStateComplete) {
      if (!completer.isCompleted) completer.complete();
    }

    try {
      await completer.future.timeout(const Duration(seconds: 5));
    } on TimeoutException {
      print('ICE gathering timed out, proceeding with partial candidates');
    }

    final localDesc = await peerConnection!.getLocalDescription();
    if (localDesc == null) {
      throw Exception('Local description is null after ICE gathering');
    }

    final response = await _postOffer(serverUrl, localDesc,);

    final answerData = jsonDecode(response.body);
    final answer =
        RTCSessionDescription(answerData['sdp'], answerData['type']);
    await peerConnection!.setRemoteDescription(answer);
  }

  Future<http.Response> _postOffer(
    String serverUrl,
    RTCSessionDescription localDesc, {
    bool isRetry = false,
  }) async {
    // Use the cached session token when we have one; only mint a brand new
    // one (via the persistent pairing secret) once we know the cached
    // token was actually rejected (isRetry == true, see below).
    final token = isRetry
        ? await networkUtils.requestToken(cameraId)
        : await networkUtils.getSessionToken(cameraId);

    final response = await http.post(
      Uri.parse('$serverUrl/offer'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'sdp': localDesc.sdp,
        'type': localDesc.type,
      }),
    );

    if (response.statusCode == 401) {
      if (isRetry) {
        throw Exception('Reauthentication failed. Please check your credentials.');
      }
      return _postOffer(serverUrl, localDesc, isRetry: true);
    }

    return response;
  }

  Future<void> _cleanupPeerConnection() async {
    try {
      await peerConnection?.close();
    } catch (_) {}
    peerConnection = null;
    remoteRenderer.srcObject = null;
    remoteStream = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await _cleanupPeerConnection();
    await remoteRenderer.dispose();
  }
}