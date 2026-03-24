import 'application.dart';

class GuildApplication {
  final String id;
  final String guildId;
  final String missionId;
  final String startupId;
  final String startupName;
  final String missionTitle;
  final String message;
  final ApplicationStatus status;
  final DateTime appliedAt;
  final DateTime? updatedAt;

  const GuildApplication({
    required this.id,
    required this.guildId,
    required this.missionId,
    required this.startupId,
    required this.startupName,
    required this.missionTitle,
    required this.message,
    required this.status,
    required this.appliedAt,
    this.updatedAt,
  });

  GuildApplication copyWith({
    String? id,
    String? guildId,
    String? missionId,
    String? startupId,
    String? startupName,
    String? missionTitle,
    String? message,
    ApplicationStatus? status,
    DateTime? appliedAt,
    DateTime? updatedAt,
  }) {
    return GuildApplication(
      id: id ?? this.id,
      guildId: guildId ?? this.guildId,
      missionId: missionId ?? this.missionId,
      startupId: startupId ?? this.startupId,
      startupName: startupName ?? this.startupName,
      missionTitle: missionTitle ?? this.missionTitle,
      message: message ?? this.message,
      status: status ?? this.status,
      appliedAt: appliedAt ?? this.appliedAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'guildId': guildId,
      'missionId': missionId,
      'startupId': startupId,
      'startupName': startupName,
      'missionTitle': missionTitle,
      'message': message,
      'status': status.name,
      'appliedAt': appliedAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory GuildApplication.fromMap(Map<String, dynamic> map) {
    ApplicationStatus parseStatus(dynamic value) {
      if (value is String) {
        switch (value) {
          case 'accepted':
            return ApplicationStatus.accepted;
          case 'rejected':
            return ApplicationStatus.rejected;
          case 'interviewing':
            return ApplicationStatus.interviewing;
          case 'hired':
            return ApplicationStatus.hired;
          case 'completed':
            return ApplicationStatus.completed;
          case 'pending':
          default:
            return ApplicationStatus.pending;
        }
      }
      return ApplicationStatus.pending;
    }

    return GuildApplication(
      id: map['id'] as String? ?? '',
      guildId: map['guildId'] as String? ?? '',
      missionId: map['missionId'] as String? ?? '',
      startupId: map['startupId'] as String? ?? '',
      startupName: map['startupName'] as String? ?? '',
      missionTitle: map['missionTitle'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: parseStatus(map['status']),
      appliedAt:
          DateTime.tryParse(map['appliedAt'] as String? ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(map['updatedAt'] as String? ?? ''),
    );
  }
}
