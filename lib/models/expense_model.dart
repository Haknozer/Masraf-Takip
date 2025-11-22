class ExpenseModel {
  final String id;
  final String groupId;
  final String paidBy; // Kullanıcı ID'si
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final List<String> sharedBy; // Paylaşan kullanıcı ID'leri
  final Map<String, double>? manualAmounts; // Manuel dağılım için: userId -> amount
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  ExpenseModel({
    required this.id,
    required this.groupId,
    required this.paidBy,
    required this.description,
    required this.amount,
    required this.category,
    required this.date,
    required this.sharedBy,
    this.manualAmounts,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // JSON'dan ExpenseModel oluştur
  factory ExpenseModel.fromJson(Map<String, dynamic> json) {
    return ExpenseModel(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      paidBy: json['paidBy'] ?? '',
      description: json['description'] ?? '',
      amount: (json['amount'] ?? 0.0).toDouble(),
      category: json['category'] ?? '',
      date: DateTime.parse(json['date']),
      sharedBy: List<String>.from(json['sharedBy'] ?? []),
      manualAmounts: json['manualAmounts'] != null
          ? Map<String, double>.from(
              (json['manualAmounts'] as Map).map((key, value) => MapEntry(key.toString(), (value as num).toDouble())))
          : null,
      imageUrl: json['imageUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  // ExpenseModel'den JSON oluştur
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'paidBy': paidBy,
      'description': description,
      'amount': amount,
      'category': category,
      'date': date.toIso8601String(),
      'sharedBy': sharedBy,
      if (manualAmounts != null) 'manualAmounts': manualAmounts,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Kopya oluştur
  ExpenseModel copyWith({
    String? id,
    String? groupId,
    String? paidBy,
    String? description,
    double? amount,
    String? category,
    DateTime? date,
    List<String>? sharedBy,
    Map<String, double>? manualAmounts,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      paidBy: paidBy ?? this.paidBy,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      sharedBy: sharedBy ?? this.sharedBy,
      manualAmounts: manualAmounts ?? this.manualAmounts,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Kişi başına düşen miktar
  double get amountPerPerson {
    if (sharedBy.isEmpty) return amount;
    // Manuel dağılım varsa, kullanıcıya özel tutarı döndür
    if (manualAmounts != null && manualAmounts!.isNotEmpty) {
      // Bu method bir userId parametresi almalı, şimdilik eşit dağılım döndürüyoruz
      return amount / sharedBy.length;
    }
    return amount / sharedBy.length;
  }

  // Belirli bir kullanıcı için tutar (manuel dağılım varsa)
  double getAmountForUser(String userId) {
    if (manualAmounts != null && manualAmounts!.containsKey(userId)) {
      return manualAmounts![userId]!;
    }
    // Eşit dağılım
    if (sharedBy.isEmpty) return amount;
    return amount / sharedBy.length;
  }

  // Paylaşan kişi sayısı
  int get sharedByCount => sharedBy.length;
}
