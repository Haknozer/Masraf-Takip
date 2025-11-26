import '../../../models/debt_model.dart';
import 'member_breakdown_data.dart';

class MemberBreakdownCalculator {
  static MemberBreakdownData build(UserDebtSummary summary, String currentUserId) {
    final receivables = <String, MemberAmount>{};
    final payables = <String, MemberAmount>{};

    for (final groupSummary in summary.groupSummaries) {
      for (final debt in groupSummary.debts) {
        if (debt.toUserId == currentUserId) {
          receivables.update(
            debt.fromUserId,
            (existing) =>
                MemberAmount(userId: existing.userId, name: existing.name, amount: existing.amount + debt.amount),
            ifAbsent: () => MemberAmount(userId: debt.fromUserId, name: debt.fromUserName, amount: debt.amount),
          );
        } else if (debt.fromUserId == currentUserId) {
          payables.update(
            debt.toUserId,
            (existing) =>
                MemberAmount(userId: existing.userId, name: existing.name, amount: existing.amount + debt.amount),
            ifAbsent: () => MemberAmount(userId: debt.toUserId, name: debt.toUserName, amount: debt.amount),
          );
        }
      }
    }

    final receivableList = receivables.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));
    final payableList = payables.values.toList()..sort((a, b) => b.amount.compareTo(a.amount));

    return MemberBreakdownData(receivables: receivableList, payables: payableList);
  }
}

