import 'package:flutter/material.dart';

/// Shows a modal bottom sheet with directional pan and tilt controls.
void showPanTiltBottomSheet(BuildContext context) {
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
