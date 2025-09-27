class Validators {
  // Email doğrulama
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email adresi gerekli';
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir email adresi girin';
    }

    return null;
  }

  // Şifre doğrulama
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gerekli';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    return null;
  }

  // Şifre tekrar doğrulama
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gerekli';
    }

    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  // İsim doğrulama
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'İsim gerekli';
    }

    if (value.length < 2) {
      return 'İsim en az 2 karakter olmalı';
    }

    return null;
  }

  // Grup adı doğrulama
  static String? validateGroupName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Grup adı gerekli';
    }

    if (value.length < 2) {
      return 'Grup adı en az 2 karakter olmalı';
    }

    if (value.length > 50) {
      return 'Grup adı en fazla 50 karakter olabilir';
    }

    return null;
  }

  // Miktar doğrulama
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Miktar gerekli';
    }

    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Geçerli bir miktar girin';
    }

    if (amount <= 0) {
      return 'Miktar 0\'dan büyük olmalı';
    }

    return null;
  }

  // Açıklama doğrulama
  static String? validateDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Açıklama gerekli';
    }

    if (value.length > 200) {
      return 'Açıklama en fazla 200 karakter olabilir';
    }

    return null;
  }
}
