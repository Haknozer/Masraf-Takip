import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import 'recent_expenses_search_bar.dart';

class RecentExpensesFiltersToolbar extends StatelessWidget {
  final TextEditingController searchController;
  final VoidCallback onFilterTap;
  final VoidCallback onClearFilters;
  final bool isFilterActive;

  const RecentExpensesFiltersToolbar({
    super.key,
    required this.searchController,
    required this.onFilterTap,
    required this.onClearFilters,
    required this.isFilterActive,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Arama bar (küçültülmüş)
        Expanded(flex: 3, child: RecentExpensesSearchBar(controller: searchController)),
        const SizedBox(width: 8),
        // Filtreleme butonu
        OutlinedButton.icon(
          onPressed: onFilterTap,
          icon: Icon(
            Icons.filter_list,
            size: 18,
            color: isFilterActive ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          label: Text(
            'Filtrele',
            style: AppTextStyles.bodySmall.copyWith(
              color: isFilterActive ? AppColors.primary : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            side: BorderSide(color: isFilterActive ? AppColors.primary : AppColors.grey, width: isFilterActive ? 1.5 : 1),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: isFilterActive ? AppColors.primary.withValues(alpha: 0.1) : null,
          ),
        ),
        if (isFilterActive)
          IconButton(
            icon: Icon(Icons.clear_all, size: 20, color: AppColors.error),
            onPressed: onClearFilters,
            tooltip: 'Tüm filtreleri temizle',
            padding: const EdgeInsets.all(8),
            constraints: const BoxConstraints(),
          ),
      ],
    );
  }
}
