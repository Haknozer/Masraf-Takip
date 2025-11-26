import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../providers/friend_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../screens/friends/friends_page.dart';

/// Arkadaşlar bölümü (Home sayfasında)
class FriendsSection extends ConsumerWidget {
  const FriendsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsState = ref.watch(userFriendsProvider);

    return Column(
      children: [
        _FriendsSectionHeader(),
        const SizedBox(height: AppSpacing.textSpacing),
        friendsState.when(
          data: (friends) {
            if (friends.isEmpty) {
              return _EmptyFriendsCard();
            }
            // İlk 3 arkadaşı göster (ID listesi)
            final displayFriends = friends.take(3).toList();
            return Column(children: displayFriends.map((friendId) => _FriendListItem(friendId: friendId)).toList());
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => _ErrorCard(message: 'Arkadaşlar yüklenemedi'),
        ),
      ],
    );
  }
}

/// Arkadaşlar bölümü başlığı
class _FriendsSectionHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(Icons.people, size: 24, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text('Arkadaşlarım', style: AppTextStyles.h3),
          ],
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsPage()));
          },
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Tümü'),
        ),
      ],
    );
  }
}

/// Arkadaş liste öğesi (kompakt)
class _FriendListItem extends ConsumerStatefulWidget {
  final String friendId; // Kullanıcı ID'si

  const _FriendListItem({required this.friendId});

  @override
  ConsumerState<_FriendListItem> createState() => _FriendListItemState();
}

class _FriendListItemState extends ConsumerState<_FriendListItem> {
  UserModel? _friendUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFriendData();
  }

  Future<void> _loadFriendData() async {
    final friendId = widget.friendId;

    try {
      final doc = await FirebaseService.getDocumentSnapshot('users/$friendId');
      if (doc.exists && mounted) {
        setState(() {
          _friendUser = UserModel.fromJson(doc.data() as Map<String, dynamic>);
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
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(radius: 20, backgroundColor: colorScheme.surfaceContainerHighest),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 100,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 10,
                      width: 150,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_friendUser == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsPage()));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
                backgroundImage: _friendUser!.photoUrl != null ? NetworkImage(_friendUser!.photoUrl!) : null,
                child:
                    _friendUser!.photoUrl == null
                        ? Text(
                          _friendUser!.displayName[0].toUpperCase(),
                          style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold, fontSize: 16),
                        )
                        : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _friendUser!.displayName,
                  style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

/// Boş arkadaşlar kartı
class _EmptyFriendsCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: InkWell(
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FriendsPage()));
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Icon(Icons.people_outline, size: 48, color: colorScheme.onSurfaceVariant),
              const SizedBox(height: 12),
              Text(
                'Henüz arkadaşınız yok',
                style: AppTextStyles.bodyMedium.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Arkadaş eklemek için tıklayın',
                style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hata kartı
class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.error),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: AppTextStyles.bodyMedium.copyWith(color: AppColors.error))),
          ],
        ),
      ),
    );
  }
}
