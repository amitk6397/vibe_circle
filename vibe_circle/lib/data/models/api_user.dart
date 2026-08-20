class ApiUser {
  final String id;
  final String? email;
  final String name;
  final int age;
  final String? username;
  final String bio;
  final String city;
  final String? avatarUrl;
  final List<String> languages;
  final List<String> interests;
  final List<String>? conversationTopics;
  final String? dateOfBirth;
  final String? gender;
  final String? preferredLanguage;
  final double? performanceRating;
  final int? reviewCount;
  final int? completedSessions;
  final String? performanceTier; // 'top_performer' | 'recommended' | 'new'
  final List<String> purposes;
  final bool isOnline;
  final String? vibeStatus;
  final String? vibeExpiresAt;
  final Map<String, bool>? notificationPreferences;

  ApiUser({
    required this.id,
    this.email,
    required this.name,
    required this.age,
    this.username,
    required this.bio,
    required this.city,
    this.avatarUrl,
    required this.languages,
    required this.interests,
    this.conversationTopics,
    this.dateOfBirth,
    this.gender,
    this.preferredLanguage,
    this.performanceRating,
    this.reviewCount,
    this.completedSessions,
    this.performanceTier,
    required this.purposes,
    required this.isOnline,
    this.vibeStatus,
    this.vibeExpiresAt,
    this.notificationPreferences,
  });

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'].toString(),
      email: json['email'] as String?,
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 18,
      username: json['username'] as String?,
      bio: json['bio'] as String? ?? '',
      city: json['city'] as String? ?? '',
      avatarUrl: json['avatar_url'] as String?,
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      interests: (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      conversationTopics: (json['conversation_topics'] as List?)?.map((e) => e.toString()).toList(),
      dateOfBirth: json['date_of_birth'] as String?,
      gender: json['gender'] as String?,
      preferredLanguage: json['preferred_language'] as String?,
      performanceRating: (json['performance_rating'] as num?)?.toDouble(),
      reviewCount: json['review_count'] as int?,
      completedSessions: json['completed_sessions'] as int?,
      performanceTier: json['performance_tier'] as String?,
      purposes: (json['purposes'] as List?)?.map((e) => e.toString()).toList() ?? [],
      isOnline: json['is_online'] as bool? ?? false,
      vibeStatus: json['vibe_status'] as String?,
      vibeExpiresAt: json['vibe_expires_at'] as String?,
      notificationPreferences: json['notification_preferences'] != null
          ? Map<String, bool>.from(json['notification_preferences'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (email != null) 'email': email,
      'name': name,
      'age': age,
      'username': username,
      'bio': bio,
      'city': city,
      'avatar_url': avatarUrl,
      'languages': languages,
      'interests': interests,
      'conversation_topics': conversationTopics,
      'date_of_birth': dateOfBirth,
      'gender': gender,
      'preferred_language': preferredLanguage,
      'performance_rating': performanceRating,
      'review_count': reviewCount,
      'completed_sessions': completedSessions,
      'performance_tier': performanceTier,
      'purposes': purposes,
      'is_online': isOnline,
      'vibe_status': vibeStatus,
      'vibe_expires_at': vibeExpiresAt,
      'notification_preferences': notificationPreferences,
    };
  }
}
