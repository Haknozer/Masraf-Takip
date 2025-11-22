import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../widgets/cards/expense_item.dart';

/// Masraflar listesi widget'ı
class ExpensesList extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final Function(ExpenseModel)? onExpenseTap;
  final bool showDividers;

  const ExpensesList({
    super.key,
    required this.expenses,
    this.onExpenseTap,
    this.showDividers = true,
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
          ),
          if (showDividers && i < expenses.length - 1) const Divider(),
        ],
      ],
    );
  }
}

