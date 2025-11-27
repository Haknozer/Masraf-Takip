import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/invitation_model.dart';
import '../models/group_model.dart';
import '../services/firebase_service.dart';
import '../providers/auth_provider.dart';
import '../providers/group_provider.dart' hide userDocumentIdProvider;

class InvitationController {
  final Ref ref;

  InvitationController(this.ref);

  /// Davet gönder
  Future<void> sendInvitation(String groupId, String toUserId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    // Grup bilgisini al
    final groupDoc = await FirebaseService.getDocumentSnapshot('groups/$groupId');
    if (!groupDoc.exists) throw Exception('Grup bulunamadı');
    final groupData = groupDoc.data() as Map<String, dynamic>;
    final group = GroupModel.fromJson({...groupData, 'id': groupDoc.id});

    // Zaten üye mi?
    if (group.memberIds.contains(toUserId)) {
      throw Exception('Kullanıcı zaten grubun üyesi');
    }

    // Grup tarafından engellenmiş mi?
    if (group.isUserBlocked(toUserId)) {
      throw Exception('Bu kullanıcı grup tarafından engellenmiş.');
    }

    // Kullanıcı grubu engellemiş mi?
    final toUserDoc =
        await FirebaseService.firestore.collection('users').where('id', isEqualTo: toUserId).limit(1).get();
    if (toUserDoc.docs.isNotEmpty) {
      final userData = toUserDoc.docs.first.data();
      final blockedGroupIds = List<String>.from(userData['blockedGroupIds'] ?? []);
      if (blockedGroupIds.contains(groupId)) {
        throw Exception('Bu kullanıcı bu grubu engellemiş.');
      }
    }

    // Zaten davet var mı?
    final existingInvitations = await FirebaseService.firestore
        .collection('invitations')
        .where('groupId', isEqualTo: groupId)
        .where('toUserId', isEqualTo: toUserId)
        .where('status', isEqualTo: 'pending')
        .get();

    if (existingInvitations.docs.isNotEmpty) {
      throw Exception('Kullanıcıya zaten gönderilmiş bekleyen bir davet var');
    }

    // Davet oluştur
    final invitation = InvitationModel(
      id: '', // Otomatik ID
      groupId: groupId,
      groupName: group.name,
      inviterId: currentUser.uid,
      inviterName: currentUser.displayName ?? currentUser.email ?? 'Bilinmeyen',
      toUserId: toUserId,
      createdAt: DateTime.now(),
      status: InvitationStatus.pending,
    );

    await FirebaseService.addDocument(collection: 'invitations', data: invitation.toJson());
  }

  /// Daveti kabul et
  Future<void> acceptInvitation(InvitationModel invitation) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    try {
      // 1. Kullanıcıyı gruba ekle
      // GroupNotifier içindeki addMember metodunu kullanabiliriz ama o metodda yetki kontrolü var.
      // Burada davet kabul edildiği için kullanıcı kendi kendini ekliyor gibi olacak.
      // Bu yüzden doğrudan veritabanı işlemlerini burada yapıyoruz.
      
      final groupDoc = await FirebaseService.getDocumentSnapshot('groups/${invitation.groupId}');
      if (!groupDoc.exists) throw Exception('Grup artık mevcut değil');
      
      final groupData = groupDoc.data() as Map<String, dynamic>;
      final group = GroupModel.fromJson({...groupData, 'id': groupDoc.id});

      // Zaten üye mi?
      if (group.memberIds.contains(currentUser.uid)) {
         // Zaten üye ise sadece daveti güncelle
         await _updateInvitationStatus(invitation.id, InvitationStatus.accepted);
         return;
      }
      
      // Grubu güncelle
      final updatedGroup = group.addMember(currentUser.uid, role: 'user');
      await FirebaseService.updateDocument(path: 'groups/${group.id}', data: updatedGroup.toJson());

      // Kullanıcının gruplarını güncelle
      final userDocId = await ref.read(userDocumentIdProvider.future);
      if (userDocId != null) {
        await FirebaseService.updateDocument(
          path: 'users/$userDocId',
          data: {
            'groups': FieldValue.arrayUnion([group.id]),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }

      // 2. Davet durumunu güncelle
      await _updateInvitationStatus(invitation.id, InvitationStatus.accepted);
      
      // Grubu yenile
      ref.invalidate(groupNotifierProvider);
      
    } catch (e) {
      throw Exception('Davet kabul edilirken hata oluştu: $e');
    }
  }

  /// Daveti reddet
  Future<void> rejectInvitation(String invitationId) async {
    await _updateInvitationStatus(invitationId, InvitationStatus.rejected);
  }

  /// Grubu engelle ve daveti reddet
  Future<void> blockGroup(InvitationModel invitation) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Kullanıcı oturumu bulunamadı');

    try {
      // 1. Kullanıcının blockedGroupIds listesine ekle
      final userDocId = await ref.read(userDocumentIdProvider.future);
      if (userDocId != null) {
        await FirebaseService.updateDocument(
          path: 'users/$userDocId',
          data: {
            'blockedGroupIds': FieldValue.arrayUnion([invitation.groupId]),
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      }

      // 2. Daveti reddet
      await _updateInvitationStatus(invitation.id, InvitationStatus.rejected);
      
      // Kullanıcı modelini yenile
      ref.invalidate(userModelProvider);
      
    } catch (e) {
      throw Exception('Grup engellenirken hata oluştu: $e');
    }
  }

  Future<void> _updateInvitationStatus(String invitationId, InvitationStatus status) async {
    await FirebaseService.updateDocument(
      path: 'invitations/$invitationId',
      data: {
        'status': status.toString().split('.').last,
      },
    );
  }
}

final invitationControllerProvider = Provider<InvitationController>((ref) {
  return InvitationController(ref);
});
