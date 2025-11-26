class MemberAmount {
  final String userId;
  final String name;
  final double amount;

  const MemberAmount({required this.userId, required this.name, required this.amount});
}

class MemberBreakdownData {
  final List<MemberAmount> receivables;
  final List<MemberAmount> payables;

  const MemberBreakdownData({required this.receivables, required this.payables});

  bool get hasData => receivables.isNotEmpty || payables.isNotEmpty;
}

