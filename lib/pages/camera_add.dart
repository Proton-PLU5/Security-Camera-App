import 'package:camera_application/models/camera.dart';
import 'package:camera_application/models/discovered_camera.dart';
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
            onPressed: () {
              // Handle setup camera action
              Camera camera = Camera(
                uuid: widget.camera.id,
                name: cameraName,
                location: cameraLocation,
                ipAddress: widget.camera.ip,
                port: widget.camera.port,
                version: widget.camera.version,
              );

              Navigator.pop(context, camera);
            },
            child: const Text('Add Camera'),
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