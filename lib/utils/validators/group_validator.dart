class GroupValidator {
  /// Grup adı kontrolü
  static String? validateName(String? name) {
    if (name == null || name.trim().isEmpty) {
      return 'Grup adı gereklidir';
    }
    if (name.trim().length < 3) {
      return 'Grup adı en az 3 karakter olmalıdır';
    }
    return null;
  }

  /// Grup ID kontrolü
  static String? validateGroupId(String? groupId) {
    if (groupId == null || groupId.trim().isEmpty) {
      return 'Grup ID geçersiz';
    }
    return null;
  }
}

