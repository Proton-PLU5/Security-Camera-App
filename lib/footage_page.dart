import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:video_player/video_player.dart';

class FootagePage extends StatefulWidget {
  final String serverUrl;

  const FootagePage({super.key, required this.serverUrl});

  @override
  State<FootagePage> createState() => _FootagePageState();
}

class _FootagePageState extends State<FootagePage> {
  List<dynamic> _clips = [];
  Map<String, dynamic>? _selectedClip;
  VideoPlayerController? _videoController;
  bool _isLoadingList = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _fetchClips();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  // Matches the /clips endpoint logic from viewer.html
  Future<void> _fetchClips() async {
    setState(() {
      _isLoadingList = true;
      _hasError = false;
    });
    try {
      final res = await http.get(Uri.parse('${widget.serverUrl}/clips'));
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        setState(() {
          _clips = data; // Keep natural ordering or .reversed if needed
          _isLoadingList = false;
          if (_clips.isNotEmpty) {
            _changeClip(_clips.first);
          }
        });
      } else {
        throw Exception();
      }
    } catch (e) {
      setState(() {
        _isLoadingList = false;
        _hasError = true;
      });
    }
  }

  // Instantiates a standard video streaming controller for the specific clip ID
  Future<void> _changeClip(Map<String, dynamic> clip) async {
    setState(() {
      _selectedClip = clip;
    });

    await _videoController?.dispose();
    
    final clipId = clip['id'];
    final clipUrl = '${widget.serverUrl}/clips/$clipId';

    _videoController = VideoPlayerController.networkUrl(Uri.parse(clipUrl));
    
    try {
      await _videoController!.initialize();
      setState(() {});
      _videoController!.play();
    } catch (e) {
      print("Error loading video clip: $e");
    }
  }

  String _formatClipLabel(Map<String, dynamic> clip) {
    try {
      final startTimeRaw = clip['started_at'];
      final startTime = startTimeRaw is String ? double.tryParse(startTimeRaw) : startTimeRaw;
      if (startTime == null) return "Clip #${clip['id']} (Invalid Date)";

      final start = DateTime.fromMillisecondsSinceEpoch(startTime.toInt());
      final trigger = clip['trigger'] ?? "unknown";
      return "${start.toLocal()} [$trigger]";
    } catch (e) {
      return "Clip #${clip['id'] ?? 'unknown'}";
    }
  }

  void _openFullscreen(BuildContext context) async {
    if (_videoController == null || !_videoController!.value.isInitialized) return;

    // Force Landscape Layout
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    if (!context.mounted) return;

    await Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => PopScope(
          onPopInvokedWithResult: (didPop, result) async {
            if (didPop) {
              await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
              await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
            }
          },
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                Center(
                  child: AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: VideoPlayer(_videoController!),
                  ),
                ),
                Positioned(
                  top: 20,
                  right: 20,
                  child: SafeArea(
                    child: IconButton(
                      icon: const Icon(Icons.fullscreen_exit, color: Colors.white, size: 36),
                      onPressed: () async {
                        await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
                        await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
                        if (context.mounted) Navigator.of(context).pop();
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recorded Clips'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Video Display Frame
          AspectRatio(
            aspectRatio: 16 / 10,
            child: Container(
              color: Colors.black,
              child: _videoController != null && _videoController!.value.isInitialized
                  ? Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        Center(
                          child: AspectRatio(
                            aspectRatio: _videoController!.value.aspectRatio,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                        VideoProgressIndicator(_videoController!, allowScrubbing: true),
                      ],
                    )
                  : const Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
          ),
          
          const SizedBox(height: 16),

          // Control & Selection Options Drawer Panel
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              children: [
                if (_isLoadingList)
                  const CircularProgressIndicator()
                else if (_hasError)
                  ElevatedButton(
                    onPressed: _fetchClips,
                    child: const Text('Failed to load clips. Retry'),
                  )
                else if (_clips.isEmpty)
                  const Text("No clips recorded yet.", style: TextStyle(color: Colors.black54))
                else
                  // Custom Dropdown Container styled like your App Buttons
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.black, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<Map<String, dynamic>>(
                        isExpanded: true,
                        value: _selectedClip,
                        items: _clips.map((clip) {
                          return DropdownMenuItem<Map<String, dynamic>>(
                            value: clip,
                            child: Text(_formatClipLabel(clip), style: const TextStyle(fontSize: 14)),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          if (newValue != null) _changeClip(newValue);
                        },
                      ),
                    ),
                  ),

                const SizedBox(height: 24),

                // Control Action Buttons Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    OutlinedButton(
                      onPressed: () => _openFullscreen(context),
                      style: ButtonStyle(
                        fixedSize: WidgetStateProperty.all(const Size(100, 100)),
                        side: WidgetStateProperty.all(const BorderSide(color: Colors.black, width: 2)),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(35))),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.fullscreen,       // Icon choice
                            color: Colors.black,   // Icon color
                            size: 48.0,           // Icon size in pixels
                          ),
                          Text('Fullscreen', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    OutlinedButton(
                      onPressed: () {
                        if (_videoController != null) {
                          _videoController!.value.isPlaying 
                              ? _videoController!.pause() 
                              : _videoController!.play();
                          setState(() {});
                        }
                      },
                      style: ButtonStyle(
                        fixedSize: WidgetStateProperty.all(const Size(100, 100)),
                        side: WidgetStateProperty.all(const BorderSide(color: Colors.black, width: 2)),
                        shape: WidgetStateProperty.all(RoundedRectangleBorder(borderRadius: BorderRadius.circular(35))),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _videoController?.value.isPlaying == true ? Icons.pause : Icons.play_arrow,
                            color: Colors.black,
                            size: 44,
                          ),
                          Text(_videoController?.value.isPlaying == true ? 'Pause' : 'Play', style: const TextStyle(fontSize: 12, color: Colors.black)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}