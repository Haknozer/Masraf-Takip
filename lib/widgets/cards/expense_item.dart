import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../utils/date_utils.dart' as DateUtils;

/// Masraf item widget'ı
class ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final bool showEditIcon;

  const ExpenseItem({
    super.key,
    required this.expense,
    this.onTap,
    this.showEditIcon = false,
  });

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategories.getById(expense.category);
    final icon = category?.icon ?? Icons.receipt;
    final color = category?.color ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(expense.description, style: AppTextStyles.bodyMedium),
        subtitle: Text(
          DateUtils.AppDateUtils.formatDate(expense.date),
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${expense.amount.toStringAsFixed(2)} ₺',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (showEditIcon && onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.edit, size: 18, color: AppColors.textSecondary),
            ],
          ],
        ),
      ),
    );
  }
}

