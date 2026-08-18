class ApiUser {
  final String id;
  final String name;
  final int age;
  final String email;
  final String? username;
  final String? bio;
  final String? city;
  final String? gender;
  final String? avatarUrl;
  final List<String> languages;
  final List<String> interests;
  final bool emailVerified;
  final bool isOnline;
  final List<String> conversationTopics;
  final double performanceRating;
  final int reviewCount;
  final int completedSessions;
  final String performanceTier;

  final String? dateOfBirth;

  ApiUser({
    required this.id,
    required this.name,
    required this.age,
    required this.email,
    this.username,
    this.bio,
    this.city,
    this.gender,
    this.avatarUrl,
    this.languages = const [],
    this.interests = const [],
    this.emailVerified = false,
    this.isOnline = false,
    this.conversationTopics = const [],
    this.performanceRating = 0.0,
    this.reviewCount = 0,
    this.completedSessions = 0,
    this.performanceTier = 'new',
    this.dateOfBirth,
  });

  ApiUser copyWith({
    String? id,
    String? name,
    int? age,
    String? email,
    String? username,
    String? bio,
    String? city,
    String? gender,
    String? avatarUrl,
    List<String>? languages,
    List<String>? interests,
    bool? emailVerified,
    bool? isOnline,
    List<String>? conversationTopics,
    double? performanceRating,
    int? reviewCount,
    int? completedSessions,
    String? performanceTier,
    String? dateOfBirth,
  }) {
    return ApiUser(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      email: email ?? this.email,
      username: username ?? this.username,
      bio: bio ?? this.bio,
      city: city ?? this.city,
      gender: gender ?? this.gender,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      languages: languages ?? this.languages,
      interests: interests ?? this.interests,
      emailVerified: emailVerified ?? this.emailVerified,
      isOnline: isOnline ?? this.isOnline,
      conversationTopics: conversationTopics ?? this.conversationTopics,
      performanceRating: performanceRating ?? this.performanceRating,
      reviewCount: reviewCount ?? this.reviewCount,
      completedSessions: completedSessions ?? this.completedSessions,
      performanceTier: performanceTier ?? this.performanceTier,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
    );
  }

  factory ApiUser.fromJson(Map<String, dynamic> json) {
    return ApiUser(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      age: json['age'] is int ? json['age'] : (int.tryParse(json['age']?.toString() ?? '18') ?? 18),
      email: json['email'] ?? '',
      username: json['username'],
      bio: json['bio'],
      city: json['city'],
      gender: json['gender'],
      avatarUrl: json['avatar_url'],
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      interests: (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      emailVerified: json['email_verified'] ?? false,
      isOnline: json['is_online'] ?? json['online'] ?? false,
      conversationTopics: (json['conversation_topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      performanceRating: (json['performance_rating'] ?? json['performanceRating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? json['reviewCount'] ?? 0,
      completedSessions: json['completed_sessions'] ?? json['completedSessions'] ?? 0,
      performanceTier: json['performance_tier'] ?? json['performanceTier'] ?? 'new',
      dateOfBirth: json['date_of_birth'] ?? json['dateOfBirth'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'email': email,
      'username': username,
      'bio': bio,
      'city': city,
      'gender': gender,
      'avatar_url': avatarUrl,
      'languages': languages,
      'interests': interests,
      'email_verified': emailVerified,
      'is_online': isOnline,
      'conversation_topics': conversationTopics,
      'performance_rating': performanceRating,
      'review_count': reviewCount,
      'completed_sessions': completedSessions,
      'performance_tier': performanceTier,
      'date_of_birth': dateOfBirth,
    };
  }
}

