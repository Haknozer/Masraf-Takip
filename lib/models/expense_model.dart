class ExpenseModel {
  final String id;
  final String groupId;
  final String paidBy; // Kullanıcı ID'si
  final String description;
  final double amount;
  final String category;
  final DateTime date;
  final List<String> sharedBy; // Paylaşan kullanıcı ID'leri
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
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Kişi başına düşen miktar
  double get amountPerPerson {
    if (sharedBy.isEmpty) return amount;
    return amount / sharedBy.length;
  }

  // Paylaşan kişi sayısı
  int get sharedByCount => sharedBy.length;
}
