import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class ChatSkeleton extends StatefulWidget {
  final int rows;

  const ChatSkeleton({super.key, this.rows = 5});

  @override
  State<ChatSkeleton> createState() => _ChatSkeletonState();
}

class _ChatSkeletonState extends State<ChatSkeleton> with SingleTickerProviderStateMixin {
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: List.generate(widget.rows, (index) {
              final bool isRight = index % 2 != 0;
              final double widthFraction = index % 3 == 0 ? 0.62 : 0.76;

              return Align(
                alignment: isRight ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: MediaQuery.of(context).size.width * widthFraction,
                  margin: const EdgeInsets.only(bottom: 14.0),
                  padding: const EdgeInsets.all(14.0),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(17.0),
                      topRight: const Radius.circular(17.0),
                      bottomLeft: Radius.circular(isRight ? 17.0 : 5.0),
                      bottomRight: Radius.circular(isRight ? 5.0 : 17.0),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 10.0,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(5.0),
                        ),
                      ),
                      const SizedBox(height: 8.0),
                      FractionallySizedBox(
                        widthFactor: 0.42,
                        child: Container(
                          height: 8.0,
                          decoration: BoxDecoration(
                            color: AppColors.border,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        );
      },
    );
  }
}
