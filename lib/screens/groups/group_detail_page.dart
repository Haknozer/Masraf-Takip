import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../../widgets/app_bars/group_detail_app_bar.dart';
import '../../widgets/cards/group_header_card.dart';
import '../../widgets/sections/quick_actions_section.dart';
import '../../widgets/sections/recent_expenses_section.dart';
import '../../widgets/sections/group_members_section.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/async_value_builder.dart';

class GroupDetailPage extends ConsumerWidget {
  final String groupId;

  const GroupDetailPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('GroupDetailPage build - GroupId: $groupId, isEmpty: ${groupId.isEmpty}');
    if (groupId.isEmpty) {
      print('UYARI: GroupDetailPage\'e boş groupId geçirildi!');
    }

    final groupState = ref.watch(groupProvider(groupId));

    return AsyncValueBuilder<GroupModel?>(
      value: groupState,
      dataBuilder: (context, group) {
        if (group == null) {
          return BasePage(
            appBar: GroupDetailAppBar(groupId: groupId),
            useScrollView: false,
            body: const Center(child: Text('Grup bulunamadı')),
          );
        }

        return BasePage(
          appBar: GroupDetailAppBar(groupId: groupId, group: group),
          useScrollView: false,
          body: _buildGroupDetail(group),
        );
      },
      loadingBuilder:
          (context) => BasePage(
            appBar: GroupDetailAppBar(groupId: groupId),
            useScrollView: false,
            body: const Center(child: CircularProgressIndicator()),
          ),
      errorBuilder:
          (context, error, stack) => BasePage(
            appBar: GroupDetailAppBar(groupId: groupId),
            useScrollView: false,
            body: Center(child: Text('Hata: $error')),
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
          QuickActionsSection(group: group),
          const SizedBox(height: AppSpacing.sectionMargin),

          // Group Members
          GroupMembersSection(group: group),
          const SizedBox(height: AppSpacing.sectionMargin),

          // Recent Expenses
          RecentExpensesSection(groupId: group.id),
        ],
      ),
    );
  }
}
