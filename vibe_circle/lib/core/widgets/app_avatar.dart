import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../utils/helpers.dart';

class AppAvatar extends StatelessWidget {
  final String name;
  final String? uri;
  final String? avatarUrl;
  final double size;
  final Color? color;
  final bool online;

  const AppAvatar({
    super.key,
    required this.name,
    this.uri,
    this.avatarUrl,
    this.size = 48.0,
    this.color,
    this.online = false,
  });

  @override
  Widget build(BuildContext context) {
    final String? absoluteUri = Helpers.resolveImageUrl(uri ?? avatarUrl);
    final initials = Helpers.getInitials(name);
    final avatarColor = color ?? AppColors.primary;

    return Stack(
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: avatarColor,
          ),
          clipBehavior: Clip.antiAlias,
          child: absoluteUri != null
              ? Image.network(
                  absoluteUri,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size * 0.35,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
              : Center(
                  child: Text(
                    initials,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: size * 0.35,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 1,
            child: Container(
              width: size * 0.27 > 13.0 ? 13.0 : size * 0.27,
              height: size * 0.27 > 13.0 ? 13.0 : size * 0.27,
              decoration: BoxDecoration(
                color: AppColors.success,
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white, // Matches white outline from style
                  width: 1.5,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
