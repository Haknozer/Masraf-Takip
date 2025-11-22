import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

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
    final userDoc = await FirebaseService.getDocumentSnapshot('users/${user.uid}');
    if (userDoc.exists) {
      return UserModel.fromJson(userDoc.data() as Map<String, dynamic>);
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
      final credential = await FirebaseService.signInWithEmailAndPassword(email: email, password: password);
      state = AsyncValue.data(credential.user);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Kayıt ol
  Future<void> signUp(String email, String password, String displayName) async {
    state = const AsyncValue.loading();
    try {
      final credential = await FirebaseService.createUserWithEmailAndPassword(email: email, password: password);

      // Kullanıcı profilini güncelle
      try {
        await credential.user?.updateDisplayName(displayName);
      } catch (e) {
        // Display name güncelleme hatası kritik değil, devam et
        print('Display name güncelleme hatası: $e');
      }

      // Firestore'da kullanıcı dokümanı oluştur
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        groups: [], // Boş groups array'i ekle
      );

      // Firestore'a kullanıcı dokümanını ekle
      try {
        await FirebaseService.setDocument(path: 'users/${credential.user!.uid}', data: userModel.toJson());
        print('Kullanıcı Firestore\'a eklendi: ${credential.user!.uid}');
      } catch (e) {
        print('Firestore ekleme hatası: $e');
        // Firestore hatası olsa bile kullanıcı oluşturuldu, state'i güncelle
        state = AsyncValue.data(credential.user);
        // Hatayı tekrar fırlat ki kullanıcı görsün
        rethrow;
      }

      state = AsyncValue.data(credential.user);
    } catch (e) {
      print('SignUp genel hatası: $e');
      state = AsyncValue.error(e, StackTrace.current);
      rethrow; // Hatayı tekrar fırlat
    }
  }

  // Çıkış yap
  Future<void> signOut() async {
    try {
      await FirebaseService.signOut();
      state = const AsyncValue.data(null);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }

  // Şifre sıfırlama
  Future<void> resetPassword(String email) async {
    try {
      await FirebaseService.sendPasswordResetEmail(email);
    } catch (e) {
      state = AsyncValue.error(e, StackTrace.current);
    }
  }
}

// Auth Notifier Provider
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AsyncValue<User?>>((ref) {
  return AuthNotifier();
});
