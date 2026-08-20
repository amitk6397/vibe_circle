import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/utils/helpers.dart';
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
    // Use coverUrl first, then avatarUrl as fallback
    final imageUrl = community.coverUrl ?? community.avatarUrl ?? '';
    final hasCover = imageUrl.isNotEmpty;
    final coverUrl = hasCover
        ? (Helpers.resolveImageUrl(imageUrl) ?? '')
        : '';

    return GestureDetector(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surfaceAlt,
          borderRadius: BorderRadius.circular(18.0),
          border: Border.all(color: AppColors.border, width: 1.0),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Full-bleed background — cover image or gradient
            Positioned.fill(
              child: hasCover && coverUrl.isNotEmpty
                  ? Image.network(
                      coverUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => _buildGradientBg(),
                    )
                  : _buildGradientBg(),
            ),

            // Bottom gradient overlay
            Positioned.fill(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.35, 1.0],
                  ),
                ),
              ),
            ),

            // Joined badge (top-right)
            if (community.joined == true || community.isOwner == true)
              Positioned(
                top: 8.0,
                right: 8.0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Text(
                    community.isOwner == true ? 'Owner' : 'Joined',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9.0,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),

            // Private lock badge (top-left)
            if (community.isPrivate)
              Positioned(
                top: 8.0,
                left: 8.0,
                child: Container(
                  padding: const EdgeInsets.all(4.0),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: const Icon(Icons.lock, size: 11.0, color: Colors.white),
                ),
              ),

            // Bottom info overlay
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Category pill
                    if (community.category.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 4.0),
                        padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 2.0),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(6.0),
                        ),
                        child: Text(
                          community.category,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),

                    // Name
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            community.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              shadows: [
                                Shadow(
                                  blurRadius: 6.0,
                                  color: Colors.black54,
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                    // Member count
                    const SizedBox(height: 2.0),
                    Row(
                      children: [
                        const Icon(Icons.people_outline, size: 11.0, color: Colors.white70),
                        const SizedBox(width: 3.0),
                        Text(
                          '${community.memberCount} members',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 10.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGradientBg() {
    // Generate a color from the community name
    final int hash = community.name.codeUnits.fold(0, (prev, e) => prev + e);
    final gradients = [
      [const Color(0xFF5B5CE2), const Color(0xFF9B5CE2)],
      [const Color(0xFFE2455B), const Color(0xFFE2845B)],
      [const Color(0xFF22C55E), const Color(0xFF0EA5E9)],
      [const Color(0xFFD63384), const Color(0xFF7C3AED)],
      [const Color(0xFFF59E0B), const Color(0xFFEF4444)],
    ];
    final pair = gradients[hash % gradients.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: pair,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        community.name[0].toUpperCase(),
        style: const TextStyle(
          fontSize: 44.0,
          fontWeight: FontWeight.w900,
          color: Colors.white70,
        ),
      ),
    );
  }
}
