import 'package:camera_application/widgets/camera_clip_player.dart';
import 'package:camera_application/widgets/camera_preview.dart';
import 'package:camera_application/widgets/clip_list_widget.dart';
import 'package:flutter/material.dart';
import '../models/camera.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../models/camera_clip.dart';

class CameraPage extends StatefulWidget {
  final Camera camera;

  const CameraPage({
    super.key,
    required this.camera,
  });

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> {
  Timer? _timer;
  ValueNotifier<String> currentTimeNotifier = ValueNotifier<String>(DateFormat('EEE, MMM d yyyy HH:mm:ss').format(DateTime.now()));
  bool get viewingPreview => _selectedClip == null;
  CameraClip? _selectedClip;

  @override
  void initState() {
    super.initState();
    // Update the current time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        if (_selectedClip == null) {
          currentTimeNotifier.value =
              DateFormat('EEE, MMM d yyyy HH:mm:ss').format(DateTime.now());
        } else {
          currentTimeNotifier.value =
              DateFormat('EEE, MMM d yyyy HH:mm:ss')
                  .format(_selectedClip!.startedAt);
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void showRenameDialog() {
    final controller = TextEditingController(text: widget.camera.name);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Rename Camera'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new camera name'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.camera.name = controller.text;
                  widget.camera.save();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void showChangeLocationDialog() {
    final controller = TextEditingController(text: widget.camera.location);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Change Location'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: 'Enter new location'),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  widget.camera.location = controller.text;
                  widget.camera.save();
                });
                Navigator.of(context).pop();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void deleteCameraDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Remove Camera'),
          content: const Text('Are you sure you want to remove this camera?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // Handle camera removal
                widget.camera.delete();
                Navigator.pop(context); // Close the dialog
                Navigator.pop(context, true); // Go back to the previous screen
              },
              child: const Text('Remove'),
            ),
          ],
        );
      },
    );
  }

  void updateTimeCallback(double currentSeconds) {
    setState(() {
      final displayTime = _selectedClip!.startedAt
            .add(Duration(milliseconds: (currentSeconds * 1000).round()));
      
      currentTimeNotifier.value = DateFormat('EEE, MMM d yyyy HH:mm:ss').format(displayTime);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.camera.name),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.settings),
            onSelected: (String value) {
              // Handle menu item selection
              switch (value) {
                case 'rename':
                  // Handle rename action
                  showRenameDialog();
                  break;
                case 'location':
                  // Handle change location action
                  showChangeLocationDialog();
                  break;
                case 'mark_favorite':
                  // Handle mark/unmark favorite action
                  setState(() {
                    widget.camera.isFavorite = !widget.camera.isFavorite;
                    widget.camera.save();
                  });
                  break;
                case 'remove':
                  // Handle remove camera action
                  deleteCameraDialog();
                  break;
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'rename',
                  child: Text('Rename Camera'),
                ),
                const PopupMenuItem<String>(
                  value: 'location',
                  child: Text('Change Location'),
                ),
                PopupMenuItem<String>(
                  value: 'mark_favorite',
                  child: Text(widget.camera.isFavorite ? 'Unmark Favorite' : 'Mark as Favorite'),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Text('Remove Camera', style: TextStyle(color: Colors.red)),
                ),
              ];
            },
          )
        ],
      ),
      body: Column(
        children: [
          _selectedClip == null
            ? CameraPreview(camera: widget.camera)
            : CameraClipPlayer(
                // Adding this Key forces Flutter to reconstruct the player state for a new clip
                key: ValueKey(_selectedClip!.id), 
                camera: widget.camera, 
                clip: _selectedClip!,
                updateTimeCallback: updateTimeCallback,
              ),
          

          // Action bar for camera actions
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ValueListenableBuilder(valueListenable: currentTimeNotifier, builder: (context, value, child) {
                  return Text(
                    value,
                    style: const TextStyle(fontSize: 20),
                  );
                })
              ),
              Row(children: [
                if (_selectedClip != null)
                  IconButton(
                    icon: const Icon(Icons.videocam, size: 28),
                    onPressed: () {
                      // Handle camera action
                      setState(() {
                        _selectedClip = null; // Switch to camera preview
                      });
                    },
                  ),
                IconButton(
                  icon: const Icon(Icons.fullscreen, size: 28),
                  onPressed: () {
                    // Handle camera action
                  },
                ),
              ],)
            ],
          ),
          const SizedBox(height: 8),
          
          Expanded(
            child: ClipListWidget(camera: widget.camera, onClipSelected: (clip) {
              // Handle clip selection
              setState(() {
                _selectedClip = clip;
              });
            }),
          ),
        ],
      )
    );
  }
}