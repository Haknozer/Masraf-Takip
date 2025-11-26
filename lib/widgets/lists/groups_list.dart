import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../cards/group_card.dart';

class GroupsList extends StatelessWidget {
  final List<GroupModel> groups;
  final Future<void> Function()? onRefresh;
  final void Function(GroupModel group)? onUnblock;

  const GroupsList({super.key, required this.groups, this.onRefresh, this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.sectionPadding),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          final card = GroupCard(group: group);

          if (onUnblock == null) {
            return card;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              card,
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => onUnblock!(group),
                  child: const Text('Engellemeyi Kaldır'),
                ),
              ),
              const SizedBox(height: AppSpacing.textSpacing),
            ],
          );
        },
      ),
    );
  }
}
