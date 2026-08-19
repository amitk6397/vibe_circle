import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

class AppScreen extends StatelessWidget {
  final Widget? header;
  final Widget child;
  final bool scroll;
  final bool noPadding;
  final EdgeInsetsGeometry? padding;
  final Color backgroundColor;

  const AppScreen({
    super.key,
    this.header,
    required this.child,
    this.scroll = true,
    this.noPadding = false,
    this.padding,
    this.backgroundColor = AppColors.bg,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (scroll) {
      content = SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Padding(
          padding: padding ?? (noPadding ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0)),
          child: child,
        ),
      );
    } else {
      if (!noPadding) {
        content = Padding(
          padding: padding ?? const EdgeInsets.symmetric(horizontal: 12.0, vertical: 16.0),
          child: child,
        );
      }
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ?header,
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
