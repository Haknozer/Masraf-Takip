import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class PaidAmountSummary extends StatelessWidget {
  final double totalPaid;
  final double targetTotal;

  const PaidAmountSummary({
    super.key,
    required this.totalPaid,
    required this.targetTotal,
  });

  @override
  Widget build(BuildContext context) {
    final difference = targetTotal - totalPaid;
    final isValid = difference.abs() < 0.01;
    final color = isValid ? AppColors.success : AppColors.error;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ödenen Toplam', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
              Text(
                '${totalPaid.toStringAsFixed(2)} ₺',
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold, color: color),
              ),
            ],
          ),
          if (!isValid)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                difference > 0
                    ? 'Eksik: ${difference.toStringAsFixed(2)} ₺'
                    : 'Fazla: ${(-difference).toStringAsFixed(2)} ₺',
                style: AppTextStyles.bodySmall.copyWith(color: color),
              ),
            ),
        ],
      ),
    );
  }
}

