import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../../utils/date_utils.dart' as DateUtils;

/// Masraf item widget'ı
class ExpenseItem extends StatelessWidget {
  final ExpenseModel expense;
  final VoidCallback? onTap;
  final bool showEditIcon;
  final List<UserModel>? groupMembers;

  const ExpenseItem({
    super.key,
    required this.expense,
    this.onTap,
    this.showEditIcon = false,
    this.groupMembers,
  });

  String _getUserName(String userId) {
    if (groupMembers == null) return 'Bilinmeyen';
    final user = groupMembers!.firstWhere(
      (u) => u.id == userId,
      orElse: () => UserModel(
        id: '',
        email: '',
        displayName: 'Bilinmeyen',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        groups: [],
      ),
    );
    return user.displayName;
  }

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategories.getById(expense.category);
    final icon = category?.icon ?? Icons.receipt;
    final color = category?.color ?? AppColors.primary;
    final paidByName = _getUserName(expense.paidBy);
    final participantCount = expense.sharedBy.length;

    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(
          expense.description,
          style: AppTextStyles.bodyMedium,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateUtils.AppDateUtils.formatDate(expense.date),
              style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$paidByName tarafından ödendi',
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '$participantCount kişi dahil',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ],
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

