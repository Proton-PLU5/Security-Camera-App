import 'package:camera_application/widgets/camera_clip_player.dart';
import 'package:camera_application/widgets/camera_control_panel.dart';
import 'package:camera_application/widgets/camera_preview.dart';
import 'package:camera_application/widgets/clip_list_widget.dart';
import 'package:camera_application/widgets/pan_tilt_bottom_sheet.dart';
import 'package:camera_application/widgets/patrol_bottom_sheet.dart';
import 'package:flutter/material.dart';
import 'package:camera_application/utils/api/network.dart';
import 'package:camera_application/utils/snapshot_storage.dart';
import '../models/camera.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../models/camera_clip.dart';

class CameraPage extends StatefulWidget {
  final Camera camera;

  const CameraPage({super.key, required this.camera});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with TickerProviderStateMixin {
  Timer? _timer;

  ValueNotifier<String> currentTimeNotifier = ValueNotifier<String>(
    DateFormat('EEE, MMM d yyyy HH:mm:ss').format(DateTime.now()),
  );

  bool get viewingPreview => _selectedClip == null;
  CameraClip? _selectedClip;

  // Toggle states for camera controls
  bool _isMicEnabled = false;
  bool _isFlashlightOn = false;
  bool _isNightVisionOn = false;
  bool _showClipList = false;
  String? _lastGallerySnapshotUri;

  // Patrol configuration & state
  bool _isPatrolActive = false;
  String _patrolPattern = 'Left to Right';
  int _patrolPeriodSeconds = 15;
  int _patrolWaitTimeSeconds = 5;

  late final AnimationController _panelAnimationController;

  @override
  void initState() {
    super.initState();
    _panelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    // Update the wall clock while showing the live preview.  Replay time is
    // driven by VideoPlayerController below; updating it here as well causes
    // the two sources to overwrite each other at the second boundary.
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (!mounted || _selectedClip != null) return;

      currentTimeNotifier.value = DateFormat(
        'EEE, MMM d yyyy HH:mm:ss',
      ).format(DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _panelAnimationController.dispose();
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
            decoration: const InputDecoration(
              hintText: 'Enter new camera name',
            ),
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
    final selectedClip = _selectedClip;
    if (!mounted || selectedClip == null) return;

    final displayTime = selectedClip.startedAt.add(
      // The label has whole-second precision.  Flooring prevents it from
      // advancing early at .5s (and then appearing to jump back if the native
      // player's reported position jitters slightly).
      Duration(seconds: currentSeconds.floor()),
    );

    currentTimeNotifier.value = DateFormat(
      'EEE, MMM d yyyy HH:mm:ss',
    ).format(displayTime);
  }

  void _openPatrolSheet() {
    showPatrolBottomSheet(
      context: context,
      isPatrolActive: _isPatrolActive,
      patrolPattern: _patrolPattern,
      patrolPeriodSeconds: _patrolPeriodSeconds,
      patrolWaitTimeSeconds: _patrolWaitTimeSeconds,
      onConfigChanged:
          ({
            required bool isPatrolActive,
            required String patrolPattern,
            required int patrolPeriodSeconds,
            required int patrolWaitTimeSeconds,
          }) {
            setState(() {
              _isPatrolActive = isPatrolActive;
              _patrolPattern = patrolPattern;
              _patrolPeriodSeconds = patrolPeriodSeconds;
              _patrolWaitTimeSeconds = patrolWaitTimeSeconds;
            });
          },
    );
  }

  void _toggleClipList() {
    setState(() {
      _showClipList = !_showClipList;
    });
    if (_showClipList) {
      _panelAnimationController.reverse();
    } else {
      _panelAnimationController.forward();
    }
  }

  Future<void> _takeSnapshot() async {
    final networkUtils = NetworkUtils(
      'http://${widget.camera.ipAddress}:${widget.camera.port}',
    );

    try {
      final response = await networkUtils.getSnapshot(widget.camera.uuid);
      if (response.statusCode != 200) {
        throw Exception('Camera returned HTTP ${response.statusCode}.');
      }
      if (response.bodyBytes.isEmpty) {
        throw Exception('Camera returned an empty snapshot.');
      }

      final snapshot = await SnapshotStorage.save(
        cameraId: widget.camera.uuid,
        jpegBytes: response.bodyBytes,
      );
      widget.camera.imagePath = snapshot.path;
      await widget.camera.save();

      String? galleryUri;
      try {
        galleryUri = await SnapshotStorage.saveToGallery(
          jpegBytes: response.bodyBytes,
          fileName: snapshot.uri.pathSegments.last,
        );
      } catch (_) {
        // Keep the app-private copy even when gallery access is unavailable.
      }

      if (mounted) {
        setState(() => _lastGallerySnapshotUri = galleryUri);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(
          content: Text(
            galleryUri == null
                ? 'Snapshot saved to app storage.'
                : 'Snapshot saved to Photos.',
          ),
          action: galleryUri == null
              ? null
              : SnackBarAction(
                  label: 'Open Photos',
                  onPressed: _openLastSnapshot,
                ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not take snapshot: $error')),
      );
    }
  }

  Future<void> _openLastSnapshot() async {
    final galleryUri = _lastGallerySnapshotUri;
    if (galleryUri == null) return;

    try {
      await SnapshotStorage.openInPhotos(galleryUri);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open Photos: $error')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.camera.name),
        actions: [
          if (_lastGallerySnapshotUri != null)
            IconButton(
              tooltip: 'Open last snapshot in Photos',
              icon: const Icon(Icons.photo_library_outlined),
              onPressed: _openLastSnapshot,
            ),
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
                  child: Text(
                    widget.camera.isFavorite
                        ? 'Unmark Favorite'
                        : 'Mark as Favorite',
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'remove',
                  child: Text(
                    'Remove Camera',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ];
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Camera preview or clip player
          _selectedClip == null
              ? CameraPreview(camera: widget.camera)
              : CameraClipPlayer(
                  // Adding this Key forces Flutter to reconstruct the player state for a new clip
                  key: ValueKey(_selectedClip!.id),
                  camera: widget.camera,
                  clip: _selectedClip!,
                  updateTimeCallback: updateTimeCallback,
                ),

          // Time display and live/fullscreen controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: ValueListenableBuilder(
                  valueListenable: currentTimeNotifier,
                  builder: (context, value, child) {
                    return Text(value, style: const TextStyle(fontSize: 20));
                  },
                ),
              ),
              Row(
                children: [
                  if (_selectedClip != null)
                    IconButton(
                      icon: const Icon(Icons.videocam, size: 28),
                      onPressed: () {
                        setState(() {
                          _selectedClip = null; // Switch to camera preview
                        });
                      },
                    ),
                  IconButton(
                    icon: const Icon(Icons.fullscreen, size: 28),
                    onPressed: () {
                      // Handle fullscreen action
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),

          // 2×3 grid camera control panel — animates collapse upward / expand downward
          CameraControlPanel(
            animationController: _panelAnimationController,
            isCollapsed: _showClipList,
            isMicEnabled: _isMicEnabled,
            isFlashlightOn: _isFlashlightOn,
            isNightVisionOn: _isNightVisionOn,
            isPatrolActive: _isPatrolActive,
            onMicToggle: () {
              setState(() => _isMicEnabled = !_isMicEnabled);
            },
            onFlashlightToggle: () {
              setState(() => _isFlashlightOn = !_isFlashlightOn);
            },
            onPanTiltTap: () => showPanTiltBottomSheet(context),
            onNightVisionToggle: () {
              setState(() => _isNightVisionOn = !_isNightVisionOn);
            },
            onSnapshotTap: _takeSnapshot,
            onPatrolTap: _openPatrolSheet,
          ),

          // View Clips button — styled to match control tile theme
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: _toggleClipList,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _showClipList
                        ? Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.15)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _showClipList
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: _showClipList ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _showClipList ? Icons.expand_less : Icons.video_library,
                        size: 20,
                        color: _showClipList
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade700,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _showClipList ? 'Hide Clips' : 'View Clips',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: _showClipList
                              ? FontWeight.w600
                              : FontWeight.normal,
                          color: _showClipList
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),

          // Clip list (shown only when toggled)
          if (_showClipList)
            Expanded(
              child: AnimatedBuilder(
                animation: _panelAnimationController,
                builder: (context, child) {
                  final double clipOpacity =
                      (1.0 - _panelAnimationController.value).clamp(0.0, 1.0);
                  return Opacity(opacity: clipOpacity, child: child);
                },
                child: ClipListWidget(
                  camera: widget.camera,
                  onClipSelected: (clip) {
                    // Handle clip selection
                    setState(() {
                      _selectedClip = clip;
                    });
                  },
                ),
              ),
            ),
        ],
      ),
    );
  }
}
