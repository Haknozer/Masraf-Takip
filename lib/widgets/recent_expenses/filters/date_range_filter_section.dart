import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_text_styles.dart';
import '../../../utils/date_utils.dart' as date_utils;

class DateRangeFilterSection extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onStartDateTap;
  final VoidCallback onEndDateTap;

  const DateRangeFilterSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.onStartDateTap,
    required this.onEndDateTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tarih Aralığı', style: AppTextStyles.label),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: onStartDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today, 
                        size: 18, 
                        color: isDark ? colorScheme.onSurfaceVariant : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        startDate != null ? date_utils.AppDateUtils.formatDate(startDate!) : 'Başlangıç',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: startDate != null 
                            ? (isDark ? colorScheme.onSurface : AppColors.textPrimary)
                            : (isDark ? colorScheme.onSurfaceVariant : AppColors.textHint),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: InkWell(
                onTap: onEndDateTap,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? colorScheme.surfaceContainerHighest : AppColors.greyLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today, 
                        size: 18, 
                        color: isDark ? colorScheme.onSurfaceVariant : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        endDate != null ? date_utils.AppDateUtils.formatDate(endDate!) : 'Bitiş',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: endDate != null 
                            ? (isDark ? colorScheme.onSurface : AppColors.textPrimary)
                            : (isDark ? colorScheme.onSurfaceVariant : AppColors.textHint),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

