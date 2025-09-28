import 'package:flutter/material.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../screens/groups/group_list_page.dart';

class GroupsSectionHeader extends StatelessWidget {
  const GroupsSectionHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sectionPadding),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Gruplarım', style: AppTextStyles.h3),
          TextButton.icon(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const GroupListPage()));
            },
            icon: const Icon(Icons.arrow_forward, size: AppSpacing.iconSize),
            label: const Text('Tümünü Gör'),
          ),
        ],
      ),
    );
  }
}
