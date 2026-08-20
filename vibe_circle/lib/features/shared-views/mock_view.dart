import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/widgets/app_screen.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/app_empty_state.dart';

class MockView extends StatelessWidget {
  final String title;

  const MockView({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return AppScreen(
      header: AppHeader(
        title: title,
        onBack: () => Get.back(),
      ),
      scroll: false,
      child: AppEmptyState(
        icon: Icons.construction,
        title: 'Screen Under Migration',
        text: 'The $title screen is currently being migrated from React Native to Flutter.',
      ),
    );
  }
}
