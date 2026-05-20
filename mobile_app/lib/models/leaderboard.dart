class LeaderboardEntry {
  final int rank;
  final String userId;
  final String username;
  final int validatedRecordings;
  final double totalDuration;
  final bool isCurrentUser;

  LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.username,
    required this.validatedRecordings,
    required this.totalDuration,
    this.isCurrentUser = false,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      rank: json['rank'] ?? 0,
      userId: json['user_id'].toString(),
      username: json['username'] ?? '',
      validatedRecordings: json['validated_recordings'] ?? 0,
      totalDuration: (json['total_duration'] ?? 0.0).toDouble(),
      isCurrentUser: json['is_current_user'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'rank': rank,
      'user_id': userId,
      'username': username,
      'validated_recordings': validatedRecordings,
      'total_duration': totalDuration,
      'is_current_user': isCurrentUser,
    };
  }
}

class LeaderboardResponse {
  final List<LeaderboardEntry> entries;
  final int? currentUserRank;
  final int totalUsers;

  LeaderboardResponse({
    required this.entries,
    this.currentUserRank,
    required this.totalUsers,
  });

  factory LeaderboardResponse.fromJson(Map<String, dynamic> json) {
    return LeaderboardResponse(
      entries:
          (json['entries'] as List<dynamic>?)
              ?.map((e) => LeaderboardEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentUserRank: json['current_user_rank'],
      totalUsers: json['total_users'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'entries': entries.map((e) => e.toJson()).toList(),
      'current_user_rank': currentUserRank,
      'total_users': totalUsers,
    };
  }
}
