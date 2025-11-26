import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import '../services/log_service.dart';

// Firebase Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.authStateChanges;
});

// Current User Provider - authStateProvider'dan türetilmiş
final currentUserProvider = Provider<User?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull;
});

// User Model Provider
final userModelProvider = FutureProvider<UserModel?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    // Retry mekanizması: 5 kere dene, her seferinde 500ms bekle
    for (int i = 0; i < 5; i++) {
      final userDoc = await FirebaseService.getDocumentSnapshot('users/${user.uid}');
      if (userDoc.exists) {
        return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
      }
      
      // Son denemede bekleme yapma
      if (i < 4) {
        await Future.delayed(const Duration(milliseconds: 500));
      }
    }

    return null;
  } catch (e) {
    return null;
  }
});

// Kullanıcının doküman ID'sini al
final userDocumentIdProvider = FutureProvider<String?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;

  try {
    // Users koleksiyonundan kullanıcının dokümanını bul
    final snapshot =
        await FirebaseService.firestore.collection('users').where('id', isEqualTo: user.uid).limit(1).get();

    if (snapshot.docs.isNotEmpty) {
      return snapshot.docs.first.id; // Doküman ID'sini döndür
    }
    return null;
  } catch (e) {
    return null;
  }
});

// Auth Service Provider
class AuthNotifier extends StateNotifier<AsyncValue<User?>> {
  AuthNotifier() : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    FirebaseService.authStateChanges.listen((user) {
      state = AsyncValue.data(user);
    });
  }

  // Giriş yap
  Future<void> signIn(String email, String password) async {
    state = const AsyncValue.loading();
    try {
      LogService.info('Giriş denemesi: $email');
      final credential = await FirebaseService.signInWithEmailAndPassword(email: email, password: password);
      state = AsyncValue.data(credential.user);
      LogService.info('Giriş başarılı: ${credential.user?.uid}');
      LogService.logUserAction('user_login', data: {'email': email});
    } catch (e, stackTrace) {
      LogService.error('Giriş hatası: $email', e, stackTrace);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Kayıt ol
  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      LogService.info('Yeni kayıt denemesi: $email');

      // DisplayName'i küçük harfe çevir ve trim et
      final normalizedDisplayName = displayName.trim().toLowerCase();

      // DisplayName'in unique olup olmadığını kontrol et (küçük harfle)
      final displayNameCheck = await FirebaseService.firestore
          .collection('users')
          .where('displayName', isEqualTo: normalizedDisplayName)
          .limit(1)
          .get();

      if (displayNameCheck.docs.isNotEmpty) {
        throw Exception('Bu kullanıcı adı zaten kullanılıyor');
      }

      final credential = await FirebaseService.createUserWithEmailAndPassword(email: email, password: password);

      // Kullanıcı profilini güncelle (orijinal displayName ile - UI'da gösterilecek)
      try {
        await credential.user?.updateDisplayName(displayName.trim());
      } catch (e) {
        // Display name güncelleme hatası kritik değil, devam et
        LogService.warning('Display name güncelleme hatası: $email', e);
      }

      // Firestore'da kullanıcı dokümanı oluştur
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        displayName: normalizedDisplayName, // Küçük harfle kaydet
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        groups: [], // Boş groups array'i ekle
        friends: [], // Boş friends array'i ekle
        friendRequests: [], // Boş friend requests array'i ekle
        sentRequests: [], // Boş sent requests array'i ekle
      );

      // Firestore'a kullanıcı dokümanını ekle
      try {
        await FirebaseService.setDocument(path: 'users/${credential.user!.uid}', data: userModel.toJson());
        LogService.debug('Kullanıcı Firestore\'a eklendi: ${credential.user!.uid}');
        
        // Firestore'a yazma işleminin tamamlandığından emin olmak için kısa bir bekleme
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e, stackTrace) {
        LogService.error('Firestore ekleme hatası: $email', e, stackTrace);
        // Firestore hatası olsa bile kullanıcı oluşturuldu, state'i güncelle
        state = AsyncValue.data(credential.user);
        // Hatayı tekrar fırlat ki kullanıcı görsün
        rethrow;
      }

      state = AsyncValue.data(credential.user);
      LogService.info('Kayıt başarılı: ${credential.user?.uid}');
      LogService.logUserAction('user_signup', data: {'email': email, 'displayName': displayName});
    } catch (e, stackTrace) {
      LogService.error('SignUp genel hatası: $email', e, stackTrace);
      state = AsyncValue.error(e, StackTrace.current);
      rethrow; // Hatayı tekrar fırlat
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      final currentUser = FirebaseService.currentUser;
      LogService.info('Çıkış yapılıyor: ${currentUser?.email}');
      await FirebaseService.signOut();
      state = const AsyncValue.data(null);
      LogService.logUserAction('user_logout', data: {'email': currentUser?.email});
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      LogService.info('Şifre sıfırlama talebi: $email');
      await FirebaseService.sendPasswordResetEmail(email);
      LogService.info('Şifre sıfırlama e-postası gönderildi: $email');
      LogService.logUserAction('password_reset_requested', data: {'email': email});
    } catch (e, stackTrace) {
      LogService.error('Şifre sıfırlama hatası: $email', e, stackTrace);
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Auth Notifier Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});
