class Sentence {
  final String id;
  final String text;
  final String status;
  final String language;
  final String difficultyLevel;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Sentence({
    required this.id,
    required this.text,
    required this.status,
    required this.language,
    required this.difficultyLevel,
    required this.createdAt,
    this.updatedAt,
  });

  factory Sentence.fromJson(Map<String, dynamic> json) {
    return Sentence(
      id: json['id'].toString(),
      text: json['text'],
      status: json['status'],
      language: json['language'] ?? 'wo',
      difficultyLevel: json['difficulty_level'] ?? 'easy',
      createdAt: DateTime.parse(json['created_at']),
      updatedAt:
          json['updated_at'] != null
              ? DateTime.parse(json['updated_at'])
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'status': status,
      'language': language,
      'difficulty_level': difficultyLevel,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}
