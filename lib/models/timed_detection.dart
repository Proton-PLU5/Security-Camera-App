import 'package:camera_application/models/detection.dart';

class TimedDetection extends Detection {
  final double offsetSeconds;

  TimedDetection({
    required this.offsetSeconds,
    required super.className,
    required super.confidence,
    required super.x,
    required super.y,
    required super.width,
    required super.height,
  });

  /// Factory that respects your center-to-corner math, 
  /// utilizing the dynamic lowres_size from the backend.
  factory TimedDetection.fromClipJson(Map<String, dynamic> json, double frameWidth, double frameHeight) {
    final double bboxX = (json['bbox_x'] as num).toDouble();
    final double bboxY = (json['bbox_y'] as num).toDouble();
    final double bboxW = (json['bbox_width'] as num).toDouble();
    final double bboxH = (json['bbox_height'] as num).toDouble();

    return TimedDetection(
      offsetSeconds: (json['offset_seconds'] as num).toDouble(),
      className: json['class_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      
      x: (bboxX - bboxW / 2) / frameWidth,
      y: (bboxY - bboxH / 2) / frameHeight,
      width: bboxW / frameWidth,
      height: bboxH / frameHeight,
    );
  }
}