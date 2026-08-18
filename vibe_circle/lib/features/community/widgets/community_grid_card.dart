import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../models/community.dart';

class CommunityGridCard extends StatelessWidget {
  final Community community;
  final VoidCallback? onPressed;

  const CommunityGridCard({
    super.key,
    required this.community,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onPressed: onPressed,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppAvatar(
            name: community.name,
            avatarUrl: community.avatarUrl,
            size: 52.0,
          ),
          const SizedBox(height: 10.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  community.name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13.5,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (community.isPrivate) ...[
                const SizedBox(width: 4.0),
                const Icon(Icons.lock, size: 12.0, color: AppColors.muted),
              ],
            ],
          ),
          const SizedBox(height: 2.0),
          Text(
            '${community.memberCount} members',
            style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
          ),
        ],
      ),
    );
  }
}
