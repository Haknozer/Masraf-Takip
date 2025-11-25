import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_spacing.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../providers/group_provider.dart';
import '../../models/group_model.dart';
import '../cards/group_card.dart';
import '../cards/empty_groups_card.dart';
import '../cards/error_card.dart';
import '../forms/create_group_form.dart';

class GroupsListSection extends ConsumerWidget {
  const GroupsListSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsState = ref.watch(userGroupsProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sectionPadding,
      ),
      child: groupsState.when(
        data: (groups) {
          if (groups.isEmpty) {
            return const EmptyGroupsCard();
          }
          return _buildGroupsList(groups, context, ref);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorCard(error: error.toString()),
      ),
    );
  }

  Widget _buildGroupsList(
    List<GroupModel> groups,
    BuildContext context,
    WidgetRef ref,
  ) {
    return Column(
      children: [
        ...groups.take(3).map((group) => GroupCard(group: group)),
        const SizedBox(height: AppSpacing.textSpacing),
        _buildCreateGroupButton(context, ref),
      ],
    );
  }

  Widget _buildCreateGroupButton(BuildContext context, WidgetRef ref) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppColors.primary.withOpacity(0.3),
          width: 1.5,
          style: BorderStyle.solid,
        ),
      ),
      child: InkWell(
        onTap: () => _showCreateGroupDialog(context, ref),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sectionPadding,
            vertical: AppSpacing.textSpacing * 2,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add_circle_outline,
                color: AppColors.primary,
                size: 24,
              ),
              const SizedBox(width: AppSpacing.textSpacing),
              Text(
                'Yeni Grup Oluştur',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
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
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
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
          ),
    );
  }
}
