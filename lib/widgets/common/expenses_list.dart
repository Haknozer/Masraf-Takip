import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../models/user_model.dart';
import '../../widgets/cards/expense_item.dart';

/// Masraflar listesi widget'ı
class ExpensesList extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final Function(ExpenseModel)? onExpenseTap;
  final Function(ExpenseModel)? onExpenseDelete;
  final bool showDividers;
  final bool showEditIcon;
  final bool showDeleteIcon;
  final List<UserModel>? groupMembers;
  final String? currentUserId;

  const ExpensesList({
    super.key,
    required this.expenses,
    this.onExpenseTap,
    this.onExpenseDelete,
    this.showDividers = true,
    this.showEditIcon = false,
    this.showDeleteIcon = false,
    this.groupMembers,
    this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    if (expenses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        for (int i = 0; i < expenses.length; i++) ...[
          ExpenseItem(
            expense: expenses[i],
            onTap: onExpenseTap != null ? () => onExpenseTap!(expenses[i]) : null,
            onDelete: onExpenseDelete != null ? () => onExpenseDelete!(expenses[i]) : null,
            showEditIcon: showEditIcon,
            showDeleteIcon: showDeleteIcon,
            groupMembers: groupMembers,
            currentUserId: currentUserId,
          ),
          if (showDividers && i < expenses.length - 1) const Divider(),
        ],
      ],
    );
  }
}

