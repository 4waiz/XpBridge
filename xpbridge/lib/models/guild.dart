class Guild {
  final String id;
  final String name;
  final String description;
  final String ownerStudentId;
  final List<String> memberIds;
  final List<String> skillTags;
  final int collaborationXp;
  final int completedTeamMissionsCount;

  const Guild({
    required this.id,
    required this.name,
    required this.description,
    required this.ownerStudentId,
    required this.memberIds,
    this.skillTags = const [],
    this.collaborationXp = 0,
    this.completedTeamMissionsCount = 0,
  });

  Guild copyWith({
    String? id,
    String? name,
    String? description,
    String? ownerStudentId,
    List<String>? memberIds,
    List<String>? skillTags,
    int? collaborationXp,
    int? completedTeamMissionsCount,
  }) {
    return Guild(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerStudentId: ownerStudentId ?? this.ownerStudentId,
      memberIds: memberIds ?? this.memberIds,
      skillTags: skillTags ?? this.skillTags,
      collaborationXp: collaborationXp ?? this.collaborationXp,
      completedTeamMissionsCount:
          completedTeamMissionsCount ?? this.completedTeamMissionsCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'ownerStudentId': ownerStudentId,
      'memberIds': memberIds,
      'skillTags': skillTags,
      'collaborationXp': collaborationXp,
      'completedTeamMissionsCount': completedTeamMissionsCount,
    };
  }

  factory Guild.fromMap(Map<String, dynamic> map) {
    List<String> stringList(dynamic value) {
      if (value is List) {
        return value.map((item) => item.toString()).toList();
      }
      return [];
    }

    return Guild(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      ownerStudentId: map['ownerStudentId'] as String? ?? '',
      memberIds: stringList(map['memberIds']),
      skillTags: stringList(map['skillTags']),
      collaborationXp: (map['collaborationXp'] as num?)?.toInt() ?? 0,
      completedTeamMissionsCount:
          (map['completedTeamMissionsCount'] as num?)?.toInt() ?? 0,
    );
  }
}
