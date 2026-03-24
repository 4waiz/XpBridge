class StudentProfile {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? education;
  final List<String> skills;
  final double availabilityHours;
  final String? portfolioUrl;
  final String? profileImageUrl;
  final DateTime createdAt;
  final int xpPoints;
  final int level;
  final int missionsCompletedCount;

  const StudentProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.education,
    required this.skills,
    required this.availabilityHours,
    this.portfolioUrl,
    this.profileImageUrl,
    required this.createdAt,
    this.xpPoints = 0,
    this.level = 1,
    this.missionsCompletedCount = 0,
  });

  StudentProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? bio,
    String? education,
    List<String>? skills,
    double? availabilityHours,
    String? portfolioUrl,
    String? profileImageUrl,
    DateTime? createdAt,
    int? xpPoints,
    int? level,
    int? missionsCompletedCount,
  }) {
    return StudentProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      bio: bio ?? this.bio,
      education: education ?? this.education,
      skills: skills ?? this.skills,
      availabilityHours: availabilityHours ?? this.availabilityHours,
      portfolioUrl: portfolioUrl ?? this.portfolioUrl,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
      xpPoints: xpPoints ?? this.xpPoints,
      level: level ?? this.level,
      missionsCompletedCount:
          missionsCompletedCount ?? this.missionsCompletedCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'bio': bio,
      'education': education,
      'skills': skills,
      'availability_hours': availabilityHours,
      'portfolio_url': portfolioUrl,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
      'xp_points': xpPoints,
      'level': level,
      'missions_completed_count': missionsCompletedCount,
    };
  }

  factory StudentProfile.fromMap(Map<String, dynamic> map) {
    return StudentProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      bio: map['bio'],
      education: map['education'],
      skills: List<String>.from(map['skills'] ?? []),
      availabilityHours: (map['availability_hours'] ?? 0).toDouble(),
      portfolioUrl: map['portfolio_url'],
      profileImageUrl: map['profile_image_url'],
      createdAt: DateTime.parse(
          map['created_at'] ?? DateTime.now().toIso8601String()),
      xpPoints: map['xp_points'] ?? 0,
      level: map['level'] ?? 1,
      missionsCompletedCount: map['missions_completed_count'] ?? 0,
    );
  }
}

