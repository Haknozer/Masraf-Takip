import '../models/debt_model.dart';
import '../models/expense_model.dart';
import '../models/group_model.dart';
import '../models/user_model.dart';
import '../models/settlement_model.dart';

/// Borç hesaplama utility sınıfı
class DebtCalculator {
  /// Bir gruptaki tüm borçları hesapla
  static GroupDebtSummary calculateGroupDebts({
    required String userId,
    required GroupModel group,
    required List<ExpenseModel> expenses,
    required Map<String, UserModel> usersMap,
    List<SettlementPayment> settlements = const [],
  }) {
    // Kullanıcının bu gruptaki borçlarını hesapla
    final debts = <DebtBetweenUsers>[];
    double totalOwed = 0.0; // Kullanıcının borçlu olduğu toplam
    double totalOwing = 0.0; // Kullanıcının alacaklı olduğu toplam

    // Her masraf için borç hesapla
    for (final expense in expenses) {
      if (expense.groupId != group.id) continue;

      final paidByUser = usersMap[expense.paidBy];
      final paidByName = paidByUser?.displayName ?? 'Bilinmeyen';

      // Eğer kullanıcı bu masrafı ödediyse, diğerleri ona borçlu
      if (expense.paidBy == userId) {
        for (final sharedUserId in expense.sharedBy) {
          if (sharedUserId == userId) continue; // Kendisine borçlu değil

          final sharedUser = usersMap[sharedUserId];
          final sharedUserName = sharedUser?.displayName ?? 'Bilinmeyen';
          final userAmount = expense.getAmountForUser(sharedUserId);

          // Mevcut borç var mı kontrol et
          final existingDebtIndex = debts.indexWhere(
            (d) => d.fromUserId == sharedUserId && d.toUserId == userId,
          );

          if (existingDebtIndex >= 0) {
            // Mevcut borcu güncelle
            final existingDebt = debts[existingDebtIndex];
            final updatedDetails = List<DebtDetail>.from(existingDebt.details)
              ..add(
                DebtDetail(
                  expenseId: expense.id,
                  expenseDescription: expense.description,
                  groupId: group.id,
                  groupName: group.name,
                  amount: userAmount,
                  date: expense.date,
                  category: expense.category,
                ),
              );

            debts[existingDebtIndex] = DebtBetweenUsers(
              fromUserId: sharedUserId,
              fromUserName: sharedUserName,
              toUserId: userId,
              toUserName: usersMap[userId]?.displayName ?? 'Bilinmeyen',
              amount: existingDebt.amount + userAmount,
              groupId: group.id,
              groupName: group.name,
              details: updatedDetails,
            );
            totalOwing += userAmount;
          } else {
            // Yeni borç oluştur
            debts.add(
              DebtBetweenUsers(
                fromUserId: sharedUserId,
                fromUserName: sharedUserName,
                toUserId: userId,
                toUserName: usersMap[userId]?.displayName ?? 'Bilinmeyen',
                amount: userAmount,
                groupId: group.id,
                groupName: group.name,
                details: [
                  DebtDetail(
                    expenseId: expense.id,
                    expenseDescription: expense.description,
                    groupId: group.id,
                    groupName: group.name,
                    amount: userAmount,
                    date: expense.date,
                    category: expense.category,
                  ),
                ],
              ),
            );
            totalOwing += userAmount;
          }
        }
      } else {
        // Eğer kullanıcı bu masrafı paylaşıyorsa, ödeyene borçlu
        if (expense.sharedBy.contains(userId)) {
          final userAmount = expense.getAmountForUser(userId);

          // Mevcut borç var mı kontrol et
          final existingDebtIndex = debts.indexWhere(
            (d) => d.fromUserId == userId && d.toUserId == expense.paidBy,
          );

          if (existingDebtIndex >= 0) {
            // Mevcut borcu güncelle
            final existingDebt = debts[existingDebtIndex];
            final updatedDetails = List<DebtDetail>.from(existingDebt.details)
              ..add(
                DebtDetail(
                  expenseId: expense.id,
                  expenseDescription: expense.description,
                  groupId: group.id,
                  groupName: group.name,
                  amount: userAmount,
                  date: expense.date,
                  category: expense.category,
                ),
              );

            debts[existingDebtIndex] = DebtBetweenUsers(
              fromUserId: userId,
              fromUserName: usersMap[userId]?.displayName ?? 'Bilinmeyen',
              toUserId: expense.paidBy,
              toUserName: paidByName,
              amount: existingDebt.amount + userAmount,
              groupId: group.id,
              groupName: group.name,
              details: updatedDetails,
            );
            totalOwed += userAmount;
          } else {
            // Yeni borç oluştur
            debts.add(
              DebtBetweenUsers(
                fromUserId: userId,
                fromUserName: usersMap[userId]?.displayName ?? 'Bilinmeyen',
                toUserId: expense.paidBy,
                toUserName: paidByName,
                amount: userAmount,
                groupId: group.id,
                groupName: group.name,
                details: [
                  DebtDetail(
                    expenseId: expense.id,
                    expenseDescription: expense.description,
                    groupId: group.id,
                    groupName: group.name,
                    amount: userAmount,
                    date: expense.date,
                    category: expense.category,
                  ),
                ],
              ),
            );
            totalOwed += userAmount;
          }
        }
      }
    }

    // Settlement payment'larını dikkate al - borçlardan düş
    final settlementMap =
        <String, double>{}; // "fromUserId_toUserId" -> toplam ödeme
    for (final settlement in settlements) {
      if (settlement.groupId != group.id) continue;

      final key = '${settlement.fromUserId}_${settlement.toUserId}';
      settlementMap[key] = (settlementMap[key] ?? 0.0) + settlement.amount;
    }

    // Settlement'ları borçlardan düş
    for (int i = 0; i < debts.length; i++) {
      final debt = debts[i];
      final key = '${debt.fromUserId}_${debt.toUserId}';
      final paidAmount = settlementMap[key] ?? 0.0;

      if (paidAmount > 0) {
        final remainingAmount = (debt.amount - paidAmount).clamp(
          0.0,
          double.infinity,
        );

        if (remainingAmount <= 0.01) {
          // Borç tamamen ödendi, listeden çıkar
          debts.removeAt(i);
          i--;

          // Total'lerden de düş
          if (debt.toUserId == userId) {
            totalOwing -= debt.amount;
          } else if (debt.fromUserId == userId) {
            totalOwed -= debt.amount;
          }
        } else {
          // Borç kısmen ödendi, güncelle
          debts[i] = DebtBetweenUsers(
            fromUserId: debt.fromUserId,
            fromUserName: debt.fromUserName,
            toUserId: debt.toUserId,
            toUserName: debt.toUserName,
            amount: remainingAmount,
            groupId: debt.groupId,
            groupName: debt.groupName,
            details: debt.details,
          );

          // Total'lerden düş
          if (debt.toUserId == userId) {
            totalOwing -= paidAmount;
          } else if (debt.fromUserId == userId) {
            totalOwed -= paidAmount;
          }
        }
      }
    }

    // Net durum hesapla
    final netAmount = totalOwing - totalOwed;

    return GroupDebtSummary(
      groupId: group.id,
      groupName: group.name,
      totalOwed: totalOwed,
      totalOwing: totalOwing,
      netAmount: netAmount,
      debts: debts,
    );
  }

