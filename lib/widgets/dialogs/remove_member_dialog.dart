import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/debt_model.dart';
import '../../models/user_model.dart';

/// Üye çıkarma onay dialogu (borç varsa)
class RemoveMemberDialog extends StatelessWidget {
  final UserModel member;
  final List<DebtBetweenUsers> debts;

  const RemoveMemberDialog({
    super.key,
    required this.member,
    required this.debts,
  });

  static Future<bool?> show(
    BuildContext context, {
    required UserModel member,
    required List<DebtBetweenUsers> debts,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => RemoveMemberDialog(
        member: member,
        debts: debts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalDebt = debts.fold(0.0, (sum, debt) => sum + debt.amount);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.warning, color: AppColors.warning, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Üyeyi Çıkar',
              style: AppTextStyles.h3.copyWith(color: AppColors.warning),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${member.displayName} adlı üyenin grupta borcu bulunmaktadır.',
              style: AppTextStyles.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.warning, width: 1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.account_balance_wallet, size: 20, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Text(
                        'Toplam Borç: ${totalDebt.toStringAsFixed(2)} ₺',
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            if (debts.isNotEmpty) ...[
              Text(
                'Borç Detayları:',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              ...debts.map((debt) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.greyLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                debt.toUserName,
                                style: AppTextStyles.bodySmall.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${debt.amount.toStringAsFixed(2)} ₺',
                                style: AppTextStyles.bodySmall.copyWith(
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: AppSpacing.sectionMargin),
            Text(
              'Üyeyi çıkardığınızda, bu üyeye ait tüm masraflar güncellenecek ve üye masraflardan kaldırılacaktır. Bu işlem geri alınamaz.',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text(
            'İptal',
            style: AppTextStyles.buttonMedium.copyWith(color: AppColors.textSecondary),
          ),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.warning,
            foregroundColor: AppColors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: const Text('Devam Et'),
        ),
      ],
    );
  }
}

