import 'package:camera_application/data/TText.dart';
import 'package:camera_application/pages/settings.dart';
import 'package:flutter/material.dart';
import '../models/camera.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'camera_browse.dart';
import 'camera_page.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {

  int selectedCameraTab = 0; // Default to 2 columns
  final List<Camera> favoriteCameraBox = [];
  final Box<Camera> cameraBox = Hive.box<Camera>('cameras');
  
  @override
  void initState() {
    super.initState();
  }

  void updateFavoriteCameras() {
    favoriteCameraBox.clear();
    for (var camera in cameraBox.values) {
      if (camera.isFavorite) {
        favoriteCameraBox.add(camera);
      }
    }
  }
  
  void addCamera() {
    final newCamera = Camera(
      name: 'New Camera',
      location: 'Unknown Location',
      imagePath: 'assets/placeholder.jpg',
      uuid: DateTime.now().millisecondsSinceEpoch.toString(),
      ipAddress: '192.168.0.161',
      port: 8080,
      version: '1.0.0'
    );

    if (selectedCameraTab == 0) {
      favoriteCameraBox.add(newCamera);
    } else {
      cameraBox.add(newCamera);
    }

    setState(() {});
  }

  Camera itemAt(int index) => selectedCameraTab == 0
    ? cameraBox.values.where((c) => c.isFavorite).toList()[index]
    : cameraBox.getAt(index)!;

  int get itemCount => selectedCameraTab == 0
    ? cameraBox.values.where((c) => c.isFavorite).length
    : cameraBox.length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 8.0),
              child: Text(TText.homeTabName, style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ))
            ),
            IconButton(
              icon: const Icon(Icons.notifications, color: Colors.white, size: 28),
              onPressed: () {
                // Handle notifications action
              },
            ),
          ]
        ),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedCameraTab = 0;
                  });
                  // Handle favorites action
                },
                child: Text(TText.homeFavouriteCamerasTabName, style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: selectedCameraTab == 0 ? FontWeight.bold : FontWeight.normal,
                )),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    selectedCameraTab = 1;
                  });
                  // Handle all cameras action
                },
                child: Text(TText.homeAllCamerasTabName, style: TextStyle(
                  color: Colors.blue,
                  fontSize: 16,
                  fontWeight: selectedCameraTab == 1 ? FontWeight.bold : FontWeight.normal,
                )),
              ),
            ],
          ),

          Container(
            height: 2,
            color: Colors.grey[400],
            margin: const EdgeInsets.only(bottom: 16),
          ),

          itemCount <= 0
            ? Text(TText.homeNoCamerasMessage, style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ))
            : const SizedBox.shrink(),

          Expanded(
            child: GridView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,      // 2 columns
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.2,  // Width / Height
                ),
                itemCount: itemCount, // Number of cameras
                itemBuilder: (context, index) {
                  return Card(
                    elevation: 3,
                    clipBehavior: Clip.antiAlias,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),

                    child: InkWell(
                      onTap: () async {
                        // Open camera page
                        await Navigator.push(context, 
                          MaterialPageRoute(
                            builder: (context) => CameraPage(
                              camera: itemAt(index),
                            )
                          )
                        );

                        setState(() {});
                      },
                      child: Stack(
                        children: [
                          // Preview Image
                          Image(
                            image: AssetImage(itemAt(index).imagePath), // Placeholder
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: 90,
                          ),
                          // Camera Icon
                          Positioned(
                            top: 12,
                            right: 12,
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.blue,
                              child: const Icon(
                                Icons.videocam_outlined,
                                color: Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          // Name + location
                          Positioned(
                            left: 10,
                            bottom: 10,
                            right: 16,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              spacing: 0,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  itemAt(index).name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  itemAt(index).location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ]
                      )
                    )
                  );
                },
              ),
            ),
        ],
      ),      
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push<Camera>(context,
            MaterialPageRoute(
              builder: (context) => const CameraBrowsePage(),
            ),
          ).then((setupCamera) {
            if (setupCamera != null) {
              cameraBox.add(setupCamera);
              selectedCameraTab = 1; // Switch to All Cameras tab
              setupCamera.save(); // Save the new camera to Hive
              setState(() {});
            }
          });
        },
        tooltip: TText.homeActionButtonTooltip,
        child: const Icon(Icons.add),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: TText.homeTabName,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.camera_alt),
            label: TText.cameraTabName,
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: TText.settingsTabName,
          ),
        ],
        onTap: (index) {
          // Handle bottom navigation tap
          if (index == 2) {
            // Navigate to camera page
            Navigator.push(context, 
              MaterialPageRoute(
                builder: (context) => const SettingsPage(),
              )
            );
          } else if (index == 1) {
            // Navigate to camera page
            // Implement camera page navigation
          }
        },
      )
    );
  }
}