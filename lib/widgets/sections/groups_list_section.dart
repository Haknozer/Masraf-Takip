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
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sectionPadding,
      ),
      child: groupsState.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const EmptyGroupsCard();
          }
          return _buildGroupsList(groups, context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorCard(error: error.toString()),
      ),
    );
  }

  Widget _buildGroupsList(
    List<GroupModel> groups,
    BuildContext context,
    WidgetRef ref,
  ) {
    // Sadece aktif grupları göster (ana sayfada)
    final activeGroups = groups.where((group) => group.isActive).take(3).toList();
    
    return Column(
      children: [
        ...activeGroups.map((group) => GroupCard(group: group)),
      ],
    );
  }

}
