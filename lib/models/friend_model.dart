import 'package:cloud_firestore/cloud_firestore.dart';

/// Arkadaşlık durumu
enum FriendshipStatus {
  pending, // Beklemede (istek gönderildi)
  accepted, // Kabul edildi
  blocked, // Engellendi
}

/// Arkadaşlık modeli
class FriendModel {
  final String id; // Firestore document ID
  final String userId; // İstek gönderen kullanıcı
  final String friendId; // İstek alan kullanıcı
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const FriendModel({
    required this.id,
    required this.userId,
    required this.friendId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Firestore'dan FriendModel oluştur
  factory FriendModel.fromJson(Map<String, dynamic> json) {
    return FriendModel(
      id: json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      friendId: json['friendId'] as String? ?? '',
      status: FriendshipStatus.values.firstWhere(
        (e) => e.name == (json['status'] as String? ?? 'pending'),
        orElse: () => FriendshipStatus.pending,
      ),
      createdAt: (json['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (json['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// FriendModel'i JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'friendId': friendId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Kopya oluştur
  FriendModel copyWith({
    String? id,
    String? userId,
    String? friendId,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return FriendModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      friendId: friendId ?? this.friendId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// İki kullanıcı arasında arkadaşlık var mı?
  static bool areFriends(String user1Id, String user2Id, List<FriendModel> friendships) {
    return friendships.any(
      (f) =>
          f.status == FriendshipStatus.accepted &&
          ((f.userId == user1Id && f.friendId == user2Id) || (f.userId == user2Id && f.friendId == user1Id)),
    );
  }

  /// Bekleyen arkadaşlık isteği var mı?
  static bool hasPendingRequest(String fromUserId, String toUserId, List<FriendModel> friendships) {
    return friendships.any(
      (f) => f.status == FriendshipStatus.pending && f.userId == fromUserId && f.friendId == toUserId,
    );
  }
}

/// Arkadaş detaylı bilgi (kullanıcı bilgisiyle birlikte)
class FriendWithUser {
  final FriendModel friendship;
  final String displayName;
  final String email;
  final String? photoUrl;

  const FriendWithUser({required this.friendship, required this.displayName, required this.email, this.photoUrl});

  /// Arkadaş ID'sini al (userId veya friendId - hangisi current user değilse)
  String getFriendId(String currentUserId) {
    return friendship.userId == currentUserId ? friendship.friendId : friendship.userId;
  }
}
