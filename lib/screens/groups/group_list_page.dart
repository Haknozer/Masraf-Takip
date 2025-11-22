import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/group_provider.dart';
import '../../widgets/app_bars/group_list_app_bar.dart';
import '../../widgets/states/empty_groups_state.dart';
import '../../widgets/states/error_state.dart';
import '../../widgets/lists/groups_list.dart';
import '../../widgets/common/base_page.dart';
import '../../widgets/common/async_value_builder.dart';

class GroupListPage extends ConsumerWidget {
  const GroupListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(userGroupsProvider);

    return BasePage(
      appBar: const GroupListAppBar(),
      useScrollView: false,
      body: AsyncValueBuilder(
        value: groupsState,
        dataBuilder: (context, groups) {
          if (groups.isEmpty) {
            return const EmptyGroupsState();
          }
          return GroupsList(
            groups: groups,
            onRefresh: () async {
              // Refresh groups logic
            },
          );
        },
        errorBuilder: (context, error, stack) => ErrorState(
          error: error.toString(),
          onRetry: () {
            // Retry logic
          },
        ),
      ),
    );
  }
}
