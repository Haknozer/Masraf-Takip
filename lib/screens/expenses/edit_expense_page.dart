import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/app_bars/edit_expense_app_bar.dart';
import '../../widgets/forms/edit_expense_form.dart';

class EditExpensePage extends ConsumerWidget {
  final String expenseId;

  const EditExpensePage({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePage(
      appBar: const EditExpenseAppBar(),
      body: EditExpenseForm(
        expenseId: expenseId,
        onSuccess: () {
          Navigator.pop(context);
        },
        onDelete: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
