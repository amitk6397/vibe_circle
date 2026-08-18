class Person {
  final String id;
  final String name;
  final int age;
  final String username;
  final String bio;
  final String? city;
  final List<String> languages;
  final List<String> interests;
  final bool online;
  final bool? trusted;
  final String avatarColor;
  final String? avatarUrl;
  final List<String>? conversationTopics;
  final List<String>? recommendationReasons;
  final double? performanceRating;
  final int? reviewCount;
  final int? completedSessions;
  final String? performanceTier; // 'top_performer' | 'recommended' | 'new'
  final double? responseRate;

  Person({
    required this.id,
    required this.name,
    required this.age,
    required this.username,
    required this.bio,
    this.city,
    required this.languages,
    required this.interests,
    required this.online,
    this.trusted,
    required this.avatarColor,
    this.avatarUrl,
    this.conversationTopics,
    this.recommendationReasons,
    this.performanceRating,
    this.reviewCount,
    this.completedSessions,
    this.performanceTier,
    this.responseRate,
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'].toString(),
      name: json['name'] as String? ?? '',
      age: json['age'] as int? ?? 18,
      username: json['username'] as String? ?? '',
      bio: json['bio'] as String? ?? '',
      city: json['city'] as String?,
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      interests: (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      online: json['online'] as bool? ?? false,
      trusted: json['trusted'] as bool?,
      avatarColor: json['avatarColor'] as String? ?? '#5B5CE2',
      avatarUrl: json['avatarUrl'] as String?,
      conversationTopics: (json['conversationTopics'] as List?)?.map((e) => e.toString()).toList(),
      recommendationReasons: (json['recommendationReasons'] as List?)?.map((e) => e.toString()).toList(),
      performanceRating: (json['performanceRating'] as num?)?.toDouble(),
      reviewCount: json['reviewCount'] as int?,
      completedSessions: json['completedSessions'] as int?,
      performanceTier: json['performanceTier'] as String?,
      responseRate: (json['responseRate'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'username': username,
      'bio': bio,
      'city': city,
      'languages': languages,
      'interests': interests,
      'online': online,
      'trusted': trusted,
      'avatarColor': avatarColor,
      'avatarUrl': avatarUrl,
      'conversationTopics': conversationTopics,
      'recommendationReasons': recommendationReasons,
      'performanceRating': performanceRating,
      'reviewCount': reviewCount,
      'completedSessions': completedSessions,
      'performanceTier': performanceTier,
      'responseRate': responseRate,
    };
  }
}
