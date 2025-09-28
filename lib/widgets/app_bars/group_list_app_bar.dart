import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../screens/groups/create_group_page.dart';

class GroupListAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GroupListAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: const Text('Gruplarım'),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateGroupPage()));
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
