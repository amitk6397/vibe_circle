import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color backgroundColor;
  final Color borderColor;
  final double borderWidth;

  const AppCard({
    super.key,
    required this.child,
    this.onPressed,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.backgroundColor = const Color(0xFF181C30), // Dark card bg color
    this.borderColor = const Color(0xFF2B304A),     // Dark card border color
    this.borderWidth = 1.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget card = Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (onPressed != null) {
      return GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          onPressed!();
        },
        child: card,
      );
    }
    return card;
  }
}
