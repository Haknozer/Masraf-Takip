import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../constants/app_colors.dart';
import '../../constants/app_text_styles.dart';
import '../../constants/app_spacing.dart';
import '../../providers/friend_provider.dart';
import '../../services/firebase_service.dart';
import '../../models/user_model.dart';
import '../../widgets/common/async_value_builder.dart';
import '../../widgets/common/error_snackbar.dart';
import '../../widgets/dialogs/add_friend_dialog.dart';

/// Arkadaşlar sayfası
class FriendsPage extends ConsumerStatefulWidget {
  const FriendsPage({super.key});

  @override
  ConsumerState<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends ConsumerState<FriendsPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: const Text('Arkadaşlar'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Arkadaşlarım', icon: Icon(Icons.people)),
            Tab(text: 'Gelen İstekler', icon: Icon(Icons.person_add)),
            Tab(text: 'Gönderilenler', icon: Icon(Icons.send)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () => AddFriendDialog.show(context),
            tooltip: 'Arkadaş Ekle',
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFriendsList(), _buildFriendRequests(), _buildSentRequests()],
      ),
    );
  }

  /// Arkadaşlar listesi
  Widget _buildFriendsList() {
    final friendsState = ref.watch(userFriendsProvider);

    return AsyncValueBuilder<List<String>>(
      value: friendsState,
      dataBuilder: (context, friendIds) {
        if (friendIds.isEmpty) {
          return _buildEmptyState(
            icon: Icons.people_outline,
            message: 'Henüz arkadaşınız yok',
            description: 'Sağ üstteki + butonuna tıklayarak arkadaş ekleyebilirsiniz',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          itemCount: friendIds.length,
          itemBuilder: (context, index) => _FriendCard(friendId: friendIds[index]),
        );
      },
      loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stack) => _buildErrorState('Arkadaşlar yüklenemedi'),
    );
  }

  /// Gelen arkadaşlık istekleri
  Widget _buildFriendRequests() {
    final requestsState = ref.watch(friendRequestsProvider);

    return AsyncValueBuilder<List<String>>(
      value: requestsState,
      dataBuilder: (context, requesterIds) {
        if (requesterIds.isEmpty) {
          return _buildEmptyState(
            icon: Icons.inbox_outlined,
            message: 'Gelen istek yok',
            description: 'Şu an size gönderilmiş arkadaşlık isteği bulunmuyor',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          itemCount: requesterIds.length,
          itemBuilder: (context, index) => _FriendRequestCard(requesterId: requesterIds[index]),
        );
      },
      loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stack) => _buildErrorState('İstekler yüklenemedi'),
    );
  }

  /// Gönderilen arkadaşlık istekleri
  Widget _buildSentRequests() {
    final sentState = ref.watch(sentFriendRequestsProvider);

    return AsyncValueBuilder<List<String>>(
      value: sentState,
      dataBuilder: (context, receiverIds) {
        if (receiverIds.isEmpty) {
          return _buildEmptyState(
            icon: Icons.send_outlined,
            message: 'Gönderilmiş istek yok',
            description: 'Henüz kimseye arkadaşlık isteği göndermediniz',
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          itemCount: receiverIds.length,
          itemBuilder: (context, index) => _SentRequestCard(receiverId: receiverIds[index]),
        );
      },
      loadingBuilder: (context) => const Center(child: CircularProgressIndicator()),
      errorBuilder: (context, error, stack) => _buildErrorState('İstekler yüklenemedi'),
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message, String? description}) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(message, style: AppTextStyles.h4.copyWith(color: colorScheme.onSurfaceVariant)),
            if (description != null) ...[
              const SizedBox(height: 8),
              Text(
                description,
                style: AppTextStyles.bodySmall.copyWith(color: colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: AppColors.error),
          const SizedBox(height: 16),
          Text(message, style: AppTextStyles.h4.copyWith(color: AppColors.error)),
        ],
      ),
    );
  }
}

/// Arkadaş kartı
class _FriendCard extends ConsumerStatefulWidget {
  final String friendId; // Kullanıcının ID'si

  const _FriendCard({required this.friendId});

  @override
  ConsumerState<_FriendCard> createState() => _FriendCardState();
}

class _FriendCardState extends ConsumerState<_FriendCard> {
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

