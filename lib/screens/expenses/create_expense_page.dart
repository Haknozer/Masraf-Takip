import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/group_model.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/app_bars/create_expense_app_bar.dart';
import '../../widgets/forms/create_expense_form.dart';

class CreateExpensePage extends ConsumerWidget {
  final GroupModel group;

  const CreateExpensePage({
    super.key,
    required this.group,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePage(
      appBar: const CreateExpenseAppBar(),
      body: CreateExpenseForm(
        group: group,
        onSuccess: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}

