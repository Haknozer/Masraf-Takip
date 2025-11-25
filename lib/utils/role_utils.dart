import '../models/group_model.dart';
import '../models/expense_model.dart';

class RoleUtils {
  // Kullanıcı grup admin'i mi?
  static bool isGroupAdmin(GroupModel group, String userId) {
    return group.isGroupAdmin(userId);
  }

  // Kullanıcı grup üyesi mi?
  static bool isGroupMember(GroupModel group, String userId) {
    return group.isGroupMember(userId);
  }

  // Kullanıcı gruba üye ekleyebilir mi?
  static bool canAddMember(GroupModel group, String userId) {
    // Tüm grup üyeleri üye ekleyebilir
    return isGroupMember(group, userId);
  }

  // Kullanıcı gruptan üye çıkarabilir mi?
  static bool canRemoveMember(GroupModel group, String userId, String targetUserId) {
    // Admin ise herkesi çıkarabilir
    if (isGroupAdmin(group, userId)) return true;

    // Kendi kendini çıkarabilir
    if (userId == targetUserId) return true;

    return false;
  }

  // Kullanıcı grubu düzenleyebilir mi?
  static bool canEditGroup(GroupModel group, String userId) {
    return isGroupAdmin(group, userId);
  }

  // Kullanıcı grubu silebilir mi?
  static bool canDeleteGroup(GroupModel group, String userId) {
    return isGroupAdmin(group, userId);
  }

  // Kullanıcı masraf ekleyebilir mi?
  static bool canAddExpense(GroupModel group, String userId) {
    return isGroupMember(group, userId);
  }

  // Kullanıcı masrafı düzenleyebilir mi?
  static bool canEditExpense(GroupModel group, ExpenseModel expense, String userId) {
    // Sadece masrafı ekleyen (ödeyen) kişi düzenleyebilir
    return expense.paidBy == userId;
  }

  // Kullanıcı masrafı silebilir mi?
  static bool canDeleteExpense(GroupModel group, ExpenseModel expense, String userId) {
    // Admin ise tüm masrafları silebilir
    if (isGroupAdmin(group, userId)) return true;

    // Kendi masrafını silebilir
    if (expense.paidBy == userId) return true;

    return false;
  }

  // Kullanıcı grup ayarlarını değiştirebilir mi?
  static bool canManageGroupSettings(GroupModel group, String userId) {
    return isGroupAdmin(group, userId);
  }

  // Kullanıcı grup istatistiklerini görebilir mi?
  static bool canViewGroupStats(GroupModel group, String userId) {
    return isGroupMember(group, userId);
  }

  // Kullanıcı grup geçmişini görebilir mi?
  static bool canViewGroupHistory(GroupModel group, String userId) {
    return isGroupMember(group, userId);
  }

  // Kullanıcının gruptaki yetkilerini al
  static List<String> getUserPermissions(GroupModel group, String userId) {
    final permissions = <String>[];

    if (isGroupMember(group, userId)) {
      permissions.addAll(['view_group', 'view_expenses', 'add_expense', 'view_stats', 'view_history']);
    }

    if (isGroupAdmin(group, userId)) {
      permissions.addAll([
        'manage_members',
        'edit_group',
        'delete_group',
        'manage_settings',
        'edit_all_expenses',
        'delete_all_expenses',
      ]);
    }

    return permissions;
  }

  // Kullanıcının belirli bir yetkisi var mı?
  static bool hasPermission(GroupModel group, String userId, String permission) {
    final permissions = getUserPermissions(group, userId);
    return permissions.contains(permission);
  }
}
