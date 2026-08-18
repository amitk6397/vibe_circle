import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/app_avatar.dart';
import '../../../core/widgets/app_card.dart';
import '../models/person.dart';

class PersonCard extends StatelessWidget {
  final Person person;
  final VoidCallback? onPressed;

  const PersonCard({
    super.key,
    required this.person,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onPressed: onPressed,
      child: Row(
        children: [
          AppAvatar(
            name: person.name,
            avatarUrl: person.avatarUrl,
            size: 48.0,
            online: person.online,
          ),
          const SizedBox(width: 12.0),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${person.name}, ${person.age}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 15.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 6.0),
                    if (person.online)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: AppColors.success.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: const Text(
                          'ONLINE',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 8.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2.0),
                Text(
                  '@${person.username} ${person.city != null ? '• ${person.city}' : ''}',
                  style: const TextStyle(color: AppColors.muted, fontSize: 12.0),
                ),
                if (person.interests.isNotEmpty) ...[
                  const SizedBox(height: 6.0),
                  Wrap(
                    spacing: 4.0,
                    runSpacing: 4.0,
                    children: person.interests.take(3).map((interest) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          interest,
                          style: const TextStyle(color: AppColors.text, fontSize: 10.0),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: AppColors.muted, size: 20.0),
        ],
      ),
    );
  }
}
