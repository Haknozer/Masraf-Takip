import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../firebase_options.dart';

class FirebaseService {
  static FirebaseAuth get auth => FirebaseAuth.instance;
  static FirebaseFirestore get firestore => FirebaseFirestore.instance;
  static FirebaseStorage get storage => FirebaseStorage.instance;

  /// Firebase'i başlat
  static Future<void> initialize() async {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  /// Kullanıcı giriş durumunu kontrol et
  static Stream<User?> get authStateChanges => auth.authStateChanges();

  /// Mevcut kullanıcıyı al
  static User? get currentUser => auth.currentUser;

  /// Kullanıcı giriş yap
  static Future<UserCredential> signInWithEmailAndPassword({required String email, required String password}) async {
    return await auth.signInWithEmailAndPassword(email: email, password: password);
  }

  /// Kullanıcı kayıt ol
  static Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    return await auth.createUserWithEmailAndPassword(email: email, password: password);
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

  /// Firestore'da veri ekle
  static Future<DocumentReference> addDocument({required String collection, required Map<String, dynamic> data}) async {
    return await firestore.collection(collection).add(data);
  }

  /// Firestore'da veri güncelle
  static Future<void> updateDocument({required String path, required Map<String, dynamic> data}) async {
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
}
