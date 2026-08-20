class UserReview {
  final String id;
  final String reviewerId;
  final String reviewerName;
  final String? reviewerAvatarUrl;
  final int overallRating;
  final String review;
  final String createdAt;

  UserReview({
    required this.id,
    this.reviewerId = '',
    this.reviewerName = 'User',
    this.reviewerAvatarUrl,
    this.overallRating = 5,
    this.review = '',
    this.createdAt = '',
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    return UserReview(
      id: json['id']?.toString() ?? '',
      reviewerId: json['reviewer_id']?.toString() ?? json['reviewerId']?.toString() ?? '',
      reviewerName: json['reviewer_name']?.toString() ?? json['reviewerName']?.toString() ?? 'User',
      reviewerAvatarUrl: json['reviewer_avatar_url']?.toString() ?? json['reviewerAvatarUrl']?.toString(),
      overallRating: (json['overall_rating'] as num?)?.toInt() ??
          (json['overallRating'] as num?)?.toInt() ??
          (json['rating'] as num?)?.toInt() ??
          5,
      review: json['review']?.toString() ?? json['comment']?.toString() ?? 'Great session!',
      createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'reviewer_id': reviewerId,
      'reviewer_name': reviewerName,
      'reviewer_avatar_url': reviewerAvatarUrl,
      'overall_rating': overallRating,
      'review': review,
      'created_at': createdAt,
    };
  }
}
