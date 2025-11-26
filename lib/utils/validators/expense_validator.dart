import '../../widgets/selectors/distribution_type_selector.dart';

class ExpenseValidator {
  /// Tutar kontrolü
  static String? validateAmount(double amount) {
    if (amount <= 0) {
      return 'Tutar 0\'dan büyük olmalıdır';
    }
    return null;
  }

  /// Kategori seçimi kontrolü
  static String? validateCategory(String? categoryId) {
    if (categoryId == null) {
      return 'Lütfen bir kategori seçin (zorunlu)';
    }
    return null;
  }

  /// Üye seçimi kontrolü
  static String? validateSelectedMembers(List<String> memberIds) {
    if (memberIds.isEmpty) {
      return 'Lütfen en az bir kişi seçin';
    }
    return null;
  }

  /// Dağılım tipi kontrolü
  static String? validateDistributionType(DistributionType? type) {
    if (type == null) {
      return 'Lütfen dağılım tipini seçin';
    }
    return null;
  }

  /// Manuel dağılım tutar kontrolü
  static String? validateManualDistribution({
    required double totalAmount,
    required Map<String, double> manualAmounts,
  }) {
    final total = manualAmounts.values.fold(0.0, (sum, amt) => sum + amt);
    if ((total - totalAmount).abs() > 0.01) {
      return 'Manuel dağılım toplamı tutara eşit olmalıdır';
    }
    return null;
  }

  /// Ödeyen kişi seçimi kontrolü (Tam ödeme için)
  static String? validatePayerSelection(String? payerId) {
    if (payerId == null) {
      return 'Lütfen ödeyen kişiyi seçin';
    }
    return null;
  }

  /// Genel form doğrulama - İlk hatayı döndürür
  static String? validateForm({
    required double amount,
    required String? categoryId,
    required List<String> selectedMemberIds,
    required DistributionType? distributionType,
    required Map<String, double> manualAmounts,
    // İleride eklenebilecek parametreler
  }) {
    String? error;

    error = validateCategory(categoryId);
    if (error != null) return error;

    error = validateAmount(amount);
    if (error != null) return error;

    error = validateSelectedMembers(selectedMemberIds);
    if (error != null) return error;

    error = validateDistributionType(distributionType);
    if (error != null) return error;

    if (distributionType == DistributionType.manual) {
      error = validateManualDistribution(totalAmount: amount, manualAmounts: manualAmounts);
      if (error != null) return error;
    }

    return null;
  }
}

