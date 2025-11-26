import 'package:flutter/material.dart';
import '../../../constants/app_text_styles.dart';
import '../../../constants/app_colors.dart';
import '../../../models/user_model.dart';

class MemberSettlementCard extends StatelessWidget {
  final UserModel member;
  final bool isSettled;
  final bool isCurrentUser;
  final bool isProcessing;
  final ValueChanged<bool?>? onChanged;

  const MemberSettlementCard({
    super.key,
    required this.member,
    required this.isSettled,
    required this.isCurrentUser,
    required this.isProcessing,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color:
            isSettled
                ? AppColors.success.withValues(alpha: 0.1)
                : Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSettled ? AppColors.success : Theme.of(context).colorScheme.surfaceContainerHighest,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: isSettled,
            onChanged: isProcessing ? null : onChanged,
            activeColor: AppColors.success,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName + (isCurrentUser ? ' (Sen)' : ''),
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: isCurrentUser ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                if (isSettled)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Kimseden alacağım borç yok',
                      style: AppTextStyles.bodySmall.copyWith(color: AppColors.success),
                    ),
                  ),
              ],
            ),
          ),
          if (!isCurrentUser && !isSettled)
            Icon(Icons.lock_outline, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
        ],
      ),
    );
  }
}

