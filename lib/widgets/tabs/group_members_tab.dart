import 'package:flutter/material.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../cards/group_header_card.dart';
import '../sections/group_members_section.dart';
import '../dialogs/add_member_dialog.dart';

class GroupMembersTab extends StatelessWidget {
  final GroupModel group;
  final bool isMember;

  const GroupMembersTab({super.key, required this.group, required this.isMember});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.sectionPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Group Header
          GroupHeaderCard(group: group),
          const SizedBox(height: AppSpacing.sectionMargin),
          // Group Members
          GroupMembersSection(group: group),
          // Üye Ekle Butonu (Tüm üyeler)
          if (isMember)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sectionMargin),
              child: ElevatedButton.icon(
                onPressed: () {
                  showDialog(context: context, builder: (context) => AddMemberDialog(group: group));
                },
                icon: const Icon(Icons.person_add),
                label: const Text('Üye Ekle'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