  Future<void> _removeFriend() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Arkadaşlığı Kaldır'),
            content: Text(
              '${_friendUser?.displayName ?? "Bu kişi"} ile arkadaşlığınızı kaldırmak istediğinize emin misiniz?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('İptal')),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                style: TextButton.styleFrom(foregroundColor: AppColors.error),
                child: const Text('Kaldır'),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(friendNotifierProvider.notifier).removeFriendship(widget.friendId);
        if (mounted) {
          ErrorSnackBar.showSuccess(context, 'Arkadaşlık kaldırıldı');
        }
      } catch (e) {
        if (mounted) {
          ErrorSnackBar.show(context, e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.only(bottom: 12),
        child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_friendUser == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          backgroundImage: _friendUser!.photoUrl != null ? NetworkImage(_friendUser!.photoUrl!) : null,
          child:
              _friendUser!.photoUrl == null
                  ? Text(
                    _friendUser!.displayName[0].toUpperCase(),
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  )
                  : null,
        ),
        title: Text(_friendUser!.displayName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        trailing: IconButton(
          icon: Icon(Icons.person_remove, color: AppColors.error),
          onPressed: _removeFriend,
          tooltip: 'Arkadaşlığı Kaldır',
        ),
      ),
    );
  }
}

/// Gelen istek kartı
class _FriendRequestCard extends ConsumerStatefulWidget {
  final String requesterId; // İstek gönderen kullanıcının ID'si

  const _FriendRequestCard({required this.requesterId});

  @override
  ConsumerState<_FriendRequestCard> createState() => _FriendRequestCardState();
}

class _FriendRequestCardState extends ConsumerState<_FriendRequestCard> {
  UserModel? _requesterUser;
  bool _isLoading = true;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _loadRequesterData();
  }

  Future<void> _loadRequesterData() async {
    try {
      final doc = await FirebaseService.getDocumentSnapshot('users/${widget.requesterId}');
      if (doc.exists && mounted) {
        setState(() {
          _requesterUser = UserModel.fromJson(doc.data() as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _acceptRequest() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(friendNotifierProvider.notifier).acceptFriendRequest(widget.requesterId);
      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'Arkadaşlık isteği kabul edildi');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _rejectRequest() async {
    setState(() => _isProcessing = true);
    try {
      await ref.read(friendNotifierProvider.notifier).removeFriendship(widget.requesterId);
      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'İstek reddedildi');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.only(bottom: 12),
        child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_requesterUser == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          backgroundImage: _requesterUser!.photoUrl != null ? NetworkImage(_requesterUser!.photoUrl!) : null,
          child:
              _requesterUser!.photoUrl == null
                  ? Text(
                    _requesterUser!.displayName[0].toUpperCase(),
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  )
                  : null,
        ),
        title: Text(_requesterUser!.displayName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        trailing:
            _isProcessing
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2))
                : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.check, color: AppColors.success),
                      onPressed: _acceptRequest,
                      tooltip: 'Kabul Et',
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: AppColors.error),
                      onPressed: _rejectRequest,
                      tooltip: 'Reddet',
                    ),
                  ],
                ),
      ),
    );
  }
}

/// Gönderilen istek kartı
class _SentRequestCard extends ConsumerStatefulWidget {
  final String receiverId; // İstek gönderilen kullanıcının ID'si

  const _SentRequestCard({required this.receiverId});

  @override
  ConsumerState<_SentRequestCard> createState() => _SentRequestCardState();
}

class _SentRequestCardState extends ConsumerState<_SentRequestCard> {
  UserModel? _receiverUser;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReceiverData();
  }

  Future<void> _loadReceiverData() async {
    try {
      final doc = await FirebaseService.getDocumentSnapshot('users/${widget.receiverId}');
      if (doc.exists && mounted) {
        setState(() {
          _receiverUser = UserModel.fromJson(doc.data() as Map<String, dynamic>);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _cancelRequest() async {
    try {
      await ref.read(friendNotifierProvider.notifier).removeFriendship(widget.receiverId);
      if (mounted) {
        ErrorSnackBar.showSuccess(context, 'İstek iptal edildi');
      }
    } catch (e) {
      if (mounted) {
        ErrorSnackBar.show(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_isLoading) {
      return const Card(
        margin: EdgeInsets.only(bottom: 12),
        child: Padding(padding: EdgeInsets.all(16), child: Center(child: CircularProgressIndicator())),
      );
    }

    if (_receiverUser == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: colorScheme.primary.withValues(alpha: 0.15),
          backgroundImage: _receiverUser!.photoUrl != null ? NetworkImage(_receiverUser!.photoUrl!) : null,
          child:
              _receiverUser!.photoUrl == null
                  ? Text(
                    _receiverUser!.displayName[0].toUpperCase(),
                    style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
                  )
                  : null,
        ),
        title: Text(_receiverUser!.displayName, style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600)),
        subtitle: Text(
          'Beklemede',
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.warning, fontWeight: FontWeight.w600),
        ),
        trailing: IconButton(
          icon: Icon(Icons.cancel_outlined, color: AppColors.error),
          onPressed: _cancelRequest,
          tooltip: 'İptal Et',
        ),
      ),
    );
  }
}
