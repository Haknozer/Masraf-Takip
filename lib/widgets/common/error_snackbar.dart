import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../constants/app_colors.dart';

/// Hata mesajlarını işleyen ve SnackBar gösteren utility sınıfı
class ErrorSnackBar {
  static void show(BuildContext context, Object error, {Duration? duration}) {
    final message = _processError(error);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        duration: duration ?? const Duration(seconds: 5),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message), backgroundColor: AppColors.success));
  }

  static void showWarning(BuildContext context, String message, {Duration? duration}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.warning,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  static String _processError(Object error) {
    final errorString = error.toString();

    // Middleware exception kontrolü
    if (errorString.contains('UnauthorizedException')) {
      return 'Giriş yapmanız gerekiyor. Lütfen giriş yapıp tekrar deneyin.';
    } else if (errorString.contains('ForbiddenException')) {
      return 'Bu işlem için yetkiniz yok.';
    } else if (errorString.contains('NotFoundException')) {
      return 'Kayıt bulunamadı.';
    } else if (error is FirebaseException) {
      if (error.code == 'permission-denied' || error.code == '-13021') {
        return 'Resim yükleme izni yok. Lütfen Firebase Console\'da Storage Security Rules\'ı kontrol edin.';
      } else if (error.code == 'unauthorized') {
        return 'Giriş yapmanız gerekiyor.';
      } else {
        return 'Firebase hatası: ${error.message ?? error.code}';
      }
    } else {
      return 'Bir hata oluştu: ${error.toString()}';
    }
  }
}
