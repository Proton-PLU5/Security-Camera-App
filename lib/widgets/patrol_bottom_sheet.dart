import 'package:flutter/material.dart';

/// Shows a modal bottom sheet to configure and control camera patrol.
void showPatrolBottomSheet({
  required BuildContext context,
  required bool isPatrolActive,
  required String patrolPattern,
  required int patrolPeriodSeconds,
  required int patrolWaitTimeSeconds,
  required void Function({
    required bool isPatrolActive,
    required String patrolPattern,
    required int patrolPeriodSeconds,
    required int patrolWaitTimeSeconds,
  }) onConfigChanged,
}) {
  bool active = isPatrolActive;
  String pattern = patrolPattern;
  int period = patrolPeriodSeconds;
  int waitTime = patrolWaitTimeSeconds;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (sheetContext) {
      return StatefulBuilder(
        builder: (context, setModalState) {
          final primaryColor = Theme.of(context).colorScheme.primary;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20.0, 12.0, 20.0, 24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Header with Title and Status badge
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Camera Patrol',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: active
                              ? primaryColor.withValues(alpha: 0.15)
                              : Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: active ? primaryColor : Colors.grey.shade400,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              active
                                  ? Icons.radio_button_checked
                                  : Icons.radio_button_off,
                              size: 12,
                              color: active ? primaryColor : Colors.grey.shade600,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              active ? 'Patrolling' : 'Idle',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: active ? primaryColor : Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Movement Pattern (Left to Right and Up & Down only)
                  Text(
                    'Movement Pattern',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      _buildPatrolModeOption(
                        context: context,
                        icon: Icons.swap_horiz,
                        label: 'Left to Right',
                        isSelected: pattern == 'Left to Right',
                        onTap: () {
                          setModalState(() {
                            pattern = 'Left to Right';
                          });
                          onConfigChanged(
                            isPatrolActive: active,
                            patrolPattern: pattern,
                            patrolPeriodSeconds: period,
                            patrolWaitTimeSeconds: waitTime,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      _buildPatrolModeOption(
                        context: context,
                        icon: Icons.swap_vert,
                        label: 'Up & Down',
                        isSelected: pattern == 'Up & Down',
                        onTap: () {
                          setModalState(() {
                            pattern = 'Up & Down';
                          });
                          onConfigChanged(
                            isPatrolActive: active,
                            patrolPattern: pattern,
                            patrolPeriodSeconds: period,
                            patrolWaitTimeSeconds: waitTime,
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Sweep Period
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Sweep Period',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${period}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: period.toDouble(),
                    min: 5,
                    max: 60,
                    divisions: 11,
                    label: '${period}s',
                    activeColor: primaryColor,
                    onChanged: (val) {
                      setModalState(() {
                        period = val.round();
                      });
                      onConfigChanged(
                        isPatrolActive: active,
                        patrolPattern: pattern,
                        patrolPeriodSeconds: period,
                        patrolWaitTimeSeconds: waitTime,
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Fast (5s)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          'Slow (60s)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Wait / Dwell Time at Endpoints
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Wait Time at Endpoints',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          waitTime == 0 ? 'Continuous' : '${waitTime}s',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: waitTime.toDouble(),
                    min: 0,
                    max: 30,
                    divisions: 6,
                    label: waitTime == 0 ? 'Continuous' : '${waitTime}s',
                    activeColor: primaryColor,
                    onChanged: (val) {
                      setModalState(() {
                        waitTime = val.round();
                      });
                      onConfigChanged(
                        isPatrolActive: active,
                        patrolPattern: pattern,
                        patrolPeriodSeconds: period,
                        patrolWaitTimeSeconds: waitTime,
                      );
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '0s (Continuous)',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                        Text(
                          '30s pause',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Start / Stop Patrol Button (styled to match app toggle theme)
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () {
                        setModalState(() {
                          active = !active;
                        });
                        onConfigChanged(
                          isPatrolActive: active,
                          patrolPattern: pattern,
                          patrolPeriodSeconds: period,
                          patrolWaitTimeSeconds: waitTime,
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              active
                                  ? 'Patrol started: $pattern (${period}s sweep, ${waitTime}s wait)'
                                  : 'Patrol stopped',
                            ),
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        decoration: BoxDecoration(
                          color: active
                              ? primaryColor.withValues(alpha: 0.15)
                              : primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: primaryColor,
                            width: active ? 1.5 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              active
                                  ? Icons.pause_circle_outline
                                  : Icons.play_arrow,
                              size: 20,
                              color: active ? primaryColor : Colors.white,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              active ? 'Stop Patrol' : 'Start Patrol',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: active ? primaryColor : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      );
    },
  );
}

/// Builds a selectable patrol pattern option tile.
Widget _buildPatrolModeOption({
  required BuildContext context,
  required IconData icon,
  required String label,
  required bool isSelected,
  required VoidCallback onTap,
}) {
  final primaryColor = Theme.of(context).colorScheme.primary;

  return Expanded(
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? primaryColor.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? primaryColor : Colors.grey.shade300,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 22,
                color: isSelected ? primaryColor : Colors.grey.shade700,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? primaryColor : Colors.grey.shade700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
