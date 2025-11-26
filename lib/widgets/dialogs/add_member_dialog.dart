import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../models/group_model.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/friend_provider.dart';
import '../../providers/group_provider.dart';
import '../../services/firebase_service.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/common/tab_button_widget.dart';
import '../../widgets/forms/custom_button.dart';
import 'add_member/add_member_qr_tab.dart';
import 'add_member/add_member_link_tab.dart';
import 'add_member/add_member_code_tab.dart';

class AddMemberDialog extends ConsumerStatefulWidget {
  final GroupModel group;

  const AddMemberDialog({super.key, required this.group});

  @override
  ConsumerState<AddMemberDialog> createState() => _AddMemberDialogState();
}

class _AddMemberDialogState extends ConsumerState<AddMemberDialog> {
  int _selectedTab = 0; // 0: QR, 1: Link, 2: Kod, 3: Arkadaş

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final isCurrentUserAdmin =
        currentUser != null && widget.group.isGroupAdmin(currentUser.uid);
    // Grup kapalıysa uyarı göster
    if (!widget.group.isActive) {
      return Dialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sectionPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.lock_outline, color: AppColors.warning, size: 48),
              const SizedBox(height: 16),
              Text('Grup Kapalı', style: AppTextStyles.h3),
              const SizedBox(height: 8),
              Text(
                'Grup kapalı olduğu için yeni üye eklenemez.',
                style: AppTextStyles.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              CustomButton(text: 'Tamam', onPressed: () => Navigator.pop(context)),
            ],
          ),
        ),
      );
    }

    return Dialog(
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sectionPadding),
        constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Başlık
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Üye Ekle', style: AppTextStyles.h2),
                  IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                ],
              ),
              const SizedBox(height: AppSpacing.sectionMargin),

              // Tab Bar
              _buildTabBar(isCurrentUserAdmin),

              const SizedBox(height: AppSpacing.sectionMargin),

              // Tab Content
              _buildTabContent(isCurrentUserAdmin),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isCurrentUserAdmin) {
    return Row(
      children: [
        Expanded(
          child: TabButtonWidget(
            label: 'QR',
            icon: Icons.qr_code,
            isSelected: _selectedTab == 0,
            onTap: () => setState(() => _selectedTab = 0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TabButtonWidget(
            label: 'Link',
            icon: Icons.link,
            isSelected: _selectedTab == 1,
            onTap: () => setState(() => _selectedTab = 1),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TabButtonWidget(
            label: 'Kod',
            icon: Icons.code,
            isSelected: _selectedTab == 2,
            onTap: () => setState(() => _selectedTab = 2),
          ),
        ),
        if (isCurrentUserAdmin) ...[
          const SizedBox(width: 8),
          Expanded(
            child: TabButtonWidget(
            label: 'Ark.',
              icon: Icons.person_add_alt_1,
              isSelected: _selectedTab == 3,
              onTap: () => setState(() => _selectedTab = 3),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTabContent(bool isCurrentUserAdmin) {
    switch (_selectedTab) {
      case 0:
        return AddMemberQrTab(inviteCode: widget.group.inviteCode);
      case 1:
        return AddMemberLinkTab(inviteCode: widget.group.inviteCode);
      case 2:
        return AddMemberCodeTab(
          inviteCode: widget.group.inviteCode,
          inviteCodeExpiresAt: widget.group.inviteCodeExpiresAt,
        );
      case 3:
        if (!isCurrentUserAdmin) return const SizedBox.shrink();
        return _AddMemberFriendsTab(group: widget.group);
      default:
        return const SizedBox.shrink();
    }
  }
}

/// Arkadaşlardan gruba üye ekleme tab'ı (sadece admin)
class _AddMemberFriendsTab extends ConsumerWidget {
  final GroupModel group;

  const _AddMemberFriendsTab({required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendIdsAsync = ref.watch(userFriendsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return friendIdsAsync.when(
      data: (friendIds) {
        // Zaten grupta olan veya engellenmiş olanları filtrele
        final filteredIds = friendIds
            .where((id) => !group.memberIds.contains(id) && !group.isUserBlocked(id))
            .toList();

        if (filteredIds.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(AppSpacing.sectionPadding),
            child: Text(
              'Gruba ekleyebileceğiniz uygun arkadaş bulunamadı.',
              style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Arkadaşlarınızdan bu gruba üye ekleyin',
              style: AppTextStyles.bodyMedium.copyWith(color: colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: AppSpacing.sectionMargin),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: filteredIds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final friendId = filteredIds[index];
                return _FriendToAddListItem(groupId: group.id, friendId: friendId);
              },
            ),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Padding(
        padding: const EdgeInsets.all(AppSpacing.sectionPadding),
        child: Text(
          'Arkadaşlar yüklenemedi: $error',
          style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error),
        ),
      ),
    );
  }
}

/// Arkadaşı gruba ekleme satırı
class _FriendToAddListItem extends ConsumerStatefulWidget {
  final String groupId;
  final String friendId;

  const _FriendToAddListItem({required this.groupId, required this.friendId});

  @override
  ConsumerState<_FriendToAddListItem> createState() => _FriendToAddListItemState();
}

class _FriendToAddListItemState extends ConsumerState<_FriendToAddListItem> {
  UserModel? _friendUser;
  bool _isLoading = true;
  bool _isAdding = false;

  @override
  void initState() {
    super.initState();
    _loadFriend();
  }

  Future<void> _loadFriend() async {
    try {
      final doc = await FirebaseService.getDocumentSnapshot('users/${widget.friendId}');
      if (doc.exists && mounted) {
        setState(() {
          _friendUser = UserModel.fromJson(doc.data() as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addToGroup() async {
    if (_friendUser == null) return;
    setState(() => _isAdding = true);
    try {
      await ref.read(groupNotifierProvider.notifier).addMember(widget.groupId, widget.friendId);
      if (mounted) {
        ErrorSnackBar.showSuccess(context, '${_friendUser!.displayName} gruba eklendi.');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isAdding = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return ListTile(
        leading: CircleAvatar(backgroundColor: colorScheme.surfaceContainerHighest),
        title: Container(
          height: 12,
          width: 80,
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      );
    }

    if (_friendUser == null) return const SizedBox.shrink();

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
        backgroundImage: _friendUser!.photoUrl != null ? NetworkImage(_friendUser!.photoUrl!) : null,
        child: _friendUser!.photoUrl == null
            ? Text(
                _friendUser!.displayName[0].toUpperCase(),
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              )
            : null,
      ),
      title: Text(
        _friendUser!.displayName,
        style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
      ),
      trailing: ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 64),
        child: ElevatedButton(
          onPressed: _isAdding ? null : _addToGroup,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            minimumSize: const Size(64, 32),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
            textStyle: AppTextStyles.bodySmall,
          ),
          child: _isAdding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Ekle'),
        ),
      ),
    );
  }
}
