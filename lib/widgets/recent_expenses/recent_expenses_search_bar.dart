import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_text_styles.dart';

class RecentExpensesSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onClear;

  const RecentExpensesSearchBar({super.key, required this.controller, required this.onClear});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: 'Masraf ara...',
            hintStyle: AppTextStyles.bodyMedium.copyWith(color: AppColors.textHint),
            prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
            suffixIcon:
                controller.text.isNotEmpty
                    ? IconButton(icon: Icon(Icons.clear, color: AppColors.textSecondary), onPressed: onClear)
                    : null,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.greyLight, width: 1),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.greyLight, width: 1),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          style: AppTextStyles.bodyMedium,
        ),
      ),
    );
  }
}
