import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';

/// Grup seçim dialogu
class SelectGroupDialog extends StatelessWidget {
  final List<GroupModel> groups;

  const SelectGroupDialog({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
        padding: const EdgeInsets.all(AppSpacing.sectionPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Grup Seç', style: AppTextStyles.h3),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            Flexible(
              child:
                  groups.isEmpty
                      ? Center(
                        child: Text(
                          'Grup bulunamadı',
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      )
                      : ListView.builder(
                        shrinkWrap: true,
                        itemCount: groups.length,
                        itemBuilder: (context, index) {
                          final group = groups[index];
                          return ListTile(
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                              child: Icon(Icons.group, color: AppColors.primary),
                            ),
                            title: Text(
                              group.name,
                              style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                            ),
                            subtitle:
                                group.description.isNotEmpty
                                    ? Text(
                                      group.description,
                                      style: AppTextStyles.bodySmall,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    )
                                    : null,
                            trailing: const Icon(Icons.chevron_right),
                            onTap: () {
                              Navigator.pop(context, group);
                            },
                          );
                        },
                      ),
            ),
          ],
        ),
      ),
    );
  }
}
