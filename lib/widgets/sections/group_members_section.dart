import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
import 'group_members/group_member_item.dart';

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
    final isCurrentUserAdmin = currentUser != null && GroupMembersController.isAdmin(widget.group, currentUser.uid);

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
                    Text('Üyeler (${_members.length})', style: AppTextStyles.h3.copyWith(color: colorScheme.onSurface)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            if (_isLoading)
              const Center(
                child: Padding(padding: EdgeInsets.all(AppSpacing.sectionMargin), child: CircularProgressIndicator()),
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
              ..._members.map(
                (member) => GroupMemberItem(
                  member: member,
                  isAdmin: GroupMembersController.isAdmin(widget.group, member.id),
                  isCurrentUser: currentUser?.uid == member.id,
                  canRemove: (isCurrentUserAdmin && currentUser.uid != member.id) || currentUser?.uid == member.id,
                  isCurrentUserAdmin: isCurrentUserAdmin,
                  isRemoving: _isRemoving,
                  onRemove: () => _removeMember(member),
                  onGiveAdmin: () => _giveAdminRole(member),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(UserModel member) async {
    final currentUser = ref.read(currentUserProvider);
    final isCurrentUser = currentUser?.uid == member.id;

    // Borçları kontrol et
    try {
      final debts = await RemoveMemberController.checkMemberDebts(ref, widget.group.id, member.id);

      // Eğer kullanıcı kendini çıkarıyorsa ve borcu varsa engelle
      if (isCurrentUser && debts.isNotEmpty) {
        if (mounted) {
          ErrorSnackBar.show(context, 'Gruptan ayrılamazsınız. Önce ${debts.length} borcunuzu ödemeniz gerekiyor.');
        }
        return;
      }

      // Eğer başkasını çıkarıyorsa ve borç varsa onay dialogu göster
      if (!isCurrentUser && debts.isNotEmpty) {
        if (!mounted) return;
        final confirmed = await RemoveMemberDialog.show(context, member: member, debts: debts);

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
      await RemoveMemberController.removeMemberFromGroup(ref, widget.group.id, member.id);

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
        ErrorSnackBar.show(context, isCurrentUser ? 'Gruptan ayrılamadınız: $e' : 'Üye çıkarılamadı: $e');
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
    if (!mounted) return;
    final confirmed = await TransferAdminDialog.show(context, member: member);

    if (confirmed != true) return;

    setState(() => _isRemoving = true);

    try {
      // Üyeye admin yetkisi ver (kendi adminliğimiz korunur)
      await ref.read(groupNotifierProvider.notifier).updateUserRole(widget.group.id, member.id, 'admin');

      if (mounted) {
        ErrorSnackBar.showSuccess(context, '${member.displayName}\'e admin yetkisi verildi');
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
