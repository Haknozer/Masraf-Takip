import 'package:flutter/material.dart';
import '../../models/group_model.dart';
import '../lists/groups_list.dart';

class GroupsTabView extends StatelessWidget {
  final List<GroupModel> groups;
  final String searchQuery;
  final String emptyMessage;
  final bool isHistoryTab;
  final Future<void> Function()? onRefresh;
  final void Function(GroupModel group)? onUnblock;

  const GroupsTabView({
    super.key,
    required this.groups,
    required this.searchQuery,
    required this.emptyMessage,
    required this.isHistoryTab,
    this.onRefresh,
    this.onUnblock,
  });

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      if (searchQuery.isNotEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.search_off, size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('Arama sonucu bulunamadı', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(
                  '"$searchQuery" için sonuç bulunamadı',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(isHistoryTab ? Icons.history : Icons.group_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text(emptyMessage, style: Theme.of(context).textTheme.titleLarge),
            ],
          ),
        ),
      );
    }
    return GroupsList(groups: groups, onRefresh: onRefresh, onUnblock: onUnblock);
  }
}
