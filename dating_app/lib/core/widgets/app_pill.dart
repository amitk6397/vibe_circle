import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../constants/app_colors.dart';

class AppPill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  final Color? color;

  const AppPill({
    super.key,
    required this.label,
    this.selected = false,
    this.onPressed,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? AppColors.primary;
    final bg = selected ? activeColor : AppColors.surface;
    final border = selected ? activeColor : AppColors.border;
    final textCol = selected ? Colors.white : AppColors.muted;

    Widget pill = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99.0),
        border: Border.all(
          color: border,
          width: 1.0,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textCol,
          fontSize: 11.0,
          fontWeight: FontWeight.w700,
        ),
      ),
    );

    if (onPressed != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed!();
        },
        child: pill,
      );
    }
    return pill;
  }
}
