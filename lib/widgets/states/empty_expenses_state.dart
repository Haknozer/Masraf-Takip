import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';

/// Boş masraflar state widget'ı
class EmptyExpensesState extends StatelessWidget {
  final String? message;

  const EmptyExpensesState({
    super.key,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Center(
          child: Text(
            message ?? 'Henüz masraf eklenmemiş',
            style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

