import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AppAnimatedLoader extends StatefulWidget {
  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  const AppAnimatedLoader({
    super.key,
    this.height = 80.0,
    this.width,
    this.borderRadius = 16.0,
    this.margin = const EdgeInsets.only(bottom: 12.0),
  });

  @override
  State<AppAnimatedLoader> createState() => _AppAnimatedLoaderState();
}

class _AppAnimatedLoaderState extends State<AppAnimatedLoader> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);

    _opacityAnimation = Tween<double>(begin: 0.35, end: 0.85).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _opacityAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnimation.value,
          child: Container(
            height: widget.height,
            width: widget.width ?? double.infinity,
            margin: widget.margin,
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(widget.borderRadius),
            ),
          ),
        );
      },
    );
  }
}