  /// Kullanıcının tüm gruplardaki borç özetini hesapla
  static UserDebtSummary calculateUserDebtSummary({
    required String userId,
    required List<GroupModel> groups,
    required List<ExpenseModel> allExpenses,
    required Map<String, UserModel> usersMap,
    List<SettlementPayment> settlements = const [],
  }) {
    final groupSummaries = <GroupDebtSummary>[];
    double totalOwed = 0.0;
    double totalOwing = 0.0;

    for (final group in groups) {
      final groupExpenses =
          allExpenses.where((e) => e.groupId == group.id).toList();
      final groupSettlements =
          settlements.where((s) => s.groupId == group.id).toList();
      final groupSummary = calculateGroupDebts(
        userId: userId,
        group: group,
        expenses: groupExpenses,
        usersMap: usersMap,
        settlements: groupSettlements,
      );

      groupSummaries.add(groupSummary);
      totalOwed += groupSummary.totalOwed;
      totalOwing += groupSummary.totalOwing;
    }

    final netAmount = totalOwing - totalOwed;

    return UserDebtSummary(
      userId: userId,
      totalOwed: totalOwed,
      totalOwing: totalOwing,
      netAmount: netAmount,
      groupSummaries: groupSummaries,
    );
  }

  /// Kullanıcıların ID'lerinden UserModel map'i oluştur
  static Future<Map<String, UserModel>> buildUsersMap(
    List<String> userIds,
  ) async {
    final usersMap = <String, UserModel>{};
    // Bu fonksiyon Firebase'den kullanıcıları çekmek için kullanılabilir
    // Şimdilik boş map döndürüyoruz, gerçek implementasyonda doldurulacak
    return usersMap;
  }
}
