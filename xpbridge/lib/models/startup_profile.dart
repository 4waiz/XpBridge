import 'startup_role.dart';

class StartupProfile {
  final String id;
  final String companyName;
  final String email;
  final String? phone;
  final String description;
  final String industry;
  final List<String> requiredSkills;
  final List<StartupRole> openRoles;
  final String? websiteUrl;
  final String? logoUrl;
  final String? logoBase64;
  final String? projectDetails;
  final String? profileImageUrl;
  final DateTime createdAt;

  const StartupProfile({
    required this.id,
    required this.companyName,
    required this.email,
    this.phone,
    required this.description,
    required this.industry,
    required this.requiredSkills,
    this.openRoles = const [],
    this.websiteUrl,
    this.logoUrl,
    this.logoBase64,
    this.projectDetails,
    this.profileImageUrl,
    required this.createdAt,
  });

  StartupProfile copyWith({
    String? id,
    String? companyName,
    String? email,
    String? phone,
    String? description,
    String? industry,
    List<String>? requiredSkills,
    List<StartupRole>? openRoles,
    String? websiteUrl,
    String? logoUrl,
    String? logoBase64,
    String? projectDetails,
    String? profileImageUrl,
    DateTime? createdAt,
  }) {
    return StartupProfile(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      industry: industry ?? this.industry,
      requiredSkills: requiredSkills ?? this.requiredSkills,
      openRoles: openRoles ?? this.openRoles,
      websiteUrl: websiteUrl ?? this.websiteUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      logoBase64: logoBase64 ?? this.logoBase64,
      projectDetails: projectDetails ?? this.projectDetails,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'company_name': companyName,
      'email': email,
      'phone': phone,
      'description': description,
      'industry': industry,
      'required_skills': requiredSkills,
      'open_roles': openRoles.map((role) => role.toMap()).toList(),
      'website_url': websiteUrl,
      'logo_url': logoUrl,
      'logo_base64': logoBase64,
      'project_details': projectDetails,
      'profile_image_url': profileImageUrl,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory StartupProfile.fromMap(Map<String, dynamic> map) {
    return StartupProfile(
      id: map['id'] ?? '',
      companyName: map['company_name'] ?? map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'],
      description: map['description'] ?? map['bio'] ?? '',
      industry: map['industry'] ?? '',
      requiredSkills: List<String>.from(map['required_skills'] ?? []),
      openRoles: (map['open_roles'] as List? ?? [])
          .map((roleMap) => StartupRole.fromMap(Map<String, dynamic>.from(roleMap)))
          .toList(),
      websiteUrl: map['website_url'],
      logoUrl: map['logo_url'],
      logoBase64: map['logo_base64'],
      projectDetails: map['project_details'],
      profileImageUrl: map['profile_image_url'],
      createdAt: DateTime.parse(
          map['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

