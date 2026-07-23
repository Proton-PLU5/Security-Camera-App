import 'dart:convert';
import 'package:camera_application/models/camera.dart';
import 'package:camera_application/models/camera_clip.dart';
import 'package:camera_application/utils/api/network.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

class ClipListWidget extends StatefulWidget {
  final Camera camera; // Replace 'dynamic' with your actual Camera class type
  final Function(CameraClip) onClipSelected;

  const ClipListWidget({
    super.key,
    required this.camera,
    required this.onClipSelected,
  });

  @override
  State<ClipListWidget> createState() => _ClipListWidgetState();
}

class _ClipListWidgetState extends State<ClipListWidget> {
  List<CameraClip> _clips = [];
  bool _isLoading = false;
  String? _errorMessage;
  late final NetworkUtils _networkUtils;

  @override
  void initState() {
    super.initState();
    _networkUtils = NetworkUtils(
      'http://${widget.camera.ipAddress}:${widget.camera.port}'
    );
    _fetchClips();
  }

  /// Fetches clips that ended before the current system time.
  Future<void> _fetchClips() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Get current epoch timestamp in seconds (as expected by your python code)
      final double nowInSeconds = DateTime.now().millisecondsSinceEpoch / 1000;
      
      // Send a GET request to the camera to fetch clips that ended before the current time
      final http.Response response = await _networkUtils.get("/clips?before=$nowInSeconds", widget.camera.uuid);

      if (response.statusCode == 200) {
        final List<dynamic> rawData = jsonDecode(response.body);
        setState(() {
          _clips = rawData
              .map((item) => CameraClip.fromJson(item as Map<String, dynamic>))
              .toList()
            ..sort((a, b) => b.startedAt.compareTo(a.startedAt));

          _isLoading = false;
        });
      } else {
        // Parse error message from your Python backend if possible
        String backendError = "Failed to load clips";
        try {
          final errorData = jsonDecode(response.body);
          if (errorData is Map && errorData.containsKey('error')) {
            backendError = errorData['error'];
          }
        } catch (_) {}
        throw Exception('$backendError (Status: ${response.statusCode})');
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: Text(
                'Clips',
                style: TextStyle(fontSize: 20),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _fetchClips,
            ),
          ],
        ),

        Expanded(
          child: RefreshIndicator(
            onRefresh: _fetchClips,
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading && _clips.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return ListView( // Wrapped in ListView to allow pull-to-refresh to try again
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchClips,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    }

    if (_clips.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.3),
          const Center(
            child: Column(
              children: [
                Icon(Icons.video_library_outlined, size: 48, color: Colors.grey),
                SizedBox(height: 12),
                Text(
                  'No clips found',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _clips.length,
      itemBuilder: (context, index) {
        final clip = _clips[index];
        final formattedDate = DateFormat('yyyy-MM-dd HH:mm:ss').format(clip.startedAt);
        final isTriggerMotion = clip.trigger.toLowerCase() == 'motion';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTriggerMotion ? Colors.orange.shade100 : Colors.blue.shade100,
              child: Icon(
                isTriggerMotion ? Icons.motion_photos_on : Icons.videocam,
                color: isTriggerMotion ? Colors.orange.shade800 : Colors.blue.shade800,
              ),
            ),
            title: Text(
              formattedDate,
              style: const TextStyle(fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 6),
                Text(
                  'Trigger: ${clip.trigger} • Duration: ${clip.formattedDuration}',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => widget.onClipSelected(clip),
          ),
        );
      },
    );
  }
}