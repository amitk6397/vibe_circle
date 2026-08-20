import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
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
    final hasPhoto = person.avatarUrl != null && person.avatarUrl!.isNotEmpty;
    final photoUrl = hasPhoto ? (Helpers.resolveImageUrl(person.avatarUrl!) ?? '') : '';
    final bgColor = person.avatarColor;

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(18.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Full-card background — photo or gradient
            Positioned.fill(
              child: hasPhoto && photoUrl.isNotEmpty
                  ? Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _buildGradientBg(bgColor),
                    )
                  : _buildGradientBg(bgColor),
            ),

            // Initial letter (only when no photo)
            if (!hasPhoto || photoUrl.isEmpty)
              Positioned.fill(
                child: Center(
                  child: Text(
                    person.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontSize: 48.0,
                      fontWeight: FontWeight.w900,
                      color: Colors.white70,
                    ),
                  ),
                ),
              ),

            // Online indicator dot
            if (person.online == true)
              Positioned(
                top: 10.0,
                right: 10.0,
                child: Container(
                  width: 14.0,
                  height: 14.0,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.surface, width: 2.0),
                  ),
                  alignment: Alignment.center,
                  child: Container(
                    width: 9.0,
                    height: 9.0,
                    decoration: const BoxDecoration(
                      color: Color(0xFF22C55E),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

            // Bottom gradient info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name + age
                    Text(
                      '${person.name}${person.age > 0 ? ', ${person.age}' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w800,
                        shadows: [
                          Shadow(blurRadius: 4.0, color: Colors.black54),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    // City
                    if (person.city != null && person.city!.isNotEmpty) ...[
                      const SizedBox(height: 2.0),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 11.0,
                            color: Colors.white70,
                          ),
                          const SizedBox(width: 2.0),
                          Expanded(
                            child: Text(
                              person.city!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11.0,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],

                    // Interest tags (max 2)
                    if (person.interests.isNotEmpty) ...[
                      const SizedBox(height: 4.0),
                      Wrap(
                        spacing: 4.0,
                        runSpacing: 3.0,
                        children: person.interests.take(2).map((tag) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 7.0,
                              vertical: 2.0,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10.0,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBg(String? colorHex) {
    Color color;
    try {
      color = Color(
        int.parse((colorHex ?? '#5B5CE2').replaceFirst('#', '0xFF')),
      );
    } catch (_) {
      color = const Color(0xFF5B5CE2);
    }
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withValues(alpha: 0.65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }
}
