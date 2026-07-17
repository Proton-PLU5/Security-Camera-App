import 'package:camera_application/models/camera.dart';
import 'package:camera_application/pages/camera_add.dart';
import 'package:camera_application/utils/camera_discovery_service.dart';
import 'package:camera_application/widgets/wifi_search_icon.dart';
import 'package:flutter/material.dart';

import '../models/discovered_camera.dart';

class CameraBrowsePage extends StatefulWidget {
  const CameraBrowsePage({super.key});

  @override
  State<CameraBrowsePage> createState() => _CameraBrowsePageState();
}

class _CameraBrowsePageState extends State<CameraBrowsePage> {

  bool isSearching = true;
  final List<DiscoveredCamera> cameras = [];
  CameraDiscoveryService? _discoveryService;

  @override
  void initState() {
    super.initState();
    _discoveryService = CameraDiscoveryService();

    search();

    // Fake camera data for testing
    DiscoveredCamera fakeCamera1 = DiscoveredCamera(
      id: 'camera1',
      name: 'Camera 1',
      ip: '192.168.0.161',
      port: 8080,
      version: '1.0',
    );

    cameras.add(fakeCamera1);
  }

  void search() {
    cameras.clear();

    setState(() => isSearching = true);
    _discoveryService!.start().then((_) {
      _discoveryService!.discoverCameras().listen(
        (camera) {
          setState(() => cameras.add(camera));
        },
        onDone: () {
          _discoveryService!.stop();
          setState(() => isSearching = false);
        },
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: isSearching ? Text('Searching for Cameras') : Text('Discovered ${cameras.length} Cameras'),
      ),
      body: Column(
        children: [
          if (isSearching)
            const LinearProgressIndicator(),
          
          Stack(
            children: [
              Positioned(child: 
                WifiSearchIcon(isSearching: isSearching, onTap: () {
                  if (!isSearching) {
                    search();
                  }
                }),
              ),
            ]
          ),

          Expanded(
            child: ListView.builder(
              itemCount: cameras.length,
              itemBuilder: (context, index) {
                final camera = cameras[index];
                return ListTile(
                  title: Text(camera.name),
                  subtitle: Text('${camera.ip}:${camera.port}'),
                  trailing: Text('Version: ${camera.version}'),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.blue,
                    ),
                    child: Center(
                      child: Icon(Icons.videocam, color: Colors.white),
                    ),
                  ),
                  onTap: () async {
                    // Handle camera selection
                    final setupCamera = await Navigator.push<Camera>(
                      context,
                      MaterialPageRoute(builder: (context) => CameraAddPage(camera: camera)),
                    );

                    if (setupCamera != null && context.mounted) {
                      Navigator.pop(context, setupCamera);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}