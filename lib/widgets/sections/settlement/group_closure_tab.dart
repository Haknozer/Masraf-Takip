import 'package:flutter/material.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_colors.dart';
import '../../../models/group_model.dart';
import '../../../models/user_model.dart';
import '../../../controllers/group_members_controller.dart';
import 'member_settlement_card.dart';

class GroupClosureTab extends StatelessWidget {
  final GroupModel group;
  final String currentUserId;
  final bool isProcessing;
  final VoidCallback onMarkAsSettled;
  final VoidCallback onUnmarkAsSettled;

  const GroupClosureTab({
    super.key,
    required this.group,
    required this.currentUserId,
    required this.isProcessing,
    required this.onMarkAsSettled,
    required this.onUnmarkAsSettled,
  });

  Future<List<UserModel>> _getGroupMembers() async {
    return await GroupMembersController.getGroupMembers(group);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<UserModel>>(
      future: _getGroupMembers(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final members = snapshot.data!;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Grup Üyeleri', style: AppTextStyles.h4),
              const SizedBox(height: AppSpacing.textSpacing),
              Text(
                'Her üye sadece kendi ismini işaretleyebilir',
                style: AppTextStyles.bodySmall.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: AppSpacing.sectionMargin),
              ...members.map((member) {
                final isSettled = group.isUserSettled(member.id);
                final isCurrentUser = currentUserId == member.id;
                
                return MemberSettlementCard(
                  member: member,
                  isSettled: isSettled,
                  isCurrentUser: isCurrentUser,
                  isProcessing: isProcessing,
                  onChanged: isCurrentUser
                      ? (value) {
                          if (value == true) {
                            onMarkAsSettled();
                          } else {
                            onUnmarkAsSettled();
                          }
                        }
                      : null,
                );
              }),
              if (group.isAllMembersSettled) ...[
                const SizedBox(height: AppSpacing.sectionMargin),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.warning),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tüm üyeler hesaplaşmayı tamamladı. Grup kapatıldı ve yeni masraf eklenemez.',
                          style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

