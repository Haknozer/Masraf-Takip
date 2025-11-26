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
    var debts = <DebtBetweenUsers>[];
    double totalOwed = 0.0; // Kullanıcının borçlu olduğu toplam
    double totalOwing = 0.0; // Kullanıcının alacaklı olduğu toplam

    // Her masraf için borç hesapla
    for (final expense in expenses) {
      if (expense.groupId != group.id) continue;

      final transactions = _buildExpenseTransactions(
        expense: expense,
        usersMap: usersMap,
      );

      for (final transaction in transactions) {
        if (transaction.amount <= 0.01) continue;

        if (transaction.fromUserId == userId) {
          totalOwed += transaction.amount;
          _upsertDebt(
            debts: debts,
            fromUserId: transaction.fromUserId,
            toUserId: transaction.toUserId,
            amount: transaction.amount,
            expense: expense,
            group: group,
            usersMap: usersMap,
          );
        } else if (transaction.toUserId == userId) {
          totalOwing += transaction.amount;
          _upsertDebt(
            debts: debts,
            fromUserId: transaction.fromUserId,
            toUserId: transaction.toUserId,
            amount: transaction.amount,
            expense: expense,
            group: group,
            usersMap: usersMap,
          );
        }
      }
    }

    // Karşılıklı borçları netleştir
    debts = _netDebts(debts, userId, usersMap, group);
    
    // Totalleri yeniden hesapla (netleştirme sonrası)
    totalOwed = 0.0;
    totalOwing = 0.0;
    for (final debt in debts) {
      if (debt.fromUserId == userId) {
        totalOwed += debt.amount;
      } else if (debt.toUserId == userId) {
        totalOwing += debt.amount;
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

  /// Karşılıklı borçları netleştir
  /// Örnek: A -> B 600₺ ve B -> A 1400₺ ise, sadece B -> A 800₺ olarak göster
  static List<DebtBetweenUsers> _netDebts(
    List<DebtBetweenUsers> debts,
    String currentUserId,
    Map<String, UserModel> usersMap,
    GroupModel group,
  ) {
    final nettedDebts = <DebtBetweenUsers>[];
    final processed = <String>{};

    for (final debt in debts) {
      final key1 = '${debt.fromUserId}_${debt.toUserId}';
      final key2 = '${debt.toUserId}_${debt.fromUserId}';

      if (processed.contains(key1)) continue;

      // Karşı yönde borç var mı kontrol et
      final reverseDebt = debts.firstWhere(
        (d) => d.fromUserId == debt.toUserId && d.toUserId == debt.fromUserId,
        orElse: () => DebtBetweenUsers(
          fromUserId: '',
          fromUserName: '',
          toUserId: '',
          toUserName: '',
          amount: 0.0,
          groupId: group.id,
          groupName: group.name,
          details: [],
        ),
      );

      processed.add(key1);
      processed.add(key2);

      if (reverseDebt.amount > 0.01) {
        // Karşılıklı borç var, netleştir
        final netAmount = debt.amount - reverseDebt.amount;
        
        if (netAmount.abs() > 0.01) {
          if (netAmount > 0) {
            // debt yönünde net borç var
            nettedDebts.add(DebtBetweenUsers(
              fromUserId: debt.fromUserId,
              fromUserName: debt.fromUserName,
              toUserId: debt.toUserId,
              toUserName: debt.toUserName,
              amount: netAmount,
              groupId: debt.groupId,
              groupName: debt.groupName,
              details: [...debt.details, ...reverseDebt.details],
            ));
          } else {
            // reverse debt yönünde net borç var
            nettedDebts.add(DebtBetweenUsers(
              fromUserId: reverseDebt.fromUserId,
              fromUserName: reverseDebt.fromUserName,
              toUserId: reverseDebt.toUserId,
              toUserName: reverseDebt.toUserName,
              amount: -netAmount,
              groupId: reverseDebt.groupId,
              groupName: reverseDebt.groupName,
              details: [...debt.details, ...reverseDebt.details],
            ));
          }
        }
      } else {
        // Tek yönlü borç, olduğu gibi ekle
        nettedDebts.add(debt);
      }
    }

    return nettedDebts;
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

  /// Klasik defter mantığıyla net bakiye (her harcama için eşit paylaşım veya manuel tutarlar)
  /// Net = kullanıcının ödediği toplam - harcamalardan ona düşen pay
  static Map<String, double> calculateNetBalances({
    required List<ExpenseModel> expenses,
    required List<String> userIds,
  }) {
    final netBalances = <String, double>{};
    final paidTotals = <String, double>{};
    final owedTotals = <String, double>{};

    for (final expense in expenses) {
      final payerMap = expense.payerAmounts;
      payerMap.forEach((payerId, paidAmount) {
        paidTotals[payerId] = (paidTotals[payerId] ?? 0.0) + paidAmount;
      });

      final participants =
          expense.sharedBy.isEmpty ? [expense.paidBy] : expense.sharedBy;
      for (final participant in participants) {
        final share = expense.getAmountForUser(participant);
        owedTotals[participant] = (owedTotals[participant] ?? 0.0) + share;
      }
    }

    for (final userId in userIds) {
      final paid = paidTotals[userId] ?? 0.0;
      final owed = owedTotals[userId] ?? 0.0;
      netBalances[userId] = paid - owed;
    }

    return netBalances;
  }

  /// Basit defter mantığında net bakiyeleri ve ödeme önerilerini döndür
  static SimpleSettlementSummary calculateSimpleSettlementSummary({
    required List<ExpenseModel> expenses,
    required List<String> userIds,
    required Map<String, UserModel> usersMap,
  }) {
    if (userIds.isEmpty) {
      return SimpleSettlementSummary.empty();
    }

    final netBalances =
        calculateNetBalances(expenses: expenses, userIds: userIds);
    final totalExpense =
        expenses.fold<double>(0.0, (sum, e) => sum + e.amount);
    final participantIds = <String>{};
    for (final expense in expenses) {
      if (expense.sharedBy.isEmpty) {
        participantIds.add(expense.paidBy);
      } else {
        participantIds.addAll(expense.sharedBy);
      }
    }
    final average =
        participantIds.isEmpty ? 0.0 : totalExpense / participantIds.length;

    final balanceEntries = netBalances.entries
        .map(
          (entry) => SimpleNetBalance(
            userId: entry.key,
            userName: usersMap[entry.key]?.displayName ?? 'Bilinmeyen',
            netAmount: entry.value,
          ),
        )
        .where((b) => b.netAmount.abs() > 0.01)
        .toList()
      ..sort((a, b) => b.netAmount.compareTo(a.netAmount));

    final settlementInstructions = settleDebtsFromNetBalances(
      netBalances: netBalances,
      usersMap: usersMap,
    );

    return SimpleSettlementSummary(
      totalExpense: totalExpense,
      averagePerPerson: average,
      netBalances: balanceEntries,
      settlementInstructions: settlementInstructions,
    );
  }

  /// Net bakiyelerden sade borç kapatma algoritması
  /// - Negatif bakiye: borçlu, pozitif: alacaklı
  static List<SimpleSettlementInstruction> settleDebtsFromNetBalances({
    required Map<String, double> netBalances,
    required Map<String, UserModel> usersMap,
  }) {
    final borclular = <String, double>{}; // Negatif bakiyeliler
    final alacaklilar = <String, double>{}; // Pozitif bakiyeliler
    // Yuvarlama hassasiyetini koru
    const epsilon = 0.01;
    // Listeleri doldur
    netBalances.forEach((userId, bakiye) {
      if (bakiye.abs() < epsilon) return; // Nötr
      if (bakiye < 0) {
        borclular[userId] = -bakiye; // Pozitif değer olarak kaydediyoruz
      } else {
        alacaklilar[userId] = bakiye;
      }
    });
    final result = <SimpleSettlementInstruction>[];
    final borcMap = Map.of(borclular);
    final alacakMap = Map.of(alacaklilar);
    // Borç ve alacak kapatılana kadar devam
    while (borcMap.isNotEmpty && alacakMap.isNotEmpty) {
      final borcluId = borcMap.keys.first;
      final borcTutar = borcMap[borcluId]!;
      final alacakliId = alacakMap.keys.first;
      final alacakTutar = alacakMap[alacakliId]!;
      final odeme = borcTutar < alacakTutar ? borcTutar : alacakTutar;
      result.add(
        SimpleSettlementInstruction(
          fromUserId: borcluId,
          fromUserName: usersMap[borcluId]?.displayName ?? 'Bilinmeyen',
          toUserId: alacakliId,
          toUserName: usersMap[alacakliId]?.displayName ?? 'Bilinmeyen',
          amount: odeme,
        ),
      );
      // Bakiyeleri güncelle
      if (borcTutar <= alacakTutar + epsilon) {
        alacakMap[alacakliId] = alacakTutar - odeme;
        borcMap.remove(borcluId);
        if ((alacakMap[alacakliId] ?? 0.0) < epsilon) {
          alacakMap.remove(alacakliId);
        }
      } else {
        borcMap[borcluId] = borcTutar - odeme;
        alacakMap.remove(alacakliId);
        if ((borcMap[borcluId] ?? 0.0) < epsilon) {
          borcMap.remove(borcluId);
        }
      }
    }
    return result;
  }

  static void _upsertDebt({
    required List<DebtBetweenUsers> debts,
    required String fromUserId,
    required String toUserId,
    required double amount,
    required ExpenseModel expense,
    required GroupModel group,
    required Map<String, UserModel> usersMap,
  }) {
    if (amount <= 0.0) return;

    final detail = DebtDetail(
      expenseId: expense.id,
      expenseDescription: expense.description,
      groupId: group.id,
      groupName: group.name,
      amount: amount,
      date: expense.date,
      category: expense.category,
    );

    final existingIndex = debts.indexWhere(
      (d) => d.fromUserId == fromUserId && d.toUserId == toUserId,
    );

    if (existingIndex >= 0) {
      final existing = debts[existingIndex];
      final updatedDetails = List<DebtDetail>.from(existing.details)..add(detail);
      debts[existingIndex] = DebtBetweenUsers(
        fromUserId: fromUserId,
        fromUserName: usersMap[fromUserId]?.displayName ?? 'Bilinmeyen',
        toUserId: toUserId,
        toUserName: usersMap[toUserId]?.displayName ?? 'Bilinmeyen',
        amount: existing.amount + amount,
        groupId: group.id,
        groupName: group.name,
        details: updatedDetails,
      );
    } else {
      debts.add(
        DebtBetweenUsers(
          fromUserId: fromUserId,
          fromUserName: usersMap[fromUserId]?.displayName ?? 'Bilinmeyen',
          toUserId: toUserId,
          toUserName: usersMap[toUserId]?.displayName ?? 'Bilinmeyen',
          amount: amount,
          groupId: group.id,
          groupName: group.name,
          details: [detail],
        ),
      );
    }
  }

  static List<SimpleSettlementInstruction> _buildExpenseTransactions({
    required ExpenseModel expense,
    required Map<String, UserModel> usersMap,
  }) {
    final participants =
        expense.sharedBy.isNotEmpty ? expense.sharedBy : [expense.paidBy];
    final payerMap = expense.payerAmounts;
    final involved = <String>{...participants, ...payerMap.keys};

    final netBalances = <String, double>{};
    for (final userId in involved) {
      final paid = payerMap[userId] ?? 0.0;
      final owed =
          participants.contains(userId) ? expense.getAmountForUser(userId) : 0.0;
      final net = paid - owed;
      if (net.abs() > 0.01) {
        netBalances[userId] = net;
      }
    }

    if (netBalances.isEmpty) return const [];

    return settleDebtsFromNetBalances(
      netBalances: netBalances,
      usersMap: usersMap,
    );
  }
}
