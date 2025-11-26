import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';

class DebtGroupSummaryItem extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;

  const DebtGroupSummaryItem({super.key, required this.label, required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        Text(
          '${amount.toStringAsFixed(2)} ₺',
          style: AppTextStyles.bodyLarge.copyWith(color: color, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

