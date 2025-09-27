class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final Map<String, String> memberRoles; // userId -> role ('admin' or 'user')
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.memberIds,
    required this.memberRoles,
    required this.createdAt,
    required this.updatedAt,
    this.isActive = true,
  });

  // JSON'dan GroupModel oluştur
  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      memberIds: List<String>.from(json['memberIds'] ?? []),
      memberRoles: Map<String, String>.from(json['memberRoles'] ?? {}),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      isActive: json['isActive'] ?? true,
    );
  }

  // GroupModel'den JSON oluştur
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'memberRoles': memberRoles,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
    };
  }

  // Kopya oluştur
  GroupModel copyWith({
    String? id,
    String? name,
    String? description,
    String? createdBy,
    List<String>? memberIds,
    Map<String, String>? memberRoles,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
  }) {
    return GroupModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      memberRoles: memberRoles ?? this.memberRoles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Üye sayısı
  int get memberCount => memberIds.length;

  // Üye ekle
  GroupModel addMember(String userId, {String role = 'user'}) {
    if (memberIds.contains(userId)) return this;
    final newMemberIds = [...memberIds, userId];
    final newMemberRoles = {...memberRoles, userId: role};
    return copyWith(memberIds: newMemberIds, memberRoles: newMemberRoles, updatedAt: DateTime.now());
  }

  // Üye çıkar
  GroupModel removeMember(String userId) {
    final newMemberIds = memberIds.where((id) => id != userId).toList();
    final newMemberRoles = Map<String, String>.from(memberRoles);
    newMemberRoles.remove(userId);
    return copyWith(memberIds: newMemberIds, memberRoles: newMemberRoles, updatedAt: DateTime.now());
  }

  // Kullanıcının gruptaki rolünü al
  String getUserRole(String userId) {
    return memberRoles[userId] ?? 'user';
  }

  // Kullanıcı grup admin'i mi?
  bool isGroupAdmin(String userId) {
    return getUserRole(userId) == 'admin';
  }

  // Kullanıcı grup üyesi mi?
  bool isGroupMember(String userId) {
    return memberIds.contains(userId);
  }

  // Admin sayısı
  int get adminCount => memberRoles.values.where((role) => role == 'admin').length;
}
