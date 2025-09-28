import 'package:firebase_auth/firebase_auth.dart';
import '../exceptions/middleware_exceptions.dart';

/// Authentication middleware sınıfı
class AuthMiddleware {
  /// Kullanıcının giriş yapmış olup olmadığını kontrol et
  static void requireAuth(User? user) {
    if (user == null) {
      throw const UnauthorizedException('Bu işlem için giriş yapmalısınız');
    }
  }

  /// Kullanıcının giriş yapmamış olup olmadığını kontrol et
  static void requireGuest(User? user) {
    if (user != null) {
      throw const InvalidOperationException('Bu işlem için çıkış yapmalısınız');
    }
  }

  /// Kullanıcının email doğrulaması yapmış olup olmadığını kontrol et
  static void requireEmailVerified(User? user) {
    requireAuth(user);

    if (!user!.emailVerified) {
      throw const UnauthorizedException('Email adresinizi doğrulamalısınız');
    }
  }

  /// Kullanıcının belirli bir email domain'ine sahip olup olmadığını kontrol et
  static void requireEmailDomain(User? user, String domain) {
    requireAuth(user);

    if (!user!.email!.endsWith(domain)) {
      throw ForbiddenException('Bu işlem için $domain email adresi gereklidir');
    }
  }

  /// Kullanıcının belirli bir UID'ye sahip olup olmadığını kontrol et
  static void requireUserId(User? user, String requiredUserId) {
    requireAuth(user);

    if (user!.uid != requiredUserId) {
      throw const ForbiddenException('Bu işlem için yetkiniz yok');
    }
  }

  /// Kullanıcının belirli bir UID listesinde olup olmadığını kontrol et
  static void requireUserIdInList(User? user, List<String> allowedUserIds) {
    requireAuth(user);

    if (!allowedUserIds.contains(user!.uid)) {
      throw const ForbiddenException('Bu işlem için yetkiniz yok');
    }
  }
}
