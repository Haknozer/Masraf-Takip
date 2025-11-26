import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../../providers/group_provider.dart';
import '../../forms/create_group_form.dart';

class CreateGroupDialog extends ConsumerWidget {
  const CreateGroupDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateGroupDialog(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        padding: const EdgeInsets.all(AppSpacing.sectionPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Yeni Grup Oluştur', style: AppTextStyles.h3),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            Flexible(
              child: SingleChildScrollView(
                child: CreateGroupForm(
                  onSuccess: () {
                    Navigator.pop(context);
                    // Grupları yenile
                    ref.invalidate(userGroupsProvider);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

