import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../models/community.dart';

class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onPressed;
  final VoidCallback? onPress;

  const CommunityCard({
    super.key,
    required this.community,
    this.onPressed,
    this.onPress,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onPressed: onPress ?? onPressed,
      child: Row(
        children: [
          AppAvatar(
            name: community.name,
            avatarUrl: community.avatarUrl,
            size: 48.0,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        community.name,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (community.isPrivate)
                      const Icon(Icons.lock, size: 14.0, color: AppColors.muted),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  '${community.memberCount} members • ${community.category}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.0),
                ),
                if (community.description.isNotEmpty) ...[
                  const SizedBox(height: 4.0),
                  Text(
                    community.description,
                    style: const TextStyle(color: AppColors.text, fontSize: 11.5),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8.0),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20.0),
        ],
      ),
    );
  }
}
