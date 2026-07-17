import 'package:flutter/material.dart';
import 'package:camera_application/models/detection.dart';

class DetectionOverlayPainter extends CustomPainter {
  final List<Detection> detections;

  DetectionOverlayPainter(this.detections);

  @override
  void paint(Canvas canvas, Size size) {
    final boxPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (final d in detections) {
      final rect = Rect.fromLTWH(
        d.x * size.width,
        d.y * size.height,
        d.width * size.width,
        d.height * size.height,
      );
      canvas.drawRect(rect, boxPaint);

      textPainter.text = TextSpan(
        text: '${d.className} ${(d.confidence * 100).toStringAsFixed(0)}%',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          backgroundColor: Colors.red,
        ),
      );
      textPainter.layout();
      textPainter.paint(canvas, rect.topLeft + const Offset(2, 2));
    }
  }

  @override
  bool shouldRepaint(covariant DetectionOverlayPainter oldDelegate) =>
      oldDelegate.detections != detections;
}