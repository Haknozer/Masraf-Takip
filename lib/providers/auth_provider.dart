import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';

// Firebase Auth State Provider
final authStateProvider = StreamProvider<User?>((ref) {
  return FirebaseService.authStateChanges;
});

// Current User Provider
final currentUserProvider = Provider<User?>((ref) {
  return FirebaseService.currentUser;
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
      await credential.user?.updateDisplayName(displayName);

      // Firestore'da kullanıcı dokümanı oluştur
      final userModel = UserModel(
        id: credential.user!.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await FirebaseService.updateDocument(path: 'users/${credential.user!.uid}', data: userModel.toJson());

      state = AsyncValue.data(credential.user);
    } catch (e) {
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
