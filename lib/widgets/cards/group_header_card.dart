import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../utils/date_utils.dart';

class GroupHeaderCard extends StatelessWidget {
  final GroupModel group;

  const GroupHeaderCard({super.key, required this.group});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                group.imageUrl != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          group.imageUrl!,
                          width: 64,
                          height: 64,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 64,
                              height: 64,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(Icons.group, color: AppColors.primary, size: 32),
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
                        child: Icon(Icons.group, color: AppColors.primary, size: 32),
                      ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(group.name, style: AppTextStyles.h2),
                      if (group.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          group.description,
                          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildInfoItem(Icons.people, '${group.memberIds.length} Üye'),
                const SizedBox(width: 24),
                _buildInfoItem(Icons.calendar_today, AppDateUtils.formatDate(group.createdAt)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Text(text, style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary)),
      ],
    );
  }
}
