import 'package:flutter/material.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/expense_categories.dart';
import '../category_filter_chip.dart';

class CategoryFilterSection extends StatelessWidget {
  final List<String> selectedCategoryIds;
  final ValueChanged<List<String>> onCategoriesSelected;

  const CategoryFilterSection({super.key, required this.selectedCategoryIds, required this.onCategoriesSelected});

  void _toggleCategory(String? categoryId) {
    if (categoryId == null) {
      // "Tümü" seçildi - tüm seçimleri temizle
      onCategoriesSelected([]);
    } else {
      // Kategori seçimi toggle
      final newSelection = List<String>.from(selectedCategoryIds);
      if (newSelection.contains(categoryId)) {
        newSelection.remove(categoryId);
      } else {
        newSelection.add(categoryId);
      }
      onCategoriesSelected(newSelection);
    }
  }

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
              isSelected: selectedCategoryIds.isEmpty,
              onTap: () => _toggleCategory(null),
            ),
            ...ExpenseCategories.all.map(
              (category) => CategoryFilterChip(
                label: category.name,
                icon: category.icon,
                color: category.color,
                isSelected: selectedCategoryIds.contains(category.id),
                onTap: () => _toggleCategory(category.id),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
