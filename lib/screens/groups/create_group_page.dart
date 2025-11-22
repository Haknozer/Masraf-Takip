import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../widgets/app_bars/create_group_app_bar.dart';
import '../../widgets/sections/create_group_header.dart';
import '../../widgets/forms/create_group_form.dart';
import '../../widgets/common/base_page.dart';

class CreateGroupPage extends ConsumerWidget {
  const CreateGroupPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BasePage(
      appBar: const CreateGroupAppBar(),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CreateGroupHeader(),
          CreateGroupForm(
            onSuccess: () {
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
