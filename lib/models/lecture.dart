class Lecture {
  final String id;
  final String title;
  final String filePath;
  final DateTime createdAt;
  final int durationSeconds;
  final String? transcript;
  String? notes;

  Lecture({
    required this.id,
    required this.title,
    required this.filePath,
    required this.createdAt,
    required this.durationSeconds,
    this.transcript,
    this.notes,
  });
}
