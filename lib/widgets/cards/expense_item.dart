import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/expense_categories.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../avatars/expense_item_avatar.dart';
import 'expense_item_subtitle.dart';
import 'expense_item_trailing.dart';

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

  String _buildPayerInfo() {
    final payerMap = expense.paidAmounts;
    if (payerMap == null || payerMap.isEmpty) {
      final name = _getUserName(expense.paidBy);
      return '$name ödedi';
    }
    final sorted = payerMap.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final firstName = _getUserName(sorted.first.key);
    if (sorted.length == 1) {
      return '$firstName ${sorted.first.value.toStringAsFixed(2)} ₺ ödedi';
    }
    final others = sorted.length - 1;
    return '$firstName +$others kişi ödedi';
  }

  bool _canCurrentUserDelete() {
    if (currentUserId == null) return false;
    if (expense.paidBy == currentUserId) return true;
    if (expense.paidAmounts != null && expense.paidAmounts!.containsKey(currentUserId)) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final category = ExpenseCategories.getById(expense.category);
    final icon = category?.icon ?? Icons.receipt;
    final color = category?.color ?? Theme.of(context).colorScheme.primary;
    final participantCount = expense.sharedBy.length;
    final payerInfo = _buildPayerInfo();

    return InkWell(
      onTap: onTap,
      child: ListTile(
        leading: ExpenseItemAvatar(imageUrl: expense.imageUrl, icon: icon, color: color),
        title: Text(expense.description, style: AppTextStyles.bodyMedium, overflow: TextOverflow.ellipsis, maxLines: 1),
        subtitle: ExpenseItemSubtitle(date: expense.date, payerInfo: payerInfo, participantCount: participantCount),
        trailing: ExpenseItemTrailing(
          amount: expense.amount,
          showEditIcon: showEditIcon,
          showDeleteIcon: showDeleteIcon,
          canDelete: _canCurrentUserDelete(),
          onTap: onTap,
          onDelete: onDelete,
        ),
      ),
    );
  }
}
