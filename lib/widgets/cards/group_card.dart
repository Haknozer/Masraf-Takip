import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../models/group_model.dart';
import '../../screens/groups/group_detail_page.dart';

class GroupCard extends StatelessWidget {
  final GroupModel group;

  const GroupCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => GroupDetailPage(groupId: group.id)));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              group.imageUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        group.imageUrl!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 48,
                            height: 48,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(Icons.group, color: AppColors.primary, size: 24),
                          );
                        },
                      ),
                    )
                  : Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.group, color: AppColors.primary, size: 24),
                    ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(group.name, style: AppTextStyles.h4, maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (group.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        group.description,
                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberIds.length} üye',
                          style: AppTextStyles.caption.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}
