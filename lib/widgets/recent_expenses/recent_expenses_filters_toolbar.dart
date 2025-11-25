import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class RecentExpensesFiltersToolbar extends StatelessWidget {
  final List<Widget> activeChips;
  final bool hasActiveFilter;
  final VoidCallback onShowFilters;
  final VoidCallback onClearFilters;

  const RecentExpensesFiltersToolbar({
    super.key,
    required this.activeChips,
    required this.hasActiveFilter,
    required this.onShowFilters,
    required this.onClearFilters,
  });

  @override
  Widget build(BuildContext context) {
    if (activeChips.isEmpty && !hasActiveFilter) {
      return OutlinedButton.icon(
        onPressed: onShowFilters,
        icon: Icon(Icons.filter_list, size: 16, color: AppColors.primary),
        label: Text('Filtrele', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          side: BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }

    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ...activeChips,
                if (activeChips.isNotEmpty) const SizedBox(width: 8),
                OutlinedButton.icon(
                  onPressed: onShowFilters,
                  icon: Icon(Icons.filter_list, size: 16, color: AppColors.primary),
                  label: Text('Filtrele', style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    side: BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (hasActiveFilter)
          IconButton(
            icon: Icon(Icons.clear_all, color: AppColors.error),
            onPressed: onClearFilters,
            tooltip: 'Tüm filtreleri temizle',
          ),
      ],
    );
  }
}
