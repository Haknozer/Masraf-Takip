import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/debt_model.dart';
import 'debt_group_summary_item.dart';

class DebtGroupCard extends StatelessWidget {
  final GroupDebtSummary groupSummary;
  final VoidCallback onTap;

  const DebtGroupCard({super.key, required this.groupSummary, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(groupSummary.groupName, style: AppTextStyles.h4)),
                  Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DebtGroupSummaryItem(label: 'Borç', amount: groupSummary.totalOwed, color: AppColors.error),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DebtGroupSummaryItem(
                      label: 'Alacak',
                      amount: groupSummary.totalOwing,
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              if (groupSummary.netAmount != 0) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: (groupSummary.netAmount > 0 ? AppColors.success : AppColors.error).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Net', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
                      Text(
                        '${groupSummary.netAmount > 0 ? '+' : ''}${groupSummary.netAmount.toStringAsFixed(2)} ₺',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: groupSummary.netAmount > 0 ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
