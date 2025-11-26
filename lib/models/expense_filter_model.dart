/// Masraf filtreleme modeli
class ExpenseFilter {
  final String? searchQuery; // Metin araması
  final List<String>? categoryIds; // Kategori filtreleri (çoklu seçim)
  final double? minAmount; // Minimum tutar
  final double? maxAmount; // Maksimum tutar
  final DateTime? startDate; // Başlangıç tarihi
  final DateTime? endDate; // Bitiş tarihi
  final String? userId; // Kişi filtresi (paidBy veya sharedBy)

  const ExpenseFilter({
    this.searchQuery,
    this.categoryIds,
    this.minAmount,
    this.maxAmount,
    this.startDate,
    this.endDate,
    this.userId,
  });

  /// Filtre aktif mi?
  bool get isActive {
    return searchQuery != null && searchQuery!.trim().isNotEmpty ||
        categoryIds != null && categoryIds!.isNotEmpty ||
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
    List<String>? categoryIds,
    double? minAmount,
    double? maxAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? userId,
  }) {
    return ExpenseFilter(
      searchQuery: searchQuery ?? this.searchQuery,
      categoryIds: categoryIds ?? this.categoryIds,
      minAmount: minAmount ?? this.minAmount,
      maxAmount: maxAmount ?? this.maxAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      userId: userId ?? this.userId,
    );
  }
}
