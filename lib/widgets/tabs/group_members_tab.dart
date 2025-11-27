import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../cards/group_header_card.dart';
import '../sections/group_members_section.dart';

class GroupMembersTab extends StatelessWidget {
  final GroupModel group;
  final bool isMember;

  const GroupMembersTab({super.key, required this.group, required this.isMember});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sectionPadding),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          GroupHeaderCard(group: group),
          const SizedBox(height: AppSpacing.sectionMargin),
          // Group Members
          GroupMembersSection(group: group),
        ],
      ),
    );
  }
}
