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
import '../../widgets/dialogs/add_member_dialog.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  List<UserModel> _blockedMembers = [];
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
      // Engellenen kullanıcıları da yükle
      final blocked = <UserModel>[];
      for (final userId in widget.group.blockedUserIds) {
        try {
          final doc = await FirebaseService.getDocumentSnapshot('users/$userId');
          if (doc.exists) {
            blocked.add(UserModel.fromJson(doc.data() as Map<String, dynamic>));
          }
        } catch (_) {
          continue;
        }
      }
      if (mounted) {
        setState(() {
          _members = members;
          _blockedMembers = blocked;
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
    final isMember = currentUser != null && widget.group.isGroupMember(currentUser.uid);

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
                if (isMember)
                  IconButton(
                    onPressed: () {
                      showDialog(context: context, builder: (context) => AddMemberDialog(group: widget.group));
                    },
                    icon: Icon(Icons.person_add, color: colorScheme.primary),
                    tooltip: 'Üye Ekle',
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
            else ...[
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
              if (isCurrentUserAdmin && _blockedMembers.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sectionMargin),
                Text(
                  'Engellenenler (${_blockedMembers.length})',
                  style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: AppSpacing.textSpacing),
                ..._blockedMembers.map((user) => _buildBlockedItem(user)),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBlockedItem(UserModel user) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.textSpacing),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
            backgroundImage: user.photoUrl != null ? NetworkImage(user.photoUrl!) : null,
            child:
                user.photoUrl == null
                    ? Text(
                      user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?',
                      style: AppTextStyles.bodySmall.copyWith(color: colorScheme.primary, fontWeight: FontWeight.bold),
                    )
                    : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              user.displayName,
              style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () async {
              try {
                await FirebaseService.updateDocument(
                  path: 'groups/${widget.group.id}',
                  data: {
                    'blockedUserIds': FieldValue.arrayRemove([user.id]),
                    'updatedAt': DateTime.now().toIso8601String(),
                  },
                );
                if (mounted) {
                  ErrorSnackBar.showSuccess(context, '${user.displayName} engellenenlerden kaldırıldı.');
                  _loadMembers();
                }
              } catch (e) {
                if (mounted) {
                  ErrorSnackBar.show(context, e);
                }
              }
            },
            child: const Text('Engeli Kaldır'),
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

      // Eğer kullanıcı kendi isteğiyle ayrılıyorsa, onay + grubu engelle seçeneği sor
      bool shouldBlockGroup = false;
      if (isCurrentUser) {
        if (!mounted) return;
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) {
            bool localBlock = false;
            return StatefulBuilder(
              builder: (context, setStateDialog) {
                return AlertDialog(
                  title: const Text('Gruptan Ayrıl'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Bu gruptan ayrılmak istediğinize emin misiniz?'),
                      const SizedBox(height: AppSpacing.textSpacing),
                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Bu grubu engelle (tekrar eklenemesin)'),
                        value: localBlock,
                        onChanged: (value) {
                          setStateDialog(() {
                            localBlock = value ?? false;
                          });
                        },
                      ),
                    ],
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Vazgeç')),
                    TextButton(
                      onPressed: () {
                        shouldBlockGroup = localBlock;
                        Navigator.of(dialogContext).pop(true);
                      },
                      child: const Text('Ayrıl'),
                    ),
                  ],
                );
              },
            );
          },
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
      // Eğer kendisi çıkıyorsa blockAfterRemove = false (grup tarafından engellenmez),
      // admin birini atıyorsa blockAfterRemove = true (grup tarafından engellenir)
      final blockAfterRemove = !isCurrentUser;
      await RemoveMemberController.removeMemberFromGroup(
        ref,
        widget.group.id,
        member.id,
        blockAfterRemove: blockAfterRemove,
      );

      if (mounted) {
        if (isCurrentUser) {
          ErrorSnackBar.showSuccess(context, 'Gruptan ayrıldınız');

          // Kullanıcı kendi isteğiyle ayrıldı ve grubu engellemek istiyorsa,
          // kullanıcı dokümanına blockedGroupIds olarak ekle
          if (shouldBlockGroup) {
            try {
              final userDocSnapshot =
                  await FirebaseService.firestore.collection('users').where('id', isEqualTo: member.id).limit(1).get();

              if (userDocSnapshot.docs.isNotEmpty) {
                final userDocId = userDocSnapshot.docs.first.id;
                await FirebaseService.updateDocument(
                  path: 'users/$userDocId',
                  data: {
                    'blockedGroupIds': FieldValue.arrayUnion([widget.group.id]),
                    'updatedAt': DateTime.now().toIso8601String(),
                  },
                );
              }
            } catch (_) {
              // Engelleme yazılamasa da ayrılma işlemi başarılı kabul edilir.
            }
          }

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
