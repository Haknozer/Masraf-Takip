import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../cards/group_card.dart';

class GroupsList extends StatelessWidget {
  final List<GroupModel> groups;
  final Future<void> Function()? onRefresh;

  const GroupsList({super.key, required this.groups, this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      child: ListView.builder(
        padding: const EdgeInsets.all(AppSpacing.sectionPadding),
        itemCount: groups.length,
        itemBuilder: (context, index) {
          final group = groups[index];
          return GroupCard(group: group);
        },
      ),
    );
  }
}
