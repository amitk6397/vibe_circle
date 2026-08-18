import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../models/person.dart';

class PersonGridCard extends StatelessWidget {
  final Person person;
  final VoidCallback? onPressed;

  const PersonGridCard({
    super.key,
    required this.person,
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
            name: person.name,
            avatarUrl: person.avatarUrl,
            size: 56.0,
            online: person.online,
          ),
          const SizedBox(height: 10.0),
          Text(
            '${person.name}, ${person.age}',
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14.0,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2.0),
          Text(
            person.city ?? '@${person.username}',
            style: const TextStyle(color: AppColors.muted, fontSize: 11.0),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.monetization_on_outlined, size: 12.0, color: AppColors.primary),
                const SizedBox(width: 4.0),
                Text(
                  '${person.coinRate} coins/min',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
