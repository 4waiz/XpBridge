import 'startup_role.dart';
import 'team_mission_config.dart';

class Mission {
  const Mission({
    required this.id,
    required this.startupId,
    required this.startupName,
    required this.title,
    required this.description,
    this.commitment,
    this.estimatedHours,
    this.durationWeeks,
    required this.learningOutcome,
    required this.requiredSkills,
    required this.status,
    required this.createdAt,
    this.websiteUrl,
    this.logoUrl,
    this.industry,
    this.teamMissionConfig,
  });

  final String id;
  final String startupId;
  final String startupName;
  final String title;
  final String description;
  final String? commitment;
  final int? estimatedHours;
  final int? durationWeeks;
  final String learningOutcome;
  final List<String> requiredSkills;
  final String status;
  final DateTime createdAt;
  final String? websiteUrl;
  final String? logoUrl;
  final String? industry;
  final TeamMissionConfig? teamMissionConfig;

  bool get isOpen => status == 'open';
  bool get isTeamMission => teamMissionConfig != null;

  StartupRole toStartupRole() {
    return StartupRole(
      title: title,
      commitment: commitment,
      description: description,
      learningOutcome: learningOutcome,
      estimatedHours: estimatedHours,
      durationWeeks: durationWeeks,
      teamMissionConfig: teamMissionConfig,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startup_id': startupId,
      'title': title,
      'description': description,
      'commitment': commitment,
      'estimated_hours': estimatedHours,
      'duration_weeks': durationWeeks,
      'learning_outcome': learningOutcome,
      'required_skills': requiredSkills,
      'status': status,
      'created_at': createdAt.toIso8601String(),
      'website_url': websiteUrl,
      'logo_url': logoUrl,
      'industry': industry,
      'team_config': teamMissionConfig?.toMap(),
    };
  }

  Mission copyWith({
    String? id,
    String? startupId,
    String? startupName,
    String? title,
    String? description,
    String? commitment,
    int? estimatedHours,
    int? durationWeeks,
    String? learningOutcome,
    List<String>? requiredSkills,
    String? status,
    DateTime? createdAt,
    String? websiteUrl,
    String? logoUrl,
    String? industry,
    TeamMissionConfig? teamMissionConfig,
  }) {
    return Mission(
      id: id ?? this.id,
      startupId: startupId ?? this.startupId,
      startupName: startupName ?? this.startupName,
      title: title ?? this.title,
      description: description ?? this.description,
      commitment: commitment ?? this.commitment,
      estimatedHours: estimatedHours ?? this.estimatedHours,
      durationWeeks: durationWeeks ?? this.durationWeeks,
      learningOutcome: learningOutcome ?? this.learningOutcome,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      industry: industry ?? this.industry,
      teamMissionConfig: teamMissionConfig ?? this.teamMissionConfig,
    );
  }

  factory Mission.fromMap(
    Map<String, dynamic> map, {
    String? startupName,
    String? websiteUrl,
    String? logoUrl,
    String? industry,
  }) {
    final teamConfig = map['team_config'];
    return Mission(
      id: map['id'] as String? ?? '',
      startupId: map['startup_id'] as String? ?? '',
      startupName: startupName ?? map['startup_name'] as String? ?? 'Startup',
      title: map['title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      commitment: map['commitment'] as String?,
      estimatedHours: (map['estimated_hours'] as num?)?.toInt(),
      durationWeeks: (map['duration_weeks'] as num?)?.toInt(),
      learningOutcome: map['learning_outcome'] as String? ?? '',
      requiredSkills: List<String>.from(map['required_skills'] ?? const []),
      status: map['status'] as String? ?? 'open',
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      websiteUrl: websiteUrl ?? map['website_url'] as String?,
      logoUrl: logoUrl ?? map['logo_url'] as String?,
      industry: industry ?? map['industry'] as String?,
      teamMissionConfig: teamConfig is Map
          ? TeamMissionConfig.fromMap(Map<String, dynamic>.from(teamConfig))
          : null,
    );
  }
}
