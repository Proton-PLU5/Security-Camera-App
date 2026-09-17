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
  bool _isSirenOn = false;
  bool _showClipList = false;

  late final AnimationController _panelAnimationController;

  @override
  void initState() {
    super.initState();
    _panelAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
      value: 1.0,
    );
    // Update the current time every second
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        if (_selectedClip == null) {
          currentTimeNotifier.value = DateFormat(
            'EEE, MMM d yyyy HH:mm:ss',
          ).format(DateTime.now());
        } else {
          currentTimeNotifier.value = DateFormat(
            'EEE, MMM d yyyy HH:mm:ss',
          ).format(_selectedClip!.startedAt);
        }
      });
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
    setState(() {
      final displayTime = _selectedClip!.startedAt.add(
        Duration(milliseconds: (currentSeconds * 1000).round()),
      );

      currentTimeNotifier.value = DateFormat(
        'EEE, MMM d yyyy HH:mm:ss',
      ).format(displayTime);
    });
  }

  /// Builds a single square control tile for the 2×3 grid.
  Widget _buildControlTile({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool isActive = false,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            color: isActive
                ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isActive
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey.shade300,
              width: isActive ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 24,
                color: isActive
                    ? Theme.of(context).colorScheme.primary
                    : Colors.grey.shade700,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                  color: isActive
                      ? Theme.of(context).colorScheme.primary
                      : Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Shows a bottom sheet with directional pan/tilt controls.
  void _showPanTiltSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Pan & Tilt',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
              const SizedBox(height: 16),
              // Directional pad layout
              SizedBox(
                width: 180,
                height: 180,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Up
                    Positioned(
                      top: 0,
                      child: _buildDirectionButton(
                        icon: Icons.arrow_upward,
                        label: 'Up',
                        onPressed: () {
                          // TODO: Send tilt-up command
                        },
                      ),
                    ),
                    // Down
                    Positioned(
                      bottom: 0,
                      child: _buildDirectionButton(
                        icon: Icons.arrow_downward,
                        label: 'Down',
                        onPressed: () {
                          // TODO: Send tilt-down command
                        },
                      ),
                    ),
                    // Left
                    Positioned(
                      left: 0,
                      child: _buildDirectionButton(
                        icon: Icons.arrow_back,
                        label: 'Left',
                        onPressed: () {
                          // TODO: Send pan-left command
                        },
                      ),
                    ),
                    // Right
                    Positioned(
                      right: 0,
                      child: _buildDirectionButton(
                        icon: Icons.arrow_forward,
                        label: 'Right',
                        onPressed: () {
                          // TODO: Send pan-right command
                        },
                      ),
                    ),
                    // Center indicator
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.grey.shade200,
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Icon(
                        Icons.control_camera,
                        size: 20,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  /// Builds a single directional button for the pan/tilt bottom sheet.
  Widget _buildDirectionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: 56,
      height: 56,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 22, color: Colors.grey.shade700),
                Text(
                  label,
                  style: TextStyle(fontSize: 8, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
        ),
      ),
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

  /// Builds the 2×3 camera control panel with matching collapse/expand animations:
  /// - Collapsing: collapses upward into the top edge with vertical shrink,
  ///   an upward fractional slide, and graceful fade-out.
  /// - Expanding: mirrors the collapse animation, sliding down smoothly from the
  ///   top edge while expanding vertically and fading in.
  Widget _buildAnimatedControlPanel() {
    return AnimatedBuilder(
      animation: _panelAnimationController,
      builder: (context, child) {
        final double value = _panelAnimationController.value;
        if (value == 0.0) {
          return const SizedBox.shrink();
        }

        // Smooth curved factor for vertical height expansion/collapse
        final double heightFactor = Curves.easeInOutCubic.transform(value);
        final double opacity = value.clamp(0.0, 1.0);

        // Slide upward when collapsing, slide downward from top into place when expanding
        final double slideY = -0.45 * (1.0 - heightFactor);

        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: heightFactor,
            child: FractionalTranslation(
              translation: Offset(0.0, slideY),
              child: Opacity(
                opacity: opacity,
                child: IgnorePointer(
                  ignoring: _showClipList,
                  child: child,
                ),
              ),
            ),
          ),
        );
      },
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: GridView.count(
              crossAxisCount: 3,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.0,
              children: [
                _buildControlTile(
                  icon: _isMicEnabled ? Icons.mic : Icons.mic_off,
                  label: _isMicEnabled ? 'Mic On' : 'Mic Off',
                  isActive: _isMicEnabled,
                  onPressed: () {
                    setState(
                      () => _isMicEnabled = !_isMicEnabled,
                    );
                  },
                ),
                _buildControlTile(
                  icon: _isFlashlightOn
                      ? Icons.flashlight_on
                      : Icons.flashlight_off,
                  label: _isFlashlightOn ? 'Light On' : 'Light Off',
                  isActive: _isFlashlightOn,
                  onPressed: () {
                    setState(
                      () => _isFlashlightOn = !_isFlashlightOn,
                    );
                  },
                ),
                _buildControlTile(
                  icon: Icons.control_camera,
                  label: 'Pan / Tilt',
                  onPressed: _showPanTiltSheet,
                ),
                _buildControlTile(
                  icon: _isNightVisionOn
                      ? Icons.nightlight
                      : Icons.nightlight_outlined,
                  label: _isNightVisionOn ? 'Night On' : 'Night Off',
                  isActive: _isNightVisionOn,
                  onPressed: () {
                    setState(
                      () => _isNightVisionOn = !_isNightVisionOn,
                    );
                  },
                ),
                _buildControlTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Snapshot',
                  onPressed: () {
                    // TODO: Capture a still snapshot from the camera feed
                  },
                ),
                _buildControlTile(
                  icon: _isSirenOn
                      ? Icons.campaign
                      : Icons.campaign_outlined,
                  label: _isSirenOn ? 'Siren On' : 'Siren Off',
                  isActive: _isSirenOn,
                  onPressed: () {
                    setState(() => _isSirenOn = !_isSirenOn);
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
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

          // 2×3 grid camera control panel — animates collapse upward / expand sideways
          _buildAnimatedControlPanel(),

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
                  return Opacity(
                    opacity: clipOpacity,
                    child: child,
                  );
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
