class Person {
  final String id;
  final String name;
  final int age;
  final String username;
  final String? bio;
  final String? city;
  final String? avatarUrl;
  final List<String> interests;
  final List<String> languages;
  final bool online;
  final String avatarColor;
  final int coinRate;
  final List<String> conversationTopics;
  final double performanceRating;
  final int reviewCount;
  final int completedSessions;
  final String performanceTier;

  Person({
    required this.id,
    required this.name,
    required this.age,
    required this.username,
    this.bio,
    this.city,
    this.avatarUrl,
    required this.interests,
    required this.languages,
    required this.online,
    required this.avatarColor,
    this.coinRate = 2,
    this.conversationTopics = const [],
    this.performanceRating = 0.0,
    this.reviewCount = 0,
    this.completedSessions = 0,
    this.performanceTier = 'new',
  });

  factory Person.fromJson(Map<String, dynamic> json) {
    return Person(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      age: json['age'] is int ? json['age'] : (int.tryParse(json['age']?.toString() ?? '18') ?? 18),
      username: json['username'] ?? '',
      bio: json['bio'],
      city: json['city'],
      avatarUrl: json['avatar_url'],
      interests: (json['interests'] as List?)?.map((e) => e.toString()).toList() ?? [],
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? [],
      online: json['online'] ?? false,
      avatarColor: json['avatar_color'] ?? '#5B5CE2',
      coinRate: json['coin_rate'] ?? 2,
      conversationTopics: (json['conversation_topics'] as List?)?.map((e) => e.toString()).toList() ??
          (json['conversationTopics'] as List?)?.map((e) => e.toString()).toList() ??
          [],
      performanceRating: (json['performance_rating'] ?? json['performanceRating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? json['reviewCount'] ?? 0,
      completedSessions: json['completed_sessions'] ?? json['completedSessions'] ?? 0,
      performanceTier: json['performance_tier'] ?? json['performanceTier'] ?? 'new',
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
      'avatar_url': avatarUrl,
      'interests': interests,
      'languages': languages,
      'online': online,
      'avatar_color': avatarColor,
      'coin_rate': coinRate,
      'conversation_topics': conversationTopics,
      'performance_rating': performanceRating,
      'review_count': reviewCount,
      'completed_sessions': completedSessions,
      'performance_tier': performanceTier,
    };
  }
}

