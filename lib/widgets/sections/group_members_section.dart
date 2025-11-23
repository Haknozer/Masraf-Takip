import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../controllers/group_members_controller.dart';
import '../../controllers/remove_member_controller.dart';
import '../../widgets/dialogs/remove_member_dialog.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../providers/auth_provider.dart';

/// Grup üyeleri listesi section'ı
class GroupMembersSection extends ConsumerStatefulWidget {
  final GroupModel group;

  const GroupMembersSection({super.key, required this.group});

  @override
  ConsumerState<GroupMembersSection> createState() => _GroupMembersSectionState();
}

class _GroupMembersSectionState extends ConsumerState<GroupMembersSection> {
  List<UserModel> _members = [];
  bool _isLoading = true;
  bool _isRemoving = false;

  @override
  void initState() {
    super.initState();
    _loadMembers();
  }

  Future<void> _loadMembers() async {
    setState(() => _isLoading = true);
    try {
      final members = await GroupMembersController.getGroupMembers(widget.group);
      if (mounted) {
        setState(() {
          _members = members;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isAdmin = currentUser != null && GroupMembersController.isAdmin(widget.group, currentUser.uid);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.people, color: AppColors.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Üyeler (${_members.length})',
                      style: AppTextStyles.h3,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(AppSpacing.sectionMargin),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_members.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sectionMargin),
                  child: Text(
                    'Grupta henüz üye yok',
                    style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                  ),
                ),
              )
            else
              ..._members.map((member) => _buildMemberItem(member, isAdmin, currentUser?.uid)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(UserModel member, bool isCurrentUserAdmin, String? currentUserId) {
    final isAdmin = GroupMembersController.isAdmin(widget.group, member.id);
    final isCurrentUser = currentUserId == member.id;
    final canRemove = isCurrentUserAdmin && !isCurrentUser;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.textSpacing),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.greyLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdmin ? AppColors.primary : AppColors.greyLight,
          width: isAdmin ? 1 : 0,
        ),
      ),
      child: Row(
        children: [
          // Profil resmi veya avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.1),
            backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child: member.photoUrl == null
                ? Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Kullanıcı bilgileri
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member.displayName,
                        style: AppTextStyles.bodyMedium.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Sen',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (isAdmin) ...[
                      Icon(Icons.shield, size: 14, color: AppColors.primary),
                      const SizedBox(width: 4),
                      Text(
                        'Admin',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ] else ...[
                      Icon(Icons.person, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Üye',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Çıkarma butonu (sadece admin ve kendisi değilse)
          if (canRemove)
            IconButton(
              icon: Icon(Icons.remove_circle_outline, color: AppColors.error),
              onPressed: _isRemoving ? null : () => _removeMember(member),
              tooltip: 'Üyeyi Çıkar',
            ),
        ],
      ),
    );
  }

  Future<void> _removeMember(UserModel member) async {
    // Borçları kontrol et
    try {
      final debts = await RemoveMemberController.checkMemberDebts(
        ref,
        widget.group.id,
        member.id,
      );

      // Eğer borç varsa onay dialogu göster
      if (debts.isNotEmpty) {
        final confirmed = await RemoveMemberDialog.show(
          context,
          member: member,
          debts: debts,
        );

        if (confirmed != true) return;
      }

      setState(() => _isRemoving = true);

      // Üyeyi çıkar
      await RemoveMemberController.removeMemberFromGroup(
        ref,
        widget.group.id,
        member.id,
      );

      if (mounted) {
        ErrorSnackBar.showSuccess(context, '${member.displayName} gruptan çıkarıldı');
        // Üye listesini yenile
        _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Üye çıkarılamadı: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }
}

