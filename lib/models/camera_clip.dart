class CameraClip {
  final String id;
  final DateTime startedAt;
  final DateTime? endedAt;
  final String filePath;
  final String trigger;

  CameraClip({
    required this.id,
    required this.startedAt,
    this.endedAt,
    required this.filePath,
    required this.trigger,
  });

  /// Maps the standard raw SQL tuple: [id, started_at, ended_at, file_path, trigger]
  factory CameraClip.fromJson(Map<String, dynamic> json) {
    return CameraClip(
      id: json['id'] as String,
      startedAt: DateTime.fromMillisecondsSinceEpoch((json['started_at'] as num).toInt()),
      endedAt: json['ended_at'] != null 
          ? DateTime.fromMillisecondsSinceEpoch((json['ended_at'] as num).toInt()) 
          : null,
      filePath: json['file_path'] as String,
      trigger: json['trigger'] as String,
    );
  }

  // Helper to extract just the filename from a full path
  String get fileName => filePath.split('/').last;

  // Helper to calculate the clip duration
  Duration get duration {
    if (endedAt == null) return Duration.zero;
    return endedAt!.difference(startedAt);
  }

  // Format duration to readable string (e.g., 01:15)
  String get formattedDuration {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return "$minutes:$seconds";
  }
}