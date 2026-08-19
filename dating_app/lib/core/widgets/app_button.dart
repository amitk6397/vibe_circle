import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../constants/app_text_styles.dart';

enum AppButtonTone { primary, secondary, danger, ghost }

class AppButton extends StatelessWidget {
  final String title;
  final VoidCallback onPressed;
  final IconData? icon;
  final AppButtonTone tone;
  final bool disabled;
  final bool compact;
  final bool loading;

  const AppButton({
    super.key,
    required this.title,
    required this.onPressed,
    this.icon,
    this.tone = AppButtonTone.primary,
    this.disabled = false,
    this.compact = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    final double height = compact ? 40.0 : 52.0;
    final double radius = compact ? AppDimensions.rSm : AppDimensions.rMd;

    Widget child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading) ...[
          SizedBox(
            width: 18.0,
            height: 18.0,
            child: CircularProgressIndicator(
              strokeWidth: 2.0,
              valueColor: AlwaysStoppedAnimation<Color>(
                tone == AppButtonTone.primary
                    ? Colors.white
                    : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
        ] else if (icon != null) ...[
          Icon(
            icon,
            size: 18.0,
            color: tone == AppButtonTone.primary
                ? Colors.white
                : (tone == AppButtonTone.danger
                      ? AppColors.danger
                      : AppColors.primary),
          ),
          const SizedBox(width: 8.0),
        ],
        Text(
          title,
          style: tone == AppButtonTone.primary
              ? AppTextStyles.buttonText
              : AppTextStyles.altButtonText.copyWith(
                  color: tone == AppButtonTone.danger ? AppColors.danger : null,
                ),
        ),
      ],
    );

    // Decorate depending on tone
    Widget buttonWidget;
    if (tone == AppButtonTone.primary) {
      buttonWidget = Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          gradient: disabled
              ? null
              : const LinearGradient(
                  colors: AppColors.primaryGradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
          color: disabled ? AppColors.muted.withValues(alpha: 0.45) : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled || loading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed();
                  },
            borderRadius: BorderRadius.circular(radius),
            child: Center(child: child),
          ),
        ),
      );
    } else {
      Color bg;
      BorderSide border;

      switch (tone) {
        case AppButtonTone.secondary:
          bg = AppColors.surfaceAlt;
          border = const BorderSide(color: AppColors.border, width: 1.0);
          break;
        case AppButtonTone.danger:
          bg = AppColors.danger.withValues(alpha: 0.12);
          border = const BorderSide(color: AppColors.danger, width: 1.0);
          break;
        case AppButtonTone.ghost:
        default:
          bg = Colors.transparent;
          border = BorderSide.none;
          break;
      }

      buttonWidget = Container(
        height: height,
        decoration: BoxDecoration(
          color: disabled ? bg.withValues(alpha: 0.2) : bg,
          borderRadius: BorderRadius.circular(radius),
          border: border != BorderSide.none
              ? Border.fromBorderSide(border)
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled || loading
                ? null
                : () {
                    HapticFeedback.lightImpact();
                    onPressed();
                  },
            borderRadius: BorderRadius.circular(radius),
            child: Center(child: child),
          ),
        ),
      );
    }

    return Opacity(opacity: disabled ? 0.45 : 1.0, child: buttonWidget);
  }
}
