enum RecordingStatus { pending, validated, rejected }

class Recording {
  final String id;
  final String userId;
  final String sentenceId;
  final String filepath;
  final String? originalFilename;
  final double? duration;
  final double? fileSize;
  final double? sampleRate;
  final RecordingStatus status;
  final double? qualityScore;
  final String? adminNotes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Recording({
    required this.id,
    required this.userId,
    required this.sentenceId,
    required this.filepath,
    this.originalFilename,
    this.duration,
    this.fileSize,
    this.sampleRate,
    required this.status,
    this.qualityScore,
    this.adminNotes,
    required this.createdAt,
    this.updatedAt,
  });

  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'].toString(),
      userId: json['user_id'].toString(),
      sentenceId: json['sentence_id'].toString(),
      filepath: json['filepath'],
      originalFilename: json['original_filename'],
      duration: json['duration']?.toDouble(),
      fileSize: json['file_size']?.toDouble(),
      sampleRate: json['sample_rate']?.toDouble(),
      status: _parseStatus(json['status']),
      qualityScore: json['quality_score']?.toDouble(),
      adminNotes: json['admin_notes'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  static RecordingStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'validated':
        return RecordingStatus.validated;
      case 'rejected':
        return RecordingStatus.rejected;
      default:
        return RecordingStatus.pending;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'sentence_id': sentenceId,
      'filepath': filepath,
      'original_filename': originalFilename,
      'duration': duration,
      'file_size': fileSize,
      'sample_rate': sampleRate,
      'status': status.name,
      'quality_score': qualityScore,
      'admin_notes': adminNotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
