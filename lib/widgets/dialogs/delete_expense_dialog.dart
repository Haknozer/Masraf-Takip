import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';

/// Masraf silme onay dialogu
class DeleteExpenseDialog extends StatelessWidget {
  final String expenseDescription;
  final double expenseAmount;

  const DeleteExpenseDialog({
    super.key,
    required this.expenseDescription,
    required this.expenseAmount,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String expenseDescription,
    required double expenseAmount,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => DeleteExpenseDialog(
        expenseDescription: expenseDescription,
        expenseAmount: expenseAmount,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning, color: AppColors.error, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Masrafı Sil',
              style: AppTextStyles.h3.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bu masrafı silmek istediğinizden emin misiniz?',
            style: AppTextStyles.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.sectionMargin),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expenseDescription,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${expenseAmount.toStringAsFixed(2)} ₺',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionMargin),
          Text(
            'Bu işlem geri alınamaz.',
            style: AppTextStyles.bodySmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'İptal',
            style: AppTextStyles.buttonMedium.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant
            ),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Sil'),
        ),
      ],
    );
  }
}

