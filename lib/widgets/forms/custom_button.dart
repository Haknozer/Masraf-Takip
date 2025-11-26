import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isSecondary;
  final IconData? icon;
  final double? width;
  final double height;
  final Color? backgroundColor;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isSecondary = false,
    this.icon,
    this.width,
    this.height = 56,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final Color baseBackground = backgroundColor ?? (isSecondary ? colorScheme.secondary : colorScheme.primary);
    final Brightness brightness = ThemeData.estimateBrightnessForColor(baseBackground);
    final Color baseForeground = brightness == Brightness.dark ? Colors.white : Colors.black;
    final Color foregroundColor =
        backgroundColor == null ? (isSecondary ? colorScheme.onSecondary : colorScheme.onPrimary) : baseForeground;
    final Color disabledBackground = colorScheme.onSurface.withValues(alpha: 0.12);
    final Color disabledForeground = colorScheme.onSurface.withValues(alpha: 0.38);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: baseBackground,
          foregroundColor: foregroundColor,
          elevation: 2,
          shadowColor: baseBackground.withValues(alpha: 0.25),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          disabledBackgroundColor: disabledBackground,
          disabledForegroundColor: disabledForeground,
        ),
        child:
            isLoading
                ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(foregroundColor),
                  ),
                )
                : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 20, color: foregroundColor), const SizedBox(width: 8)],
                    Text(text, style: AppTextStyles.buttonLarge.copyWith(color: foregroundColor)),
                  ],
                ),
      ),
    );
  }
}
