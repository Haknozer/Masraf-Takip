import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class ManualDistributionTotal extends StatelessWidget {
  final double total;
  final double targetTotal;
  final bool isValid;
  final double difference;

  const ManualDistributionTotal({
    super.key,
    required this.total,
    required this.targetTotal,
    required this.isValid,
    required this.difference,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isValid ? AppColors.success.withValues(alpha: 0.1) : AppColors.error.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isValid ? AppColors.success : AppColors.error, width: 1),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Toplam:', style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold)),
              Text(
                '${total.toStringAsFixed(2)} TL / ${targetTotal.toStringAsFixed(2)} TL',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isValid ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        if (!isValid)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              difference > 0
                  ? 'Eksik: ${difference.toStringAsFixed(2)} TL'
                  : 'Fazla: ${(-difference).toStringAsFixed(2)} TL',
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
      ],
    );
  }
}

