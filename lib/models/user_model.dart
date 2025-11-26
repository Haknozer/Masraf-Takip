class UserModel {
  final String id;
  final String email;
  final String displayName; // Bu alan artık unique username olarak da kullanılacak
  final String? photoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  List<String> groups; // Grup ID'leri
  List<String> friends; // Arkadaş ID'leri (kabul edilmiş)
  List<String> friendRequests; // Gelen arkadaşlık istekleri
  List<String> sentRequests; // Gönderilen arkadaşlık istekleri

  UserModel({
    required this.id,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.groups,
    List<String>? friends,
    List<String>? friendRequests,
    List<String>? sentRequests,
  })  : friends = friends ?? [],
        friendRequests = friendRequests ?? [],
        sentRequests = sentRequests ?? [];

  // JSON'dan UserModel oluştur
  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      displayName: json['displayName'] ?? '',
      photoUrl: json['photoUrl'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      groups: List<String>.from(json['groups'] ?? []),
      friends: List<String>.from(json['friends'] ?? []),
      friendRequests: List<String>.from(json['friendRequests'] ?? []),
      sentRequests: List<String>.from(json['sentRequests'] ?? []),
    );
  }

  // UserModel'den JSON oluştur
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'groups': groups,
      'friends': friends,
      'friendRequests': friendRequests,
      'sentRequests': sentRequests,
    };
  }

  // Kopya oluştur
  UserModel copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? groups,
    List<String>? friends,
    List<String>? friendRequests,
    List<String>? sentRequests,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      groups: groups ?? this.groups,
      friends: friends ?? this.friends,
      friendRequests: friendRequests ?? this.friendRequests,
      sentRequests: sentRequests ?? this.sentRequests,
    );
  }
}
