class CreatorProfile {
  final String id;
  final String name;
  final String? avatarUrl;
  final bool verified;
  final String category;
  final String availabilityStatus;
  final String bio;
  final double performanceRating;
  final int completedSessions;
  final int responseRate;
  final List<String> topics;
  final int chatPrice;
  final int audioPricePerMinute;
  final int videoPricePerMinute;

  CreatorProfile({
    this.id = '',
    this.name = 'Creator',
    this.avatarUrl,
    this.verified = false,
    this.category = 'Creator',
    this.availabilityStatus = 'Available',
    this.bio = '',
    this.performanceRating = 5.0,
    this.completedSessions = 0,
    this.responseRate = 100,
    this.topics = const [],
    this.chatPrice = 2,
    this.audioPricePerMinute = 5,
    this.videoPricePerMinute = 10,
  });

  factory CreatorProfile.fromJson(Map<String, dynamic> json) {
    return CreatorProfile(
      id: json['id']?.toString() ?? json['user_id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'Creator',
      avatarUrl: json['avatar_url']?.toString() ?? json['avatarUrl']?.toString(),
      verified: json['verified'] == true,
      category: json['category']?.toString() ?? 'Host & Creator',
      availabilityStatus: json['availability_status']?.toString() ??
          json['availabilityStatus']?.toString() ??
          'Available',
      bio: json['bio']?.toString() ?? '',
      performanceRating: (json['performance_rating'] as num?)?.toDouble() ??
          (json['performanceRating'] as num?)?.toDouble() ??
          (json['rating'] as num?)?.toDouble() ??
          5.0,
      completedSessions: (json['completed_sessions'] as num?)?.toInt() ??
          (json['completedSessions'] as num?)?.toInt() ??
          (json['totalCompletedSessions'] as num?)?.toInt() ??
          0,
      responseRate: (json['response_rate'] as num?)?.toInt() ??
          (json['responseRate'] as num?)?.toInt() ??
          100,
      topics: (json['topics'] as List?)?.map((e) => e.toString()).toList() ?? [],
      chatPrice: (json['chat_price'] as num?)?.toInt() ??
          (json['chatPrice'] as num?)?.toInt() ??
          2,
      audioPricePerMinute: (json['audio_price_per_minute'] as num?)?.toInt() ??
          (json['audioPricePerMinute'] as num?)?.toInt() ??
          5,
      videoPricePerMinute: (json['video_price_per_minute'] as num?)?.toInt() ??
          (json['videoPricePerMinute'] as num?)?.toInt() ??
          10,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'avatar_url': avatarUrl,
      'verified': verified,
      'category': category,
      'availability_status': availabilityStatus,
      'bio': bio,
      'performance_rating': performanceRating,
      'completed_sessions': completedSessions,
      'response_rate': responseRate,
      'topics': topics,
      'chat_price': chatPrice,
      'audio_price_per_minute': audioPricePerMinute,
      'video_price_per_minute': videoPricePerMinute,
    };
  }
}
