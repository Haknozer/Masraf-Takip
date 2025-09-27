class ErrorUtils {
  /// Firebase hata mesajlarını Türkçe'ye çevir
  static String getErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Bu email adresi zaten kullanımda. Lütfen farklı bir email adresi deneyin.';
      case 'weak-password':
        return 'Şifre çok zayıf. Lütfen daha güçlü bir şifre seçin.';
      case 'user-not-found':
        return 'Bu email adresi ile kayıtlı kullanıcı bulunamadı.';
      case 'wrong-password':
        return 'Hatalı şifre. Lütfen şifrenizi kontrol edin.';
      case 'invalid-email':
        return 'Geçersiz email adresi. Lütfen doğru bir email adresi girin.';
      case 'user-disabled':
        return 'Bu hesap devre dışı bırakılmış. Lütfen destek ekibi ile iletişime geçin.';
      case 'too-many-requests':
        return 'Çok fazla deneme yapıldı. Lütfen daha sonra tekrar deneyin.';
      case 'operation-not-allowed':
        return 'Bu işlem şu anda izin verilmiyor.';
      case 'invalid-credential':
        return 'Geçersiz kimlik bilgileri.';
      case 'account-exists-with-different-credential':
        return 'Bu email adresi farklı bir giriş yöntemi ile kayıtlı.';
      case 'requires-recent-login':
        return 'Bu işlem için tekrar giriş yapmanız gerekiyor.';
      default:
        return 'Bir hata oluştu. Lütfen tekrar deneyin.';
    }
  }

  /// Hata mesajından sadece error code'u çıkar
  static String extractErrorCode(String errorMessage) {
    // Firebase hata mesajları genellikle şu formatta gelir:
    // "Exception: [firebase_auth/email-already-in-use] The email address is already in use by another account."
    final regex = RegExp(r'\[([^\]]+)\]');
    final match = regex.firstMatch(errorMessage);
    return match?.group(1)?.split('/').last ?? errorMessage;
  }

  /// Tam hata mesajını işle ve kullanıcı dostu mesaj döndür
  static String processError(dynamic error) {
    final errorString = error.toString();
    final errorCode = extractErrorCode(errorString);
    return getErrorMessage(errorCode);
  }
}
