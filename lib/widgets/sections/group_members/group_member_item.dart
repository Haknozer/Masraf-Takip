import 'package:flutter/material.dart';
import '../../../constants/app_spacing.dart';
import '../../../constants/app_text_styles.dart';
import '../../../models/user_model.dart';
import '../../../constants/app_colors.dart';

class GroupMemberItem extends StatelessWidget {
  final UserModel member;
  final bool isAdmin;
  final bool isCurrentUser;
  final bool canRemove;
  final bool isCurrentUserAdmin;
  final bool isRemoving;
  final VoidCallback? onRemove;
  final VoidCallback? onGiveAdmin;

  const GroupMemberItem({
    super.key,
    required this.member,
    required this.isAdmin,
    required this.isCurrentUser,
    required this.canRemove,
    required this.isCurrentUserAdmin,
    required this.isRemoving,
    this.onRemove,
    this.onGiveAdmin,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.textSpacing),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: isAdmin ? colorScheme.primary : Colors.transparent, width: isAdmin ? 1 : 0),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Profil resmi veya avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child:
                member.photoUrl == null
                    ? Text(
                      member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                      style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    )
                    : null,
          ),
          const SizedBox(width: 12),
          // Kullanıcı bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  member.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isAdmin) ...[
                      Icon(Icons.shield, size: 14, color: colorScheme.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Admin',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.person, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 4),
                      Text('Üye', style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant)),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // "Sen" badge'i sağda, butonlarla aynı hizada
          if (isCurrentUser) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Sen',
                style: AppTextStyles.bodySmall.copyWith(color: colorScheme.primary, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(width: 4),
          ],
          // Admin yetkisi devret butonu (sadece admin ve kendisi değilse)
          if (isCurrentUserAdmin && !isCurrentUser && !isAdmin)
            IconButton(
              icon: Icon(Icons.more_vert, color: colorScheme.primary, size: 20),
              onPressed: isRemoving ? null : onGiveAdmin,
              tooltip: 'Admin Yetkisi Ver',
            ),
          // Çıkarma butonu
          if (canRemove)
            IconButton(
              icon: Icon(isCurrentUser ? Icons.exit_to_app : Icons.remove_circle_outline, color: AppColors.error),
              onPressed: isRemoving ? null : onRemove,
              tooltip: isCurrentUser ? 'Gruptan Ayrıl' : 'Üyeyi Çıkar',
            ),
        ],
      ),
    );
  }
}
