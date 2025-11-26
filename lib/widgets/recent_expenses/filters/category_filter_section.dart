import 'package:flutter/material.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/expense_categories.dart';
import '../category_filter_chip.dart';

class CategoryFilterSection extends StatelessWidget {
  final String? selectedCategoryId;
  final ValueChanged<String?> onCategorySelected;

  const CategoryFilterSection({super.key, required this.selectedCategoryId, required this.onCategorySelected});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kategori', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CategoryFilterChip(
              label: 'Tümü',
              isSelected: selectedCategoryId == null,
              onTap: () => onCategorySelected(null),
            ),
            ...ExpenseCategories.all.map(
              (category) => CategoryFilterChip(
                label: category.name,
                icon: category.icon,
                color: category.color,
                isSelected: selectedCategoryId == category.id,
                onTap: () => onCategorySelected(category.id),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
