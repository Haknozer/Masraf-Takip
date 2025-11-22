import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // Bu satırı ekleyin
import '../models/group_model.dart';
import '../services/firebase_service.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/permission_middleware.dart';
import '../exceptions/middleware_exceptions.dart';
import 'auth_provider.dart';

// Kullanıcının gruplarını getir - groups koleksiyonunu dinle (real-time güncelleme için)
final userGroupsProvider = StreamProvider<List<GroupModel>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  // Groups koleksiyonunu direkt dinle ve kullanıcının üyesi olduğu grupları filtrele
  // Bu sayede grup güncellemeleri anında yansır
  return FirebaseService.listenToCollection('groups').map((snapshot) {
    return snapshot.docs
        .where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // Kullanıcı üye olmalı
          return (data['memberIds'] as List?)?.contains(user.uid) == true;
        })
        .map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          // doc.id'yi kullan, doc.data() içindeki id'yi override et
          return GroupModel.fromJson({...data, 'id': doc.id});
        })
        .toList();
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
              .map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                // doc.id'yi kullan, doc.data() içindeki id'yi override et
                return GroupModel.fromJson({...data, 'id': doc.id});
              })
              .toList();
      state = AsyncValue.data(groups);
    });
  }

  // Grup oluştur
  Future<void> createGroup(String name, String description, {String? imageUrl}) async {
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
        imageUrl: imageUrl,
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

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final group = GroupModel.fromJson({...groupData, 'id': groupDoc.id});

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

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final group = GroupModel.fromJson({...groupData, 'id': groupDoc.id});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanRemoveMember(user, group, userId);

      final updatedGroup = group.removeMember(userId);
      await FirebaseService.updateDocument(path: 'groups/$groupId', data: updatedGroup.toJson());
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Grup güncelle
  Future<void> updateGroup(String groupId, String name, String description, {String? imageUrl}) async {
    final user = ref.read(currentUserProvider);

    // Middleware: Authentication kontrolü
    AuthMiddleware.requireAuth(user);

    try {
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
      if (!groupDoc.exists) {
        throw const NotFoundException('Grup bulunamadı');
      }

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final group = GroupModel.fromJson({...groupData, 'id': groupDoc.id});

      // Middleware: Permission kontrolü
      PermissionMiddleware.requireCanEditGroup(user, group);

      // Güncelleme verilerini hazırla
      final updateData = <String, dynamic>{
        'name': name,
        'description': description,
        'updatedAt': DateTime.now().toIso8601String(),
      };

      // imageUrl varsa ekle
      // null ise field'ı sil (kullanıcı resmi kaldırdıysa)
      // imageUrl parametresi gönderilmediyse (null değil ama parametre yok) mevcut değeri koru
      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      } else if (imageUrl == null && group.imageUrl != null) {
        // Kullanıcı resmi kaldırdıysa field'ı sil
        updateData['imageUrl'] = FieldValue.delete();
      }
      // imageUrl null ve group.imageUrl da null ise hiçbir şey yapma (zaten yok)

      // Path'i kontrol et
      if (groupId.isEmpty) {
        throw const NotFoundException('Grup ID geçersiz');
      }

      final path = 'groups/$groupId';
      print('Grup güncelleme - Path: $path, GroupId: $groupId');
      print('Grup güncelleme - UpdateData: $updateData');

      // Dokümanın var olduğunu tekrar kontrol et
      final docCheck = await FirebaseService.getDocumentSnapshot(path);
      if (!docCheck.exists) {
        throw const NotFoundException('Grup bulunamadı (güncelleme öncesi kontrol)');
      }

      await FirebaseService.updateDocument(path: path, data: updateData);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
      rethrow;
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

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final group = GroupModel.fromJson({...groupData, 'id': groupDoc.id});

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

      final groupData = groupDoc.data() as Map<String, dynamic>;
      final group = GroupModel.fromJson({...groupData, 'id': groupDoc.id});

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
