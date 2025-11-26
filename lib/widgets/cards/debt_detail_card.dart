import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/debt_model.dart';
import 'debt_detail_item.dart';

class DebtDetailCard extends StatelessWidget {
  final DebtBetweenUsers debt;
  final String currentUserId;

  const DebtDetailCard({super.key, required this.debt, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    // Kullanıcı borçlu mu? (fromUserId == currentUserId ise borçlu)
    final isOwed = debt.fromUserId == currentUserId;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              isOwed ? Icons.arrow_downward : Icons.arrow_upward,
              color: isOwed ? AppColors.error : AppColors.success,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                isOwed ? '${debt.toUserName}\'a borçlusunuz' : '${debt.fromUserName} size borçlu',
                style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${debt.amount.toStringAsFixed(2)} ₺',
            style: AppTextStyles.h4.copyWith(
              color: isOwed ? AppColors.error : AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Masraf Detayları',
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600, 
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 12),
                ...debt.details.map((detail) => DebtDetailItem(detail: detail)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
