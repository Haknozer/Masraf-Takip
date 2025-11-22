import 'package:flutter/material.dart';
import '../../constants/expense_categories.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';

/// Kategori seçim widget'ı
class CategorySelector extends StatelessWidget {
  final String? selectedCategoryId;
  final Function(String categoryId) onCategorySelected;

  const CategorySelector({
    super.key,
    this.selectedCategoryId,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: AppTextStyles.label),
        const SizedBox(height: AppSpacing.textSpacing),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ExpenseCategories.all.map((category) {
            final isSelected = selectedCategoryId == category.id;
            return GestureDetector(
              onTap: () => onCategorySelected(category.id),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? category.color.withOpacity(0.1) : AppColors.greyLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? category.color : AppColors.greyLight,
                    width: isSelected ? 2 : 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      category.icon,
                      color: isSelected ? category.color : AppColors.textSecondary,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      category.name,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isSelected ? category.color : AppColors.textSecondary,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

