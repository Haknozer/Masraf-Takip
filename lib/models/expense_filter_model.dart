/// Masraf filtreleme modeli
class ExpenseFilter {
  final String? searchQuery; // Metin araması
  final String? categoryId; // Kategori filtresi
  final double? minAmount; // Minimum tutar
  final double? maxAmount; // Maksimum tutar
  final DateTime? startDate; // Başlangıç tarihi
  final DateTime? endDate; // Bitiş tarihi
  final String? userId; // Kişi filtresi (paidBy veya sharedBy)

  const ExpenseFilter({
    this.searchQuery,
    this.categoryId,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    this.userId,
  });

  /// Filtre aktif mi?
  bool get isActive {
    return searchQuery != null && searchQuery!.trim().isNotEmpty ||
        categoryId != null ||
        minAmount != null ||
        maxAmount != null ||
        startDate != null ||
        endDate != null ||
        userId != null;
  }

  /// Filtreyi temizle
  ExpenseFilter clear() {
    return const ExpenseFilter();
  }

  /// Kopya oluştur
  ExpenseFilter copyWith({
    String? searchQuery,
    String? categoryId,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) {
    return ExpenseFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryId: categoryId ?? this.categoryId,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
    );
  }
}

