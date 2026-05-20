class User {
  final String id;
  final String username;
  final String gender;
  final String ageRange;
  final bool isAdmin;
  final String role;
  final bool isActive;
  final bool consentGiven;
  final DateTime createdAt;
  final DateTime? updatedAt;

  User({
    required this.id,
    required this.username,
    required this.gender,
    required this.ageRange,
    required this.isAdmin,
    required this.role,
    required this.isActive,
    required this.consentGiven,
    required this.createdAt,
    this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'].toString(),
      username: json['username'],
      gender: json['gender'],
      ageRange: json['age_range'],
      isAdmin: json['is_admin'] ?? false,
      role: json['role'] ?? 'user',
      isActive: json['is_active'] ?? true,
      consentGiven: json['consent_given'] ?? false,
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
      'username': username,
      'gender': gender,
      'age_range': ageRange,
      'is_admin': isAdmin,
      'role': role,
      'is_active': isActive,
      'consent_given': consentGiven,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class UserStats {
  final int totalRecordings;
  final int validatedRecordings;
  final int rejectedRecordings;
  final int pendingRecordings;
  final double totalDuration;

  UserStats({
    required this.totalRecordings,
    required this.validatedRecordings,
    required this.rejectedRecordings,
    required this.pendingRecordings,
    required this.totalDuration,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalRecordings: json['total_recordings'] ?? 0,
      validatedRecordings: json['validated_recordings'] ?? 0,
      rejectedRecordings: json['rejected_recordings'] ?? 0,
      pendingRecordings: json['pending_recordings'] ?? 0,
      totalDuration: (json['total_duration'] ?? 0).toDouble(),
    );
  }
}
