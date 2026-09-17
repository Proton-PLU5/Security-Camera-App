import 'package:flutter/material.dart';

/// 2×3 grid camera control panel with directional collapse/expand animations.
class CameraControlPanel extends StatelessWidget {
  final AnimationController animationController;
  final bool isCollapsed;
  final bool isMicEnabled;
  final bool isFlashlightOn;
  final bool isNightVisionOn;
  final bool isPatrolActive;
  final VoidCallback onMicToggle;
  final VoidCallback onFlashlightToggle;
  final VoidCallback onPanTiltTap;
  final VoidCallback onNightVisionToggle;
  final VoidCallback onSnapshotTap;
  final VoidCallback onPatrolTap;

  const CameraControlPanel({
    super.key,
    required this.animationController,
    required this.isCollapsed,
    required this.isMicEnabled,
    required this.isFlashlightOn,
    required this.isNightVisionOn,
    required this.isPatrolActive,
    required this.onMicToggle,
    required this.onFlashlightToggle,
    required this.onPanTiltTap,
    required this.onNightVisionToggle,
    required this.onSnapshotTap,
    required this.onPatrolTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (context, child) {
        final double value = animationController.value;
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
                  ignoring: isCollapsed,
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
                CameraControlTile(
                  icon: isMicEnabled ? Icons.mic : Icons.mic_off,
                  label: isMicEnabled ? 'Mic On' : 'Mic Off',
                  isActive: isMicEnabled,
                  onPressed: onMicToggle,
                ),
                CameraControlTile(
                  icon: isFlashlightOn
                      ? Icons.flashlight_on
                      : Icons.flashlight_off,
                  label: isFlashlightOn ? 'Light On' : 'Light Off',
                  isActive: isFlashlightOn,
                  onPressed: onFlashlightToggle,
                ),
                CameraControlTile(
                  icon: Icons.control_camera,
                  label: 'Pan / Tilt',
                  onPressed: onPanTiltTap,
                ),
                CameraControlTile(
                  icon: isNightVisionOn
                      ? Icons.nightlight
                      : Icons.nightlight_outlined,
                  label: isNightVisionOn ? 'Night On' : 'Night Off',
                  isActive: isNightVisionOn,
                  onPressed: onNightVisionToggle,
                ),
                CameraControlTile(
                  icon: Icons.camera_alt_outlined,
                  label: 'Snapshot',
                  onPressed: onSnapshotTap,
                ),
                CameraControlTile(
                  icon: isPatrolActive
                      ? Icons.radar
                      : Icons.radar_outlined,
                  label: isPatrolActive ? 'Patrolling' : 'Patrol',
                  isActive: isPatrolActive,
                  onPressed: onPatrolTap,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// A single square control tile for the camera control grid.
class CameraControlTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isActive;

  const CameraControlTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isActive = false,
  });

  @override
  Widget build(BuildContext context) {
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
}
