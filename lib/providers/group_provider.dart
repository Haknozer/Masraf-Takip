import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/group_model.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

// User Groups Provider
final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseService.listenToCollection('groups').map(
    (snapshot) =>
        snapshot.docs
            .where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['memberIds']?.contains(user.uid) == true;
            })
            .map((doc) => GroupModel.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
            .toList(),
  );
});

// Group Notifier
class GroupNotifier extends StateNotifier<AsyncValue<List<GroupModel>>> {
  GroupNotifier(this.ref) : super(const AsyncValue.loading()) {
    _loadGroups();
  }

  final Ref ref;

  void _loadGroups() {
    final user = ref.read(currentUserProvider);
    if (user == null) {
      state = const AsyncValue.data([]);
      return;
    }

    FirebaseService.listenToCollection('groups').listen((snapshot) {
      final groups =
          snapshot.docs
              .where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return data['memberIds']?.contains(user.uid) == true;
              })
              .map((doc) => GroupModel.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>}))
              .toList();
      state = AsyncValue.data(groups);
    });
  }

  // Grup oluştur
  Future<void> createGroup(String name, String description) async {
    final user = ref.read(currentUserProvider);
    if (user == null) return;

    try {
      final group = GroupModel(
        id: '', // Firebase otomatik ID verecek
        name: name,
        description: description,
        createdBy: user.uid,
        memberIds: [user.uid],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.addDocument(collection: 'groups', data: group.toJson());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Gruba üye ekle
  Future<void> addMember(String groupId, String userId) async {
    try {
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) return;

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      final updatedGroup = group.addMember(userId);
      await FirebaseService.updateDocument(path: 'groups/$groupId', data: updatedGroup.toJson());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Gruptan üye çıkar
  Future<void> removeMember(String groupId, String userId) async {
    try {
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) return;

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      final updatedGroup = group.removeMember(userId);
      await FirebaseService.updateDocument(path: 'groups/$groupId', data: updatedGroup.toJson());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Grup güncelle
  Future<void> updateGroup(String groupId, String name, String description) async {
    try {
      await FirebaseService.updateDocument(
        path: 'groups/$groupId',
        data: {'name': name, 'description': description, 'updatedAt': DateTime.now().toIso8601String()},
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Grup sil
  Future<void> deleteGroup(String groupId) async {
    try {
      await FirebaseService.deleteDocument('groups/$groupId');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Group Notifier Provider
final groupNotifierProvider = StateNotifierProvider<GroupNotifier, AsyncValue<List<GroupModel>>>((ref) {
  return GroupNotifier(ref);
});
