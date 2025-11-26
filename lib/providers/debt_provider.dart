import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/debt_model.dart';
import '../models/expense_model.dart';
import '../models/user_model.dart';
import '../models/settlement_model.dart';
import '../utils/debt_calculator.dart';
import '../services/firebase_service.dart';
import 'expense_provider.dart';
import 'group_provider.dart';
import 'auth_provider.dart';

/// Kullanıcıların map'ini oluştur
Future<Map<String, UserModel>> _buildUsersMap(List<String> userIds) async {
  final usersMap = <String, UserModel>{};
  for (final userId in userIds) {
    try {
      final userDoc = await FirebaseService.getDocumentSnapshot(
        'users/$userId',
      );
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        usersMap[userId] = UserModel.fromJson(data);
      }
    } catch (e) {
      // Hata durumunda devam et
    }
  }
  return usersMap;
}

/// Kullanıcının tüm gruplardaki borç özeti provider'ı
final userDebtSummaryProvider = FutureProvider<UserDebtSummary>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) {
    throw Exception('Kullanıcı giriş yapmamış');
  }

  // Grupları al
  final groupsState = ref.watch(userGroupsProvider);
  final groups = groupsState.valueOrNull ?? [];

  if (groups.isEmpty) {
    return UserDebtSummary(
      userId: user.uid,
      totalOwed: 0.0,
      totalOwing: 0.0,
      netAmount: 0.0,
      groupSummaries: [],
    );
  }

  // Tüm masrafları al
  final allExpenses = <ExpenseModel>[];
  for (final group in groups) {
    final expensesState = ref.watch(groupExpensesProvider(group.id));
    final expenses = expensesState.valueOrNull ?? [];
    allExpenses.addAll(expenses);
  }

  // Tüm kullanıcı ID'lerini topla
  final allUserIds = <String>{user.uid};
  for (final group in groups) {
    allUserIds.addAll(group.memberIds);
  }
  for (final expense in allExpenses) {
    allUserIds.add(expense.paidBy);
    allUserIds.addAll(expense.sharedBy);
    if (expense.paidAmounts != null) {
      allUserIds.addAll(expense.paidAmounts!.keys);
    }
  }

  // Kullanıcı map'ini oluştur
  final usersMap = await _buildUsersMap(allUserIds.toList());

  // Settlement payment'ları al
  final settlements = <SettlementPayment>[];
  for (final group in groups) {
    try {
      final settlementsSnapshot =
          await FirebaseService.firestore
              .collection('settlements')
              .where('groupId', isEqualTo: group.id)
              .get();

      settlements.addAll(
        settlementsSnapshot.docs.map(
          (doc) => SettlementPayment.fromJson({'id': doc.id, ...doc.data()}),
        ),
      );
    } catch (e) {
      // Hata durumunda devam et
    }
  }

  // Borç özetini hesapla
  return DebtCalculator.calculateUserDebtSummary(
    userId: user.uid,
    groups: groups,
    allExpenses: allExpenses,
    usersMap: usersMap,
    settlements: settlements,
  );
});

/// Belirli bir gruptaki borç özeti provider'ı
final groupDebtSummaryProvider =
    FutureProvider.family<GroupDebtSummary, String>((ref, groupId) async {
      final user = ref.watch(currentUserProvider);
      if (user == null) {
        throw Exception('Kullanıcı giriş yapmamış');
      }

      // Grubu al
      final groupState = ref.watch(groupProvider(groupId));
      final group = groupState.valueOrNull;
      if (group == null) {
        throw Exception('Grup bulunamadı');
      }

      // Masrafları al
      final expensesState = ref.watch(groupExpensesProvider(groupId));
      final expenses = expensesState.valueOrNull ?? [];

      // Tüm kullanıcı ID'lerini topla
      final allUserIds = <String>{user.uid};
      allUserIds.addAll(group.memberIds);
      for (final expense in expenses) {
        allUserIds.add(expense.paidBy);
        allUserIds.addAll(expense.sharedBy);
        if (expense.paidAmounts != null) {
          allUserIds.addAll(expense.paidAmounts!.keys);
        }
      }

      // Kullanıcı map'ini oluştur
      final usersMap = await _buildUsersMap(allUserIds.toList());

      // Settlement payment'ları al
      final settlements = <SettlementPayment>[];
      try {
        final settlementsSnapshot =
            await FirebaseService.firestore
                .collection('settlements')
                .where('groupId', isEqualTo: groupId)
                .get();

        settlements.addAll(
          settlementsSnapshot.docs.map(
            (doc) => SettlementPayment.fromJson({'id': doc.id, ...doc.data()}),
          ),
        );
      } catch (e) {
        // Hata durumunda devam et
      }

      // Borç özetini hesapla
      return DebtCalculator.calculateGroupDebts(
        userId: user.uid,
        group: group,
        expenses: expenses,
        usersMap: usersMap,
        settlements: settlements,
      );
    });
