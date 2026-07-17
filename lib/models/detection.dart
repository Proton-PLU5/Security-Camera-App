
class Detection {
  final String className;
  final double confidence;
  final double x, y, width, height; // normalized [0,1]

  Detection({
    required this.className,
    required this.confidence,
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  factory Detection.fromJson(Map<String, dynamic> json) {
    const frameWidth = 960.0;
    const frameHeight = 544.0;
    return Detection(
      className: json['class_name'] as String,
      confidence: (json['confidence'] as num).toDouble(),
      x: ((json['bbox_x'] as num).toDouble() - (json['bbox_width'] as num).toDouble() / 2) / frameWidth,
      y: ((json['bbox_y'] as num).toDouble() - (json['bbox_height'] as num).toDouble() / 2) / frameHeight,
      width: (json['bbox_width'] as num).toDouble() / frameWidth,
      height: (json['bbox_height'] as num).toDouble() / frameHeight,
    );
  }
}
