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
import '../../widgets/dialogs/transfer_admin_dialog.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../providers/auth_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/firebase_service.dart';

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

    final colorScheme = Theme.of(context).colorScheme;

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
                    Icon(Icons.people, color: colorScheme.primary, size: 24),
                    const SizedBox(width: 8),
                    Text(
                      'Üyeler (${_members.length})',
                      style: AppTextStyles.h3.copyWith(color: colorScheme.onSurface),
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
                    style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ),
              )
            else
              ..._members.map((member) => _buildMemberItem(context, member, isAdmin, currentUser?.uid)),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberItem(BuildContext context, UserModel member, bool isCurrentUserAdmin, String? currentUserId) {
    final isAdmin = GroupMembersController.isAdmin(widget.group, member.id);
    final isCurrentUser = currentUserId == member.id;
    // Admin başkalarını çıkarabilir, kullanıcı kendini çıkarabilir
    final canRemove = (isCurrentUserAdmin && !isCurrentUser) || isCurrentUser;
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.textSpacing),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.4),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isAdmin ? colorScheme.primary : Colors.transparent,
          width: isAdmin ? 1 : 0,
        ),
      ),
      child: Row(
        children: [
          // Profil resmi veya avatar
          CircleAvatar(
            radius: 20,
            backgroundColor: colorScheme.primary.withOpacity(0.15),
            backgroundImage: member.photoUrl != null ? NetworkImage(member.photoUrl!) : null,
            child: member.photoUrl == null
                ? Text(
                    member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: colorScheme.primary,
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
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isCurrentUser) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: colorScheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Sen',
                          style: AppTextStyles.bodySmall.copyWith(
                            color: colorScheme.primary,
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
                      Text(
                        'Üye',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          // Admin yetkisi devret butonu (sadece admin ve kendisi değilse)
          if (isCurrentUserAdmin && !isCurrentUser && !isAdmin)
            IconButton(
              icon: Icon(
                Icons.more_vert,
                color: colorScheme.primary,
                size: 20,
              ),
              onPressed: _isRemoving ? null : () => _giveAdminRole(member),
              tooltip: 'Admin Yetkisi Ver',
            ),
          // Çıkarma butonu
          if (canRemove)
            IconButton(
              icon: Icon(
                isCurrentUser ? Icons.exit_to_app : Icons.remove_circle_outline,
                color: AppColors.error,
              ),
              onPressed: _isRemoving ? null : () => _removeMember(member),
              tooltip: isCurrentUser ? 'Gruptan Ayrıl' : 'Üyeyi Çıkar',
            ),
        ],
      ),
    );
  }

  Future<void> _removeMember(UserModel member) async {
    final currentUser = ref.read(currentUserProvider);
    final isCurrentUser = currentUser?.uid == member.id;

    // Borçları kontrol et
    try {
      final debts = await RemoveMemberController.checkMemberDebts(
        ref,
        widget.group.id,
        member.id,
      );

      // Eğer kullanıcı kendini çıkarıyorsa ve borcu varsa engelle
      if (isCurrentUser && debts.isNotEmpty) {
        if (mounted) {
          ErrorSnackBar.show(
            context,
            'Gruptan ayrılamazsınız. Önce ${debts.length} borcunuzu ödemeniz gerekiyor.',
          );
        }
        return;
      }

      // Eğer başkasını çıkarıyorsa ve borç varsa onay dialogu göster
      if (!isCurrentUser && debts.isNotEmpty) {
        final confirmed = await RemoveMemberDialog.show(
          context,
          member: member,
          debts: debts,
        );

        if (confirmed != true) return;
      }

      setState(() => _isRemoving = true);

      // Eğer admin ayrılıyorsa ve başka admin yoksa, yetki devri yapılacak
      final isLeavingAdmin = GroupMembersController.isAdmin(widget.group, member.id);
      final remainingMembers = widget.group.memberIds.where((id) => id != member.id).toList();
      final hasOtherAdmin = remainingMembers.any((id) => GroupMembersController.isAdmin(widget.group, id));
      String? newAdminName;

      if (isLeavingAdmin && !hasOtherAdmin && remainingMembers.isNotEmpty) {
        // Yeni admin'in adını al
        try {
          final newAdminId = remainingMembers.first;
          final newAdminDoc = await FirebaseService.getDocumentSnapshot('users/$newAdminId');
          if (newAdminDoc.exists) {
            final newAdminData = newAdminDoc.data() as Map<String, dynamic>;
            newAdminName = newAdminData['displayName'] as String?;
          }
        } catch (e) {
          // Hata durumunda devam et
        }
      }

      // Üyeyi çıkar
      await RemoveMemberController.removeMemberFromGroup(
        ref,
        widget.group.id,
        member.id,
      );

      if (mounted) {
        if (isCurrentUser) {
          ErrorSnackBar.showSuccess(context, 'Gruptan ayrıldınız');
          // Ana sayfaya dön
          Navigator.pop(context);
        } else {
          if (isLeavingAdmin && newAdminName != null) {
            ErrorSnackBar.showSuccess(
              context,
              '${member.displayName} gruptan çıkarıldı. Admin yetkisi $newAdminName\'e devredildi.',
            );
          } else {
            ErrorSnackBar.showSuccess(context, '${member.displayName} gruptan çıkarıldı');
          }
          // Üye listesini yenile
          _loadMembers();
        }
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(
          context,
          isCurrentUser ? 'Gruptan ayrılamadınız: $e' : 'Üye çıkarılamadı: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }

  Future<void> _giveAdminRole(UserModel member) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) return;

    // Onay dialogu göster
    final confirmed = await TransferAdminDialog.show(
      context,
      member: member,
    );

    if (confirmed != true) return;

    setState(() => _isRemoving = true);

    try {
      // Üyeye admin yetkisi ver (kendi adminliğimiz korunur)
      await ref.read(groupNotifierProvider.notifier).updateUserRole(
            widget.group.id,
            member.id,
            'admin',
          );

      if (mounted) {
        ErrorSnackBar.showSuccess(
          context,
          '${member.displayName}\'e admin yetkisi verildi',
        );
        // Üye listesini yenile
        _loadMembers();
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, 'Admin yetkisi verilemedi: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isRemoving = false);
      }
    }
  }
}

