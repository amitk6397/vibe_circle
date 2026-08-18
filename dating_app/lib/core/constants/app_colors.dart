import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  static const Color bg = Color(0xFF242837);
  static const Color surface = Color(0xFF2E3347);
  static const Color surfaceAlt = Color(0xFF38405A);
  static const Color primary = Color(0xFFFF2D75);
  static const Color primaryDark = Color(0xFF8B5CF6);
  static const Color accent = Color(0xFFFF7A00);
  static const Color text = Color(0xFFEEF2FF);
  static const Color muted = Color(0xFF8892A4);
  static const Color border = Color(0xFF3D4460);
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);
  static const Color dark = Color(0xFF1A1D2E);

  // Gradients
  static const List<Color> primaryGradient = [
    Color(0xFFFF2D75),
    Color(0xFF8B5CF6),
    Color(0xFF4F46E5),
  ];

  static const List<Color> warmGradient = [
    Color(0xFFFF7A00),
    Color(0xFFFF2D75),
    Color(0xFF9333EA),
  ];

  static const List<Color> supportGradient = [
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFFF2D75),
  ];

  // Aliases for broader compatibility
  static const Color background = bg;
  static const Color textMuted = muted;
  static const Color error = danger;
}
