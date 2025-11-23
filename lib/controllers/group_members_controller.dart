import '../models/user_model.dart';
import '../models/group_model.dart';
import '../services/firebase_service.dart';

/// Group Members Controller - MVC prensiplerine uygun grup üyeleri işlemleri controller'ı
class GroupMembersController {
  /// Grup üyelerini getir
  static Future<List<UserModel>> getGroupMembers(GroupModel group) async {
    final members = <UserModel>[];

    for (final memberId in group.memberIds) {
      try {
        final userDoc = await FirebaseService.getDocumentSnapshot('users/$memberId');
        if (userDoc.exists) {
          final data = userDoc.data() as Map<String, dynamic>;
          members.add(UserModel.fromJson(data));
        }
      } catch (e) {
        // Hata durumunda devam et
        continue;
      }
    }

    return members;
  }

  /// Kullanıcının gruptaki rolünü al
  static String getUserRole(GroupModel group, String userId) {
    return group.getUserRole(userId);
  }

  /// Kullanıcı admin mi kontrol et
  static bool isAdmin(GroupModel group, String userId) {
    return group.isGroupAdmin(userId);
  }
}

