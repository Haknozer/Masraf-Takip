import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../cards/group_card.dart';
import '../cards/empty_groups_card.dart';
import '../cards/error_card.dart';

class GroupsListSection extends ConsumerWidget {
  const GroupsListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(userGroupsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sectionPadding),
      child: groupsState.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const EmptyGroupsCard();
          }
          return _buildGroupsList(groups);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorCard(error: error.toString()),
      ),
    );
  }

  Widget _buildGroupsList(List<GroupModel> groups) {
    return Column(children: groups.take(3).map((group) => GroupCard(group: group)).toList());
  }
}
