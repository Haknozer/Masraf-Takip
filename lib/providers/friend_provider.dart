import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/friend_model.dart';
import '../models/user_model.dart';
import '../services/firebase_service.dart';
import 'auth_provider.dart';

/// Kullanıcının arkadaşlarını dinle (users.friends array'inden - HIZLI)
final userFriendsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  // Kullanıcının dokümanını dinle
  return FirebaseService.firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
    if (!snapshot.exists) return [];
    final data = snapshot.data();
    return List<String>.from(data?['friends'] ?? []);
  });
});

/// Gelen arkadaşlık isteklerini dinle (users.friendRequests array'inden - HIZLI)
final friendRequestsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  // Kullanıcının dokümanını dinle
  return FirebaseService.firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
    if (!snapshot.exists) return [];
    final data = snapshot.data();
    return List<String>.from(data?['friendRequests'] ?? []);
  });
});

/// Gönderilen arkadaşlık isteklerini dinle (users.sentRequests array'inden - HIZLI)
final sentFriendRequestsProvider = StreamProvider.autoDispose<List<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value([]);

  // Kullanıcının dokümanını dinle
  return FirebaseService.firestore.collection('users').doc(user.uid).snapshots().map((snapshot) {
    if (!snapshot.exists) return [];
    final data = snapshot.data();
    return List<String>.from(data?['sentRequests'] ?? []);
  });
});

/// Friend Notifier
class FriendNotifier extends StateNotifier<AsyncValue<List<FriendModel>>> {
  FriendNotifier(this.ref) : super(const AsyncValue.loading());

  final Ref ref;

  /// Arkadaşlık isteği gönder (email veya kullanıcı adı ile) - TRANSACTION
  Future<void> sendFriendRequest(String emailOrUsername) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Giriş yapmanız gerekiyor');

