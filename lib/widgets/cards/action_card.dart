import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';

/// Hızlı işlemler için action card widget'ı
class ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool isDisabled;

  const ActionCard({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
    this.isDisabled = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: isDisabled ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Opacity(
          opacity: isDisabled ? 0.5 : 1.0,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              children: [
                Icon(
                  icon,
                  color:
                      isDisabled ? AppColors.textSecondary : AppColors.primary,
                  size: 32,
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color:
                        isDisabled
                            ? AppColors.textSecondary
                            : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
