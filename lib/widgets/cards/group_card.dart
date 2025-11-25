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
      child: Stack(
        children: [
          InkWell(
            onTap: () {
              print('GroupCard tıklandı - GroupId: ${group.id}, isEmpty: ${group.id.isEmpty}');
              if (group.id.isEmpty) {
                print('UYARI: GroupCard\'dan boş groupId geçiriliyor!');
              }
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
                        style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.people, size: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        const SizedBox(width: 4),
                        Text(
                          '${group.memberIds.length} üye',
                          style: AppTextStyles.caption.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
                  Icon(Icons.chevron_right, color: Theme.of(context).colorScheme.onSurfaceVariant),
                ],
              ),
            ),
          ),
          // Kapalı grup badge'i
          if (!group.isActive)
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.warning,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lock_outline, size: 12, color: Colors.white),
                    const SizedBox(width: 4),
                    Text(
                      'Kapalı',
                      style: AppTextStyles.caption.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
