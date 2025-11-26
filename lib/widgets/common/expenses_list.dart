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

    // ListView.builder ile performans optimizasyonu
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: expenses.length,
      separatorBuilder: (context, index) => showDividers ? const Divider() : const SizedBox.shrink(),
      itemBuilder: (context, index) {
        final expense = expenses[index];
        return ExpenseItem(
          key: ValueKey(expense.id), // Efficient rebuilds için key
          expense: expense,
          onTap: onExpenseTap != null ? () => onExpenseTap!(expense) : null,
          onDelete: onExpenseDelete != null ? () => onExpenseDelete!(expense) : null,
          showEditIcon: showEditIcon,
          showDeleteIcon: showDeleteIcon,
          groupMembers: groupMembers,
          currentUserId: currentUserId,
        );
      },
    );
  }
}

