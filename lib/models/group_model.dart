import 'user_model.dart';

class GroupModel {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final List<String> memberIds;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  GroupModel({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.memberIds,
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
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
    );
  }

  // Üye sayısı
  int get memberCount => memberIds.length;

  // Üye ekle
  GroupModel addMember(String userId) {
    if (memberIds.contains(userId)) return this;
    return copyWith(memberIds: [...memberIds, userId], updatedAt: DateTime.now());
  }

  // Üye çıkar
  GroupModel removeMember(String userId) {
    return copyWith(memberIds: memberIds.where((id) => id != userId).toList(), updatedAt: DateTime.now());
  }
}
