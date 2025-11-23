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
    String? newPassword,
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
    if (newPassword != null && newPassword.isNotEmpty) {
      await user.updatePassword(newPassword);
    }

    // Firestore user dokümanını güncelle
    final updateData = {
      'displayName': displayName,
      if (photoUrl != null) 'photoUrl': photoUrl,
      'updatedAt': DateTime.now().toIso8601String(),
    };
    await FirebaseService.updateDocument(path: 'users/${user.uid}', data: updateData);
  }

  static Future<String> _uploadProfileImage(String uid, XFile file) async {
    return FirebaseService.uploadFile(
      file: file,
      path: 'profile_images/$uid.jpg',
    );
  }
}
