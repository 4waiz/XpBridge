class TeamMissionConfig {
  final List<String> requiredRoles;
  final int maxMembers;
  final int teamSizeMin;
  final String sharedLearningOutcome;

  const TeamMissionConfig({
    required this.requiredRoles,
    required this.maxMembers,
    required this.teamSizeMin,
    required this.sharedLearningOutcome,
  });

  TeamMissionConfig copyWith({
    List<String>? requiredRoles,
    int? maxMembers,
    int? teamSizeMin,
    String? sharedLearningOutcome,
  }) {
    return TeamMissionConfig(
      requiredRoles: requiredRoles ?? this.requiredRoles,
      maxMembers: maxMembers ?? this.maxMembers,
      teamSizeMin: teamSizeMin ?? this.teamSizeMin,
      sharedLearningOutcome:
          sharedLearningOutcome ?? this.sharedLearningOutcome,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'requiredRoles': requiredRoles,
      'maxMembers': maxMembers,
      'teamSizeMin': teamSizeMin,
      'sharedLearningOutcome': sharedLearningOutcome,
    };
  }

  factory TeamMissionConfig.fromMap(Map<String, dynamic> map) {
    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    return TeamMissionConfig(
      requiredRoles: stringList(map['requiredRoles']),
      maxMembers: (map['maxMembers'] as num?)?.toInt() ?? 4,
      teamSizeMin: (map['teamSizeMin'] as num?)?.toInt() ?? 2,
      sharedLearningOutcome:
          map['sharedLearningOutcome'] as String? ?? 'Shared outcome coming soon',
    );
  }
}
