import 'package:camera_application/models/camera.dart';
import 'package:camera_application/models/discovered_camera.dart';
import 'package:camera_application/utils/api/network.dart';
import 'package:flutter/material.dart';

class CameraAddPage extends StatefulWidget {
  final DiscoveredCamera camera;

  const CameraAddPage({
    super.key,
    required this.camera,
  });

  @override
  State<CameraAddPage> createState() => _CameraAddPageState();
}

class _CameraAddPageState extends State<CameraAddPage> {
  String cameraName = 'My Camera';
  String cameraLocation = 'Front Door';
  bool congratsPageVisible = true;
  bool _pairing = false;
  NetworkUtils? _networkUtils;

  @override
  void initState() {
    super.initState();
    _networkUtils = NetworkUtils(
      'http://${widget.camera.ip}:${widget.camera.port}'
    );
  }
  
  @override
  Widget build(BuildContext context) {

    Column congratsPage = Column(
        children: [
          SizedBox(height: 50),
          Center(
            child: Icon(
              Icons.thumb_up_rounded,
              size: 128,
            )
          ),
          SizedBox(height: 20),
          Center(
            child: Text(
              "Congratulations on your new camera!\n Let's get it set up.",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ),
          SizedBox(height: 50),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              fixedSize: const Size(200, 50),
            ),
            onPressed: () {
              setState(() {
                congratsPageVisible = false;
              });
            },
            child: const Text('Continue'),
          ),
        ]
    );

    Column setupPage = Column(
        children: [
          SizedBox(height: 50),
          Center(
            child: const Text(
              "Let's set up your camera.",
              style: const TextStyle(fontSize: 20),
            ),
          ),

          // Setup form fields for camera configuration
          // Camera Name (label and text field)
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16.0, top: 32.0),
            child: const Text(
              'Camera Name',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
            decoration: const InputDecoration(
              labelText: 'My Camera',
            ),
            onChanged: (value) {
              setState(() {
                cameraName = value;
              });
            },
          ),
          ),

          // Camera Location (label and text field)
          Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.only(left: 16.0, top: 32.0),
            child: const Text(
              'Camera Location',
              style: TextStyle(fontSize: 16),
            ),
          ),
          Padding(padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
            decoration: const InputDecoration(
              labelText: 'Front Door',
            ),
            onChanged: (value) {
              setState(() {
                cameraLocation = value;
              });
            },
          ),
          ),

          SizedBox(height: 50),

          ElevatedButton(
            onPressed: _pairing
              ? null
              : () async {
                  setState(() => _pairing = true);

                  try {
                    // Pair the camera using the NetworkUtils class. This
                    // must succeed - and be persisted - before we ever
                    // save the camera, otherwise every later session-token
                    // request will fail with no pairing secret to use.
                    await _networkUtils?.requestPairingToken(widget.camera.uuid);
                  } catch (e) {
                    if (!context.mounted) return;
                    setState(() => _pairing = false);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Could not pair with camera: $e')),
                    );
                    return;
                  }

                  // Handle setup camera action
                  Camera camera = Camera(
                    uuid: widget.camera.uuid,
                    name: cameraName,
                    location: cameraLocation,
                    ipAddress: widget.camera.ip,
                    port: widget.camera.port,
                    version: widget.camera.version
                  );

                  if (context.mounted) {
                    Navigator.pop(context, camera);
                  }
                },
            child: _pairing
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Add Camera'),
          ),
        ]
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Camera'),
      ),
      body: congratsPageVisible ? congratsPage : setupPage,
    );
  }
}