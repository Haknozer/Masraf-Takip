import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../models/group_model.dart';
import '../../screens/groups/edit_group_page.dart';

class GroupDetailAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String groupId;
  final GroupModel? group; // Opsiyonel: group objesi varsa ondan id al

  const GroupDetailAppBar({super.key, required this.groupId, this.group});

  @override
  Widget build(BuildContext context) {
    // GroupId'yi belirle: önce group objesinden, yoksa parametreden
    final effectiveGroupId = group?.id.isNotEmpty == true ? group!.id : groupId;

    print('GroupDetailAppBar build - GroupId: $effectiveGroupId, isEmpty: ${effectiveGroupId.isEmpty}');

    return AppBar(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      title: const Text('Grup Detayı'),
      elevation: 0,
      actions: [
        IconButton(
          icon: const Icon(Icons.edit),
          onPressed: () {
            print('GroupDetailAppBar - Edit butonu tıklandı, GroupId: $effectiveGroupId');
            if (effectiveGroupId.isEmpty) {
              print('UYARI: GroupDetailAppBar\'dan boş groupId geçiriliyor!');
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Grup ID bulunamadı. Lütfen tekrar deneyin.')));
              return;
            }
            Navigator.push(context, MaterialPageRoute(builder: (context) => EditGroupPage(groupId: effectiveGroupId)));
          },
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
