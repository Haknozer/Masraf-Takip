import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/role_utils.dart';
import 'auth_provider.dart';
import 'group_provider.dart';

// Kullanıcının belirli bir gruptaki rolünü al
final userRoleProvider = Provider.family<String, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final groups = ref.watch(userGroupsProvider);

  if (user == null) return 'user';

  return groups.when(
    data: (groupList) {
      final group = groupList.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
      return group.getUserRole(user.uid);
    },
    loading: () => 'user',
    error: (_, __) => 'user',
  );
});

// Kullanıcının belirli bir grupta admin olup olmadığını kontrol et
final isGroupAdminProvider = Provider.family<bool, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final groups = ref.watch(userGroupsProvider);

  if (user == null) return false;

  return groups.when(
    data: (groupList) {
      final group = groupList.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
      return group.isGroupAdmin(user.uid);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// Kullanıcının belirli bir grupta üye olup olmadığını kontrol et
final isGroupMemberProvider = Provider.family<bool, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final groups = ref.watch(userGroupsProvider);

  if (user == null) return false;

  return groups.when(
    data: (groupList) {
      final group = groupList.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
      return group.isGroupMember(user.uid);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// Kullanıcının belirli bir gruptaki yetkilerini al
final userPermissionsProvider = Provider.family<List<String>, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final groups = ref.watch(userGroupsProvider);

  if (user == null) return [];

  return groups.when(
    data: (groupList) {
      final group = groupList.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
      return RoleUtils.getUserPermissions(group, user.uid);
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

// Kullanıcının belirli bir yetkiye sahip olup olmadığını kontrol et
final hasPermissionProvider = Provider.family<bool, (String, String)>((ref, params) {
  final groupId = params.$1;
  final permission = params.$2;
  final user = ref.watch(currentUserProvider);
  final groups = ref.watch(userGroupsProvider);

  if (user == null) return false;

  return groups.when(
    data: (groupList) {
      final group = groupList.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
      return RoleUtils.hasPermission(group, user.uid, permission);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// Kullanıcının grup yönetimi yetkilerini kontrol et
final canManageGroupProvider = Provider.family<bool, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final groups = ref.watch(userGroupsProvider);

  if (user == null) return false;

  return groups.when(
    data: (groupList) {
      final group = groupList.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
      return RoleUtils.canEditGroup(group, user.uid);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// Kullanıcının üye yönetimi yetkilerini kontrol et
final canManageMembersProvider = Provider.family<bool, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final groups = ref.watch(userGroupsProvider);

  if (user == null) return false;

  return groups.when(
    data: (groupList) {
      final group = groupList.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
      return RoleUtils.canAddMember(group, user.uid);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});

// Kullanıcının masraf yönetimi yetkilerini kontrol et
final canManageExpensesProvider = Provider.family<bool, String>((ref, groupId) {
  final user = ref.watch(currentUserProvider);
  final groups = ref.watch(userGroupsProvider);

  if (user == null) return false;

  return groups.when(
    data: (groupList) {
      final group = groupList.firstWhere((g) => g.id == groupId, orElse: () => throw Exception('Grup bulunamadı'));
      return RoleUtils.canAddExpense(group, user.uid);
    },
    loading: () => false,
    error: (_, __) => false,
  );
});