    try {
      final searchTerm = emailOrUsername.trim().toLowerCase();
      final isEmail = searchTerm.contains('@');

      // Kullanıcıyı bul
      final usersSnapshot =
          await FirebaseService.firestore
              .collection('users')
              .where(isEmail ? 'email' : 'displayName', isEqualTo: searchTerm)
              .limit(1)
              .get();

      if (usersSnapshot.docs.isEmpty) {
        throw Exception(
          isEmail
              ? 'Bu email adresiyle kayıtlı kullanıcı bulunamadı'
              : 'Bu kullanıcı adıyla kayıtlı kullanıcı bulunamadı',
        );
      }

      final friendData = usersSnapshot.docs.first.data();
      final friendId = friendData['id'] as String;

      // Kendine istek göndermeyi engelle
      if (friendId == currentUser.uid) {
        throw Exception('Kendinize arkadaşlık isteği gönderemezsiniz');
      }

      // Kullanıcı dokümanlarını al (array kontrolü için)
      final currentUserDoc = await FirebaseService.firestore.collection('users').doc(currentUser.uid).get();
      final friendDoc = await FirebaseService.firestore.collection('users').doc(friendId).get();

      final currentUserData = currentUserDoc.data();
      final friendDataMap = friendDoc.data();

      final friends = List<String>.from(currentUserData?['friends'] ?? []);
      final sentRequests = List<String>.from(currentUserData?['sentRequests'] ?? []);
      final friendSentRequests = List<String>.from(friendDataMap?['sentRequests'] ?? []);

      // Kontroller
      if (friends.contains(friendId)) {
        throw Exception('Bu kullanıcı zaten arkadaşınız');
      }

      if (sentRequests.contains(friendId)) {
        throw Exception('Bu kullanıcıya zaten arkadaşlık isteği gönderdiniz');
      }

      if (friendSentRequests.contains(currentUser.uid)) {
        throw Exception('Bu kullanıcının size zaten bir isteği var. Gelen isteklerden kabul edebilirsiniz');
      }

      // Transaction: Her iki kullanıcıyı ve friendship'i güncelle
      await FirebaseService.firestore.runTransaction((transaction) async {
        // 1. Friendship oluştur
        final friendshipRef = FirebaseService.firestore.collection('friendships').doc();
        final friendship = FriendModel(
          id: friendshipRef.id,
          userId: currentUser.uid,
          friendId: friendId,
          status: FriendshipStatus.pending,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        transaction.set(friendshipRef, friendship.toJson());

        // 2. Gönderenin sentRequests'ine ekle
        transaction.update(currentUserDoc.reference, {
          'sentRequests': FieldValue.arrayUnion([friendId]),
        });

        // 3. Alıcının friendRequests'ine ekle
        transaction.update(friendDoc.reference, {
          'friendRequests': FieldValue.arrayUnion([currentUser.uid]),
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Arkadaşlık isteğini kabul et - TRANSACTION
  Future<void> acceptFriendRequest(String requesterId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Giriş yapmanız gerekiyor');

    try {
      // Friendship dokümanını bul
      final friendshipSnapshot =
          await FirebaseService.firestore
              .collection('friendships')
              .where('userId', isEqualTo: requesterId)
              .where('friendId', isEqualTo: currentUser.uid)
              .where('status', isEqualTo: 'pending')
              .limit(1)
              .get();

      if (friendshipSnapshot.docs.isEmpty) {
        throw Exception('Arkadaşlık isteği bulunamadı');
      }

      final friendshipDoc = friendshipSnapshot.docs.first;
      final currentUserDoc = FirebaseService.firestore.collection('users').doc(currentUser.uid);
      final requesterDoc = FirebaseService.firestore.collection('users').doc(requesterId);

      // Transaction: Friendship'i güncelle ve her iki kullanıcının array'lerini güncelle
      await FirebaseService.firestore.runTransaction((transaction) async {
        // 1. Friendship'i accepted yap
        transaction.update(friendshipDoc.reference, {
          'status': FriendshipStatus.accepted.name,
          'updatedAt': Timestamp.fromDate(DateTime.now()),
        });

        // 2. Her iki kullanıcının friends array'ine ekle
        transaction.update(currentUserDoc, {
          'friends': FieldValue.arrayUnion([requesterId]),
          'friendRequests': FieldValue.arrayRemove([requesterId]), // İstekten kaldır
        });

        transaction.update(requesterDoc, {
          'friends': FieldValue.arrayUnion([currentUser.uid]),
          'sentRequests': FieldValue.arrayRemove([currentUser.uid]), // Gönderilenden kaldır
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Arkadaşlık isteğini reddet veya arkadaşlığı kaldır - TRANSACTION
  /// Parametre: otherUserId - diğer kullanıcının ID'si
  Future<void> removeFriendship(String otherUserId) async {
    final currentUser = ref.read(currentUserProvider);
    if (currentUser == null) throw Exception('Giriş yapmanız gerekiyor');

    try {
      // Friendship dokümanını bul (her iki yönde de)
      final firstTry =
          await FirebaseService.firestore
              .collection('friendships')
              .where('userId', isEqualTo: currentUser.uid)
              .where('friendId', isEqualTo: otherUserId)
              .limit(1)
              .get();

      DocumentSnapshot<Map<String, dynamic>>? friendshipDoc;

      if (firstTry.docs.isNotEmpty) {
        friendshipDoc = firstTry.docs.first;
      } else {
        final secondTry =
            await FirebaseService.firestore
                .collection('friendships')
                .where('userId', isEqualTo: otherUserId)
                .where('friendId', isEqualTo: currentUser.uid)
                .limit(1)
                .get();

        if (secondTry.docs.isNotEmpty) {
          friendshipDoc = secondTry.docs.first;
        }
      }

      if (friendshipDoc == null || !friendshipDoc.exists) {
        throw Exception('Arkadaşlık kaydı bulunamadı');
      }

      final friendshipData = friendshipDoc.data() as Map<String, dynamic>;
      final userId = friendshipData['userId'] as String;
      final friendId = friendshipData['friendId'] as String;
      final status = friendshipData['status'] as String;

      // Gerçek diğer kullanıcı ID'sini belirle (yön bağımsız)
      final resolvedOtherUserId = userId == currentUser.uid ? friendId : userId;

      final currentUserDoc = FirebaseService.firestore.collection('users').doc(currentUser.uid);
      final otherUserDoc = FirebaseService.firestore.collection('users').doc(resolvedOtherUserId);

      // Transaction: Friendship'i sil ve kullanıcıların array'lerinden kaldır
      await FirebaseService.firestore.runTransaction((transaction) async {
        // 1. Friendship'i sil
        transaction.delete(friendshipDoc!.reference);

        // 2. Array'lerden kaldır
        if (status == 'accepted') {
          // Arkadaşlık kabul edilmişse friends'ten kaldır
          transaction.update(currentUserDoc, {
            'friends': FieldValue.arrayRemove([resolvedOtherUserId]),
          });
          transaction.update(otherUserDoc, {
            'friends': FieldValue.arrayRemove([currentUser.uid]),
          });
        } else if (status == 'pending') {
          // Bekleyen istekse sentRequests ve friendRequests'ten kaldır
          if (userId == currentUser.uid) {
            // Ben gönderdim, iptal ediyorum
            transaction.update(currentUserDoc, {
              'sentRequests': FieldValue.arrayRemove([resolvedOtherUserId]),
            });
            transaction.update(otherUserDoc, {
              'friendRequests': FieldValue.arrayRemove([currentUser.uid]),
            });
          } else {
            // Bana gönderildi, reddediyorum
            transaction.update(currentUserDoc, {
              'friendRequests': FieldValue.arrayRemove([resolvedOtherUserId]),
            });
            transaction.update(otherUserDoc, {
              'sentRequests': FieldValue.arrayRemove([currentUser.uid]),
            });
          }
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  /// Email ile kullanıcı ara
  Future<List<UserModel>> searchUsersByEmail(String email) async {
    if (email.trim().isEmpty) return [];

    try {
      final snapshot =
          await FirebaseService.firestore
              .collection('users')
              .where('email', isGreaterThanOrEqualTo: email.trim().toLowerCase())
              .where('email', isLessThan: '${email.trim().toLowerCase()}z')
              .limit(10)
              .get();

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserModel.fromJson(data);
      }).toList();
    } catch (e) {
      return [];
    }
  }
}

/// Friend Notifier Provider
final friendNotifierProvider = StateNotifierProvider<FriendNotifier, AsyncValue<List<FriendModel>>>((ref) {
  return FriendNotifier(ref);
});
