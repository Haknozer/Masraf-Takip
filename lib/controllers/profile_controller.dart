import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/auth_provider.dart';
import '../services/firebase_service.dart';

class ProfileController {
  /// Profil fotoğrafı seçimi
  static Future<XFile?> pickProfileImage() async {
    final picker = ImagePicker();
    return await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
  }

  /// Profil genel güncellemesi: ad, fotoğraf, şifre
  static Future<void> updateProfile(
    WidgetRef ref, {
    required String displayName,
    XFile? imageFile,
  }) async {
    final user = ref.read(currentUserProvider);
    if (user == null) throw Exception('Kullanıcı oturumu bulunamadı');

    // Mevcut kullanıcı modelini al (photoUrl'i korumak için)
    final userModelAsync = await ref.read(userModelProvider.future);
    String? photoUrl = userModelAsync?.photoUrl;

    // Yeni fotoğraf yükleniyorsa, storage'a yükle
    if (imageFile != null) {
      photoUrl = await _uploadProfileImage(user.uid, imageFile);
    }

    // Firebase Auth profilini güncelle
    await user.updateDisplayName(displayName);
    if (photoUrl != null) {
      await user.updatePhotoURL(photoUrl);
    }

    // Firestore user dokümanını güncelle
    final updateData = {
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await FirebaseService.updateDocument(path: 'users/${user.uid}', data: updateData);
  }

  static Future<void> changePassword(
    WidgetRef ref, {
    required String currentPassword,
    required String newPassword,
  }) async {
    // Giriş kontrolü
    if (currentPassword.isEmpty || newPassword.isEmpty) {
      throw Exception('Şifre alanları boş olamaz');
    }

    if (newPassword.length < 6) {
      throw Exception('Yeni şifre en az 6 karakter olmalıdır');
    }

    // Kullanıcı kontrolü
    final user = ref.read(currentUserProvider);
    if (user == null) {
      throw FirebaseAuthException(
        code: 'user-not-found',
        message: 'Kullanıcı oturumu bulunamadı',
      );
    }

    if (user.email == null || user.email!.isEmpty) {
      throw FirebaseAuthException(
        code: 'invalid-email',
        message: 'Kullanıcı e-posta adresi bulunamadı',
      );
    }

    try {
      // Mevcut şifre ile yeniden kimlik doğrulama
      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      // Re-authentication
      await user.reauthenticateWithCredential(credential);

      // Şifre güncelleme
      await user.updatePassword(newPassword);

      // Firestore'da güncelleme zamanını kaydet (başarısız olsa bile şifre değişmiş olabilir)
      try {
        await FirebaseService.updateDocument(
          path: 'users/${user.uid}',
          data: {
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );
      } catch (e) {
        // Firestore güncellemesi başarısız olsa bile şifre değişmiştir
        print('Firestore güncellemesi başarısız: $e');
      }

    } on FirebaseAuthException catch (e) {
      // Firebase hatalarını yeniden fırlat
      rethrow;
    } catch (e) {
      // Beklenmedik hataları FirebaseAuthException'e çevir
      throw FirebaseAuthException(
        code: 'unknown-error',
        message: e.toString(),
      );
    }
  }

  static Future<String> _uploadProfileImage(String uid, XFile file) async {
    return FirebaseService.uploadFile(
      file: file,
      path: 'profile_images/$uid.jpg',
    );
  }
}
