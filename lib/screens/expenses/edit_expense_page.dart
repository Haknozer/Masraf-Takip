import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/app_bars/edit_expense_app_bar.dart';
import '../../widgets/forms/edit_expense_form.dart';
import '../../providers/expense_provider.dart';
import '../../providers/group_provider.dart';
import '../../widgets/common/async_value_builder.dart';

class EditExpensePage extends ConsumerWidget {
  final String expenseId;

  const EditExpensePage({super.key, required this.expenseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseState = ref.watch(expenseProvider(expenseId));

    return BasePage(
      appBar: const EditExpenseAppBar(),
      body: AsyncValueBuilder(
        value: expenseState,
        dataBuilder: (context, expense) {
          if (expense == null) {
            return const Center(child: Text('Masraf bulunamadı'));
          }

          final groupState = ref.watch(groupProvider(expense.groupId));
          return AsyncValueBuilder(
            value: groupState,
            dataBuilder: (context, group) {
              if (group == null) {
                return const Center(child: Text('Grup bulunamadı'));
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: EditExpenseForm(expense: expense, group: group, onSuccess: () => Navigator.pop(context)),
              );
            },
          );
        },
      ),
    );
  }
}
