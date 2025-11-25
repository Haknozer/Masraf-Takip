/// Hesaplaşma ödeme kaydı
class SettlementPayment {
  final String id;
  final String groupId;
  final String fromUserId; // Borçlu
  final String toUserId; // Alacaklı
  final double amount; // Ödenen miktar
  final DateTime paidAt;
  final String? note; // Not

  SettlementPayment({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.paidAt,
    this.note,
  });

  factory SettlementPayment.fromJson(Map<String, dynamic> json) {
    return SettlementPayment(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      fromUserId: json['fromUserId'] ?? '',
      toUserId: json['toUserId'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      paidAt: DateTime.parse(json['paidAt']),
      note: json['note'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'amount': amount,
      'paidAt': paidAt.toIso8601String(),
      if (note != null) 'note': note,
    };
  }
}

/// Grup hesaplaşma durumu
class GroupSettlementStatus {
  final String groupId;
  final Set<String> settledUserIds; // "Kimseden alacağım yok" işaretleyen kullanıcılar
  final List<SettlementPayment> payments; // Ödeme kayıtları
  final bool isClosed; // Grup kapalı mı?

  GroupSettlementStatus({
    required this.groupId,
    required this.settledUserIds,
    required this.payments,
    this.isClosed = false,
  });

  factory GroupSettlementStatus.fromJson(Map<String, dynamic> json) {
    return GroupSettlementStatus(
      groupId: json['groupId'] ?? '',
      settledUserIds: Set<String>.from(json['settledUserIds'] ?? []),
      payments: (json['payments'] as List<dynamic>?)
              ?.map((p) => SettlementPayment.fromJson(p as Map<String, dynamic>))
              .toList() ??
          [],
      isClosed: json['isClosed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'groupId': groupId,
      'settledUserIds': settledUserIds.toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'isClosed': isClosed,
    };
  }

  GroupSettlementStatus copyWith({
    Set<String>? settledUserIds,
    List<SettlementPayment>? payments,
    bool? isClosed,
  }) {
    return GroupSettlementStatus(
      groupId: groupId,
      settledUserIds: settledUserIds ?? this.settledUserIds,
      payments: payments ?? this.payments,
      isClosed: isClosed ?? this.isClosed,
    );
  }
}

