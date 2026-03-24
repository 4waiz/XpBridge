import 'team_mission_config.dart';

class StartupRole {
  final String title;
  final String? commitment;
  final String? description;
  final String learningOutcome;
  final int? estimatedHours;
  final int? durationWeeks;
  final TeamMissionConfig? teamMissionConfig;

  const StartupRole({
    required this.title,
    this.commitment,
    this.description,
    this.learningOutcome = 'Outcome coming soon',
    this.estimatedHours,
    this.durationWeeks,
    this.teamMissionConfig,
  });

  bool get isTeamMission => teamMissionConfig != null;

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'commitment': commitment,
      'description': description,
      'learningOutcome': learningOutcome,
      'estimatedHours': estimatedHours,
      'durationWeeks': durationWeeks,
      'teamMissionConfig': teamMissionConfig?.toMap(),
    };
  }

  StartupRole copyWith({
    String? title,
    String? commitment,
    String? description,
    String? learningOutcome,
    int? estimatedHours,
    int? durationWeeks,
    TeamMissionConfig? teamMissionConfig,
  }) {
    return StartupRole(
      title: title ?? this.title,
      commitment: commitment ?? this.commitment,
      description: description ?? this.description,
      learningOutcome: learningOutcome ?? this.learningOutcome,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      teamMissionConfig: teamMissionConfig ?? this.teamMissionConfig,
    );
  }

  factory StartupRole.fromMap(Map<String, dynamic> map) {
    return StartupRole(
      title: map['title'] as String? ?? '',
      commitment: map['commitment'] as String?,
      description: map['description'] as String?,
      learningOutcome: map['learningOutcome'] as String? ?? '',
      estimatedHours: map['estimatedHours'] as int?,
      durationWeeks: map['durationWeeks'] as int?,
      teamMissionConfig: map['teamMissionConfig'] is Map
          ? TeamMissionConfig.fromMap(
              Map<String, dynamic>.from(map['teamMissionConfig'] as Map),
            )
          : null,
    );
  }
}
