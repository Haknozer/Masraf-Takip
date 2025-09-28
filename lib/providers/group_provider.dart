import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Bu satırı ekleyin
import '../models/group_model.dart';
import '../services/firebase_service.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/permission_middleware.dart';
import '../exceptions/middleware_exceptions.dart';
import 'auth_provider.dart';

// Kullanıcının gruplarını getir
final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  return FirebaseService.listenToDocument('users/${user.uid}').asyncMap((snapshot) async {
    if (!snapshot.exists) return <GroupModel>[];

    final userData = snapshot.data() as Map<String, dynamic>;
    final groupIds = List<String>.from(userData['groups'] ?? []);

    if (groupIds.isEmpty) return <GroupModel>[];

    // Her grup ID'si için grup bilgilerini getir
    final groups = await Future.wait(
      groupIds.map((groupId) async {
        try {
          final doc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
          if (doc.exists) {
            return GroupModel.fromJson({'id': doc.id, ...doc.data() as Map<String, dynamic>});
          }
          return null;
        } catch (e) {
          return null;
        }
      }),
    );

    return groups.where((g) => g != null).cast<GroupModel>().toList();
  });
});

// Kullanıcının doküman ID'sini al
final userDocumentIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    // Users koleksiyonundan kullanıcının dokümanını bul
    final snapshot =
        await FirebaseService.firestore.collection('users').where('id', isEqualTo: user.uid).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id; // Doküman ID'sini döndür
    }
    return null;
  } catch (e) {
    return null;
  }
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

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      // Kullanıcının doküman ID'sini al
      final userDocId = await ref.read(userDocumentIdProvider.future);
      if (userDocId == null) {
        throw Exception('Kullanıcı dokümanı bulunamadı');
      }

      final group = GroupModel(
        id: '', // Firebase otomatik ID verecek
        name: name,
        description: description,
        createdBy: user!.uid,
        memberIds: [user.uid],
        memberRoles: {user.uid: 'admin'}, // Grup oluşturan otomatik admin olur
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Grubu oluştur
      final docRef = await FirebaseService.addDocument(collection: 'groups', data: group.toJson());

      // Kullanıcının groups array'ine ekle
      await FirebaseService.updateDocument(
        path: 'users/$userDocId', // Doküman ID'sini kullan
        data: {
          'groups': FieldValue.arrayUnion([docRef.id]),
          'updatedAt': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Gruba üye ekle
  Future<void> addMember(String groupId, String userId, {String role = 'user'}) async {
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanAddMember(user, group);

      final updatedGroup = group.addMember(userId, role: role);
      await FirebaseService.updateDocument(path: 'groups/$groupId', data: updatedGroup.toJson());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Gruptan üye çıkar
  Future<void> removeMember(String groupId, String userId) async {
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanRemoveMember(user, group, userId);

      final updatedGroup = group.removeMember(userId);
      await FirebaseService.updateDocument(path: 'groups/$groupId', data: updatedGroup.toJson());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Grup güncelle
  Future<void> updateGroup(String groupId, String name, String description) async {
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanEditGroup(user, group);

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
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanDeleteGroup(user, group);

      await FirebaseService.deleteDocument('groups/$groupId');
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Kullanıcının rolünü güncelle
  Future<void> updateUserRole(String groupId, String userId, String newRole) async {
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final group = GroupModel.fromJson({'id': groupDoc.id, ...groupDoc.data() as Map<String, dynamic>});

      // Middleware: Permission kontrolü (sadece admin rol güncelleyebilir)
      PermissionMiddleware.requireGroupAdmin(user, group);

      final updatedMemberRoles = {...group.memberRoles, userId: newRole};
      final updatedGroup = group.copyWith(memberRoles: updatedMemberRoles, updatedAt: DateTime.now());

      await FirebaseService.updateDocument(path: 'groups/$groupId', data: updatedGroup.toJson());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Kullanıcının gruptaki rolünü al
  String getUserRole(String groupId, String userId) {
    final groups = state.value ?? [];
    final group = groups.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
    return group.getUserRole(userId);
  }

  // Kullanıcı grup admin'i mi?
  bool isGroupAdmin(String groupId, String userId) {
    final groups = state.value ?? [];
    final group = groups.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
    return group.isGroupAdmin(userId);
  }
}

// Group Notifier Provider
final groupNotifierProvider = StateNotifierProvider<GroupNotifier, AsyncValue<List<GroupModel>>>((ref) {
  return GroupNotifier(ref);
});

final groupProvider = Provider.family<AsyncValue<GroupModel?>, String>((ref, groupId) {
  return ref
      .watch(groupNotifierProvider)
      .when(
        data: (groups) {
          try {
            final group = groups.firstWhere((g) => g.id == groupId);
            return AsyncValue.data(group);
          } catch (e) {
            return const AsyncValue.data(null);
          }
        },
        loading: () => const AsyncValue.loading(),
        error: (error, stack) => AsyncValue.error(error, stack),
      );
});
