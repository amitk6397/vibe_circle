import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static const TextStyle title = TextStyle(
    color: AppColors.text,
    fontSize: 30,
    fontWeight: FontWeight.w900,
    height: 36 / 30,
  );

  static const TextStyle h2 = TextStyle(
    color: AppColors.text,
    fontSize: 21,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle headerTitle = TextStyle(
    color: AppColors.text,
    fontSize: 24,
    fontWeight: FontWeight.w900,
  );

  static const TextStyle body = TextStyle(
    color: AppColors.text,
    fontSize: 15,
    height: 22 / 15,
  );

  static const TextStyle muted = TextStyle(
    color: AppColors.muted,
    fontSize: 13,
    height: 19 / 13,
  );

  static const TextStyle label = TextStyle(
    color: AppColors.text,
    fontSize: 14,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle buttonText = TextStyle(
    color: Colors.white,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle altButtonText = TextStyle(
    color: AppColors.primary,
    fontSize: 15,
    fontWeight: FontWeight.w800,
  );

  static const TextStyle caption = TextStyle(
    color: AppColors.muted,
    fontSize: 12,
    height: 17 / 12,
  );

  static const TextStyle error = TextStyle(
    color: AppColors.danger,
    fontSize: 13,
    fontWeight: FontWeight.w500,
  );

  // Aliases for broader compatibility
  static const TextStyle subtitle = TextStyle(
    color: AppColors.text,
    fontSize: 16,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle h3 = TextStyle(
    color: AppColors.text,
    fontSize: 17,
    fontWeight: FontWeight.bold,
  );
  static const TextStyle titleMedium = h2;
  static const TextStyle titleSmall = label;
  static const TextStyle titleLarge = title;
  static const TextStyle bodySmall = caption;
  static const TextStyle button = buttonText;
}
