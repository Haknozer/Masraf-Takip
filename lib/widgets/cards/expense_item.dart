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
  final VoidCallback? onDelete;
  final bool showEditIcon;
  final bool showDeleteIcon;
  final List<UserModel>? groupMembers;
  final String? currentUserId;

  const ExpenseItem({
    super.key,
    required this.expense,
    this.onTap,
    this.onDelete,
    this.showEditIcon = false,
    this.showDeleteIcon = false,
    this.groupMembers,
    this.currentUserId,
  });

  String _getUserName(String userId) {
    if (groupMembers == null) return 'Bilinmeyen';
    final user = groupMembers!.firstWhere(
      (u) => u.id == userId,
      orElse:
          () => UserModel(
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
    final color = category?.color ?? Theme.of(context).colorScheme.primary;
    final paidByName = _getUserName(expense.paidBy);
    final participantCount = expense.sharedBy.length;

    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: _buildLeading(context, icon, color),
        title: Text(expense.description, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              DateUtils.AppDateUtils.formatDate(expense.date),
              style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$paidByName tarafından ödendi',
                        style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.people, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        '$participantCount kişi dahil',
                        style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        overflow: TextOverflow.ellipsis,
                      ),
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
              style: AppTextStyles.bodyMedium.copyWith(color: AppColors.success, fontWeight: FontWeight.bold),
            ),
            if (showEditIcon && onTap != null) ...[
              const SizedBox(width: 8),
              Icon(Icons.edit, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
            if (showDeleteIcon && onDelete != null && currentUserId != null && expense.paidBy == currentUserId) ...[
              const SizedBox(width: 8),
              GestureDetector(onTap: onDelete, child: Icon(Icons.delete_outline, size: 18, color: AppColors.error)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLeading(BuildContext context, IconData icon, Color fallbackColor) {
    if (expense.imageUrl != null && expense.imageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(
          expense.imageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildIconAvatar(icon, fallbackColor),
        ),
      );
    }
    return _buildIconAvatar(icon, fallbackColor);
  }

  Widget _buildIconAvatar(IconData icon, Color color) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: color),
    );
  }
}
