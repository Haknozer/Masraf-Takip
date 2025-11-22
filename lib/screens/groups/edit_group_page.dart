import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bars/edit_group_app_bar.dart';
import '../../widgets/forms/edit_group_form.dart';
import '../../widgets/common/base_page.dart';

class EditGroupPage extends ConsumerWidget {
  final String groupId;

  const EditGroupPage({super.key, required this.groupId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    print('EditGroupPage build - GroupId: $groupId');
    if (groupId.isEmpty) {
      print('UYARI: EditGroupPage\'e boş groupId geçirildi!');
    }

    return BasePage(
      appBar: const EditGroupAppBar(),
      body: EditGroupForm(
        groupId: groupId,
        onSuccess: () {
          Navigator.pop(context);
        },
      ),
    );
  }
}
