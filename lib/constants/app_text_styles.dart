import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTextStyles {
  // Headers
  static const TextStyle h1 = TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textPrimary);

  static const TextStyle h2 = TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary);

  static const TextStyle h3 = TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  static const TextStyle h4 = TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary);

  // Body Text
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Button Text
  static const TextStyle buttonLarge = TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.white);

  static const TextStyle buttonMedium = TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.white);

  // Caption
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  // Label
  static const TextStyle label = TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary);
}
