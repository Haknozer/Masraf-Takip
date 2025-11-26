import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:image_picker/image_picker.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  /// Firebase'i başlat
  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Firebase App Check'i başlat - Sadece Debug Provider
    // Not: Bu opsiyonel bir özellik, hata olsa bile uygulama çalışmaya devam eder
    try {
      await FirebaseAppCheck.instance.activate(
        androidProvider: AndroidProvider.debug, // Debug provider kullanılacak
        appleProvider: AppleProvider.debug, // iOS için debug provider
      );
      debugPrint('✅ Firebase App Check başarıyla başlatıldı (Debug provider)');
    } catch (e) {
      // App Check hatası uygulamanın çalışmasını engellemez
      debugPrint('⚠️ Firebase App Check başlatılamadı (opsiyonel): $e');
    }
  }

  /// Kullanıcı giriş durumunu kontrol et
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Mevcut kullanıcıyı al
  static User? get currentUser => auth.currentUser;

  /// Kullanıcı giriş yap
  static Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Kullanıcı kayıt ol
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Kullanıcı çıkış yap
  static Future<void> signOut() async {
    await auth.signOut();
  }

  /// Kullanıcı şifre sıfırlama
  static Future<void> sendPasswordResetEmail(String email) async {
    await auth.sendPasswordResetEmail(email: email);
  }

  /// Firestore koleksiyon referansı al
  static CollectionReference getCollection(String path) {
    return firestore.collection(path);
  }

  /// Firestore doküman referansı al
  static DocumentReference getDocument(String path) {
    return firestore.doc(path);
  }

  /// Firestore'da veri ekle (otomatik ID)
  static Future<DocumentReference> addDocument({
    required String collection,
    required Map<String, dynamic> data,
  }) async {
    return await firestore.collection(collection).add(data);
  }

  /// Firestore'da veri ekle/güncelle (belirli ID ile)
  static Future<void> setDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    await firestore.doc(path).set(data);
  }

  /// Firestore'da veri güncelle
  static Future<void> updateDocument({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    await firestore.doc(path).update(data);
  }

  /// Firestore'dan veri sil
  static Future<void> deleteDocument(String path) async {
    await firestore.doc(path).delete();
  }

  /// Firestore'dan veri oku
  static Future<DocumentSnapshot> getDocumentSnapshot(String path) async {
    return await firestore.doc(path).get();
  }

  /// Firestore koleksiyonunu dinle
  static Stream<QuerySnapshot> listenToCollection(String collection) {
    return firestore.collection(collection).snapshots();
  }

  /// Firestore dokümanını dinle
  static Stream<DocumentSnapshot> listenToDocument(String path) {
    return firestore.doc(path).snapshots();
  }

  /// Firebase Storage'a dosya yükle (XFile ile)
  static Future<String> uploadFile({
    required String path,
    required XFile file,
  }) async {
    final ref = storage.ref().child(path);
    final fileToUpload = File(file.path);
    await ref.putFile(fileToUpload);
    return await ref.getDownloadURL();
  }
}
