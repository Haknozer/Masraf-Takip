import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/middleware_exceptions.dart';
import '../models/group_model.dart';
import '../models/expense_model.dart';
import '../utils/role_utils.dart';

/// Permission middleware sınıfı
class PermissionMiddleware {
  /// Kullanıcının belirli bir grupta admin olup olmadığını kontrol et
  static void requireGroupAdmin(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.isGroupAdmin(group, user.uid)) {
      throw const ForbiddenException('Bu işlem için grup admin yetkisi gereklidir');
    }
  }

  /// Kullanıcının belirli bir grupta üye olup olmadığını kontrol et
  static void requireGroupMember(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.isGroupMember(group, user.uid)) {
      throw const ForbiddenException('Bu grubun üyesi değilsiniz');
    }
  }

  /// Kullanıcının gruba üye ekleyebilir olup olmadığını kontrol et
  static void requireCanAddMember(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canAddMember(group, user.uid)) {
      throw const ForbiddenException('Gruba üye ekleme yetkiniz yok');
    }
  }

  /// Kullanıcının gruptan üye çıkarabilir olup olmadığını kontrol et
  static void requireCanRemoveMember(User? user, GroupModel group, String targetUserId) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canRemoveMember(group, user.uid, targetUserId)) {
      throw const ForbiddenException('Bu üyeyi gruptan çıkarma yetkiniz yok');
    }
  }

  /// Kullanıcının grubu düzenleyebilir olup olmadığını kontrol et
  static void requireCanEditGroup(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canEditGroup(group, user.uid)) {
      throw const ForbiddenException('Grup düzenleme yetkiniz yok');
    }
  }

  /// Kullanıcının grubu silebilir olup olmadığını kontrol et
  static void requireCanDeleteGroup(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canDeleteGroup(group, user.uid)) {
      throw const ForbiddenException('Grup silme yetkiniz yok');
    }
  }

  /// Kullanıcının masraf ekleyebilir olup olmadığını kontrol et
  static void requireCanAddExpense(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canAddExpense(group, user.uid)) {
      throw const ForbiddenException('Masraf ekleme yetkiniz yok');
    }
  }

  /// Kullanıcının masrafı düzenleyebilir olup olmadığını kontrol et
  static void requireCanEditExpense(User? user, GroupModel group, ExpenseModel expense) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canEditExpense(group, expense, user.uid)) {
      throw const ForbiddenException('Bu masrafı düzenleme yetkiniz yok');
    }
  }

  /// Kullanıcının masrafı silebilir olup olmadığını kontrol et
  static void requireCanDeleteExpense(User? user, GroupModel group, ExpenseModel expense) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canDeleteExpense(group, expense, user.uid)) {
      throw const ForbiddenException('Bu masrafı silme yetkiniz yok');
    }
  }

  /// Kullanıcının grup ayarlarını yönetebilir olup olmadığını kontrol et
  static void requireCanManageGroupSettings(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canManageGroupSettings(group, user.uid)) {
      throw const ForbiddenException('Grup ayarlarını yönetme yetkiniz yok');
    }
  }

  /// Kullanıcının grup istatistiklerini görebilir olup olmadığını kontrol et
  static void requireCanViewGroupStats(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canViewGroupStats(group, user.uid)) {
      throw const ForbiddenException('Grup istatistiklerini görme yetkiniz yok');
    }
  }

  /// Kullanıcının grup geçmişini görebilir olup olmadığını kontrol et
  static void requireCanViewGroupHistory(User? user, GroupModel group) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.canViewGroupHistory(group, user.uid)) {
      throw const ForbiddenException('Grup geçmişini görme yetkiniz yok');
    }
  }

  /// Kullanıcının belirli bir yetkiye sahip olup olmadığını kontrol et
  static void requirePermission(User? user, GroupModel group, String permission) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }

    if (!RoleUtils.hasPermission(group, user.uid, permission)) {
      throw ForbiddenException('Bu işlem için $permission yetkisi gereklidir');
    }
  }
}
