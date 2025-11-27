enum InvitationStatus { pending, accepted, rejected }

class InvitationModel {
  final String id;
  final String groupId;
  final String groupName;
  final String inviterId;
  final String inviterName;
  final String toUserId;
  final InvitationStatus status;
  final DateTime createdAt;

  InvitationModel({
    required this.id,
    required this.groupId,
    required this.groupName,
    required this.inviterId,
    required this.inviterName,
    required this.toUserId,
    this.status = InvitationStatus.pending,
    required this.createdAt,
  });

  factory InvitationModel.fromJson(Map<String, dynamic> json) {
    return InvitationModel(
      id: json['id'] ?? '',
      groupId: json['groupId'] ?? '',
      groupName: json['groupName'] ?? '',
      inviterId: json['inviterId'] ?? '',
      inviterName: json['inviterName'] ?? '',
      toUserId: json['toUserId'] ?? '',
      status: InvitationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => InvitationStatus.pending,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'groupName': groupName,
      'inviterId': inviterId,
      'inviterName': inviterName,
      'toUserId': toUserId,
      'status': status.toString().split('.').last,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  InvitationModel copyWith({
    String? id,
    String? groupId,
    String? groupName,
    String? inviterId,
    String? inviterName,
    String? toUserId,
    InvitationStatus? status,
    DateTime? createdAt,
  }) {
    return InvitationModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      inviterId: inviterId ?? this.inviterId,
      inviterName: inviterName ?? this.inviterName,
      toUserId: toUserId ?? this.toUserId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

