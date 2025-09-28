import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_spacing.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../widgets/app_bars/group_detail_app_bar.dart';
import '../../widgets/cards/group_header_card.dart';
import '../../widgets/sections/quick_actions_section.dart';
import '../../widgets/sections/recent_expenses_section.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupState = ref.watch(groupProvider(groupId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: const GroupDetailAppBar(),
      body: groupState.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('Grup bulunamadı'));
          }
          return _buildGroupDetail(group);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('Hata: $error')),
      ),
    );
  }

  Widget _buildGroupDetail(GroupModel group) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          GroupHeaderCard(group: group),
          const SizedBox(height: AppSpacing.sectionMargin),

          // Quick Actions
          const QuickActionsSection(),
          const SizedBox(height: AppSpacing.sectionMargin),

          // Recent Expenses
          const RecentExpensesSection(),
        ],
      ),
    );
  }
}
