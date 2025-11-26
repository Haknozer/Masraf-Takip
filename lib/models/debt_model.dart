
/// Borç detayı - hangi masraftan kaynaklandığı
class DebtDetail {
  final String expenseId;
  final String expenseDescription;
  final String groupId;
  final String groupName;
  final double amount;
  final DateTime date;
  final String category;

  const DebtDetail({
    required this.expenseId,
    required this.expenseDescription,
    required this.groupId,
    required this.groupName,
    required this.amount,
    required this.date,
    required this.category,
  });
}

/// İki kişi arasındaki borç özeti
class DebtBetweenUsers {
  final String fromUserId; // Borçlu
  final String fromUserName;
  final String toUserId; // Alacaklı
  final String toUserName;
  final double amount; // Toplam borç miktarı
  final String groupId;
  final String groupName;
  final List<DebtDetail> details; // Borç detayları

  const DebtBetweenUsers({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
    required this.groupId,
    required this.groupName,
    required this.details,
  });
}

/// Kullanıcının bir gruptaki borç özeti
class GroupDebtSummary {
  final String groupId;
  final String groupName;
  final double totalOwed; // Toplam borçlu olduğu
  final double totalOwing; // Toplam alacaklı olduğu
  final double netAmount; // Net durum (negatif = borçlu, pozitif = alacaklı)
  final List<DebtBetweenUsers> debts; // Detaylı borçlar

  const GroupDebtSummary({
    required this.groupId,
    required this.groupName,
    required this.totalOwed,
    required this.totalOwing,
    required this.netAmount,
    required this.debts,
  });
}

/// Kullanıcının tüm gruplardaki borç özeti
class UserDebtSummary {
  final String userId;
  final double totalOwed; // Tüm gruplarda toplam borçlu olduğu
  final double totalOwing; // Tüm gruplarda toplam alacaklı olduğu
  final double netAmount; // Net durum
  final List<GroupDebtSummary> groupSummaries; // Grup bazında özetler

  const UserDebtSummary({
    required this.userId,
    required this.totalOwed,
    required this.totalOwing,
    required this.netAmount,
    required this.groupSummaries,
  });
}

/// Basit (defter) net bakiye kaydı
class SimpleNetBalance {
  final String userId;
  final String userName;
  final double netAmount;

  const SimpleNetBalance({
    required this.userId,
    required this.userName,
    required this.netAmount,
  });
}

/// Net bakiyeye göre yapılması gereken ödeme önerisi
class SimpleSettlementInstruction {
  final String fromUserId; // Borçlu
  final String fromUserName;
  final String toUserId; // Alacaklı
  final String toUserName;
  final double amount;

  const SimpleSettlementInstruction({
    required this.fromUserId,
    required this.fromUserName,
    required this.toUserId,
    required this.toUserName,
    required this.amount,
  });
}

/// Basit eşitleme özeti
class SimpleSettlementSummary {
  final double totalExpense;
  final double averagePerPerson;
  final List<SimpleNetBalance> netBalances;
  final List<SimpleSettlementInstruction> settlementInstructions;

  const SimpleSettlementSummary({
    required this.totalExpense,
    required this.averagePerPerson,
    required this.netBalances,
    required this.settlementInstructions,
  });

  factory SimpleSettlementSummary.empty() {
    return const SimpleSettlementSummary(
      totalExpense: 0.0,
      averagePerPerson: 0.0,
      netBalances: [],
      settlementInstructions: [],
    );
  }

  bool get hasData =>
      netBalances.any((b) => b.netAmount.abs() > 0.01) ||
      settlementInstructions.isNotEmpty;
}

