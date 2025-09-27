/// Middleware exception sınıfları
class MiddlewareException implements Exception {
  final String message;
  final String? code;

  const MiddlewareException(this.message, {this.code});

  @override
  String toString() => 'MiddlewareException: $message';
}

/// Yetkisiz erişim hatası
class UnauthorizedException extends MiddlewareException {
  const UnauthorizedException(super.message, {super.code});

  @override
  String toString() => 'UnauthorizedException: $message';
}

/// Yetki yetersizliği hatası
class ForbiddenException extends MiddlewareException {
  const ForbiddenException(super.message, {super.code});

  @override
  String toString() => 'ForbiddenException: $message';
}

/// Kaynak bulunamadı hatası
class NotFoundException extends MiddlewareException {
  const NotFoundException(super.message, {super.code});

  @override
  String toString() => 'NotFoundException: $message';
}

/// Geçersiz işlem hatası
class InvalidOperationException extends MiddlewareException {
  const InvalidOperationException(super.message, {super.code});

  @override
  String toString() => 'InvalidOperationException: $message';
}
