import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../models/post.dart';

class PostCard extends StatelessWidget {
  final Post post;
  final VoidCallback? onPressed;
  final VoidCallback? onLikePressed;
  final VoidCallback? onCommentPressed;

  const PostCard({
    super.key,
    required this.post,
    this.onPressed,
    this.onLikePressed,
    this.onCommentPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onPressed: onPressed,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AppAvatar(
                name: post.authorName,
                avatarUrl: post.authorAvatar,
                size: 38.0,
              ),
              const SizedBox(width: 10.0),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      post.authorName,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 1.0),
                    const Text(
                      'Recent',
                      style: TextStyle(color: AppColors.muted, fontSize: 10.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10.0),
          Text(
            post.content,
            style: const TextStyle(color: AppColors.text, fontSize: 13.5, height: 1.35),
          ),
          if (post.mediaUrls.isNotEmpty) ...[
            const SizedBox(height: 10.0),
            ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: Image.network(
                post.mediaUrls.first,
                height: 180.0,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 140.0,
                  color: AppColors.surfaceAlt,
                  alignment: Alignment.center,
                  child: const Icon(Icons.image_not_supported, color: AppColors.muted),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12.0),
          Row(
            children: [
              InkWell(
                onTap: onLikePressed,
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      Icon(
                        post.isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 18.0,
                        color: post.isLiked ? AppColors.danger : AppColors.muted,
                      ),
                      const SizedBox(width: 4.0),
                      Text(
                        '${post.likesCount}',
                        style: TextStyle(
                          color: post.isLiked ? AppColors.danger : AppColors.muted,
                          fontSize: 12.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16.0),
              InkWell(
                onTap: onCommentPressed,
                borderRadius: BorderRadius.circular(8.0),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  child: Row(
                    children: [
                      const Icon(Icons.chat_bubble_outline, size: 17.0, color: AppColors.muted),
                      const SizedBox(width: 4.0),
                      Text(
                        '${post.commentsCount}',
                        style: const TextStyle(color: AppColors.muted, fontSize: 12.0, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
