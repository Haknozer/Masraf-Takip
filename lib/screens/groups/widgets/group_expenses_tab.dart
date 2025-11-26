import 'package:flutter/material.dart';
import '../../../constants/app_spacing.dart';
import '../../../models/group_model.dart';
import '../../../widgets/sections/recent_expenses_section.dart';

class GroupExpensesTab extends StatelessWidget {
  final GroupModel group;

  const GroupExpensesTab({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recent Expenses
          RecentExpensesSection(groupId: group.id),
        ],
      ),
    );
  }
}

