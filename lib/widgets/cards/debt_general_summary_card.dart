import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/debt_model.dart';
import 'debt_summary_item.dart';

class DebtGeneralSummaryCard extends StatelessWidget {
  final UserDebtSummary summary;

  const DebtGeneralSummaryCard({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Genel Özet', style: AppTextStyles.h4),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DebtSummaryItem(
                    label: 'Toplam Borç',
                    amount: summary.totalOwed,
                    color: AppColors.error,
                    icon: Icons.arrow_downward,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DebtSummaryItem(
                    label: 'Toplam Alacak',
                    amount: summary.totalOwing,
                    color: AppColors.success,
                    icon: Icons.arrow_upward,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: (summary.netAmount > 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: summary.netAmount > 0 ? AppColors.success : AppColors.error, width: 2),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Net Durum', style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
                      const SizedBox(height: 4),
                      Text(
                        summary.netAmount > 0 ? 'Alacaklısınız' : 'Borçlusunuz',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Text(
                    '${summary.netAmount > 0 ? '+' : ''}${summary.netAmount.toStringAsFixed(2)} ₺',
                    style: AppTextStyles.h3.copyWith(
                      color: summary.netAmount > 0 ? AppColors.success : AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
