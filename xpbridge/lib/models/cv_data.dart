class CvData {
  const CvData({
    this.fullName,
    this.headline,
    this.email,
    this.phone,
    this.location,
    this.links = const [],
    this.objective,
    this.experience = const [],
    this.education = const [],
    this.projects = const [],
    this.skillCategories = const [],
    this.achievements = const [],
  });

  final String? fullName;
  final String? headline;
  final String? email;
  final String? phone;
  final String? location;
  final List<CvLink> links;
  final String? objective;
  final List<CvExperience> experience;
  final List<CvEducation> education;
  final List<CvProject> projects;
  final List<CvSkillCategory> skillCategories;
  final List<String> achievements;

  static const CvData empty = CvData();

  bool get isEmpty =>
      (fullName == null || fullName!.trim().isEmpty) &&
      (objective == null || objective!.trim().isEmpty) &&
      experience.isEmpty &&
      education.isEmpty &&
      projects.isEmpty &&
      skillCategories.isEmpty;

  factory CvData.fromJson(Map<String, dynamic> json) {
    String? str(dynamic v) {
      if (v == null) return null;
      final s = v.toString().trim();
      return s.isEmpty ? null : s;
    }

    List<String> strList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return const [];
    }

    List<Map<String, dynamic>> mapList(dynamic v) {
      if (v is List) {
        return v.whereType<Map>().map((e) => e.cast<String, dynamic>()).toList();
      }
      return const [];
    }

    return CvData(
      fullName: str(json['fullName'] ?? json['name']),
      headline: str(json['headline'] ?? json['title']),
      email: str(json['email']),
      phone: str(json['phone']),
      location: str(json['location']),
      links: mapList(json['links']).map(CvLink.fromJson).toList(),
      objective: str(json['objective'] ?? json['summary'] ?? json['about']),
      experience:
          mapList(json['experience']).map(CvExperience.fromJson).toList(),
      education:
          mapList(json['education']).map(CvEducation.fromJson).toList(),
      projects: mapList(json['projects']).map(CvProject.fromJson).toList(),
      skillCategories:
          mapList(json['skillCategories']).map(CvSkillCategory.fromJson).toList(),
      achievements: strList(json['achievements'] ?? json['certifications']),
    );
  }
}

class CvLink {
  const CvLink({required this.label, required this.url});

  final String label;
  final String url;

  factory CvLink.fromJson(Map<String, dynamic> json) => CvLink(
        label: (json['label'] ?? json['name'] ?? json['url'] ?? '')
            .toString()
            .trim(),
        url: (json['url'] ?? json['href'] ?? '').toString().trim(),
      );
}

class CvSkillCategory {
  const CvSkillCategory({required this.category, required this.items});

  final String category;
  final List<String> items;

  factory CvSkillCategory.fromJson(Map<String, dynamic> json) {
    final raw = json['items'] ?? json['skills'] ?? json['values'];
    final items = raw is List
        ? raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    return CvSkillCategory(
      category: (json['category'] ?? json['name'] ?? '').toString().trim(),
      items: items,
    );
  }
}

class CvExperience {
  const CvExperience({
    this.role,
    this.company,
    this.period,
    this.location,
    this.highlights = const [],
  });

  final String? role;
  final String? company;
  final String? period;
  final String? location;
  final List<String> highlights;

  factory CvExperience.fromJson(Map<String, dynamic> json) {
    final raw = json['highlights'] ?? json['bullets'] ?? json['description'];
    final highlights = raw is List
        ? raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
        : (raw == null || raw.toString().trim().isEmpty
            ? <String>[]
            : [raw.toString().trim()]);
    return CvExperience(
      role: (json['role'] ?? json['title'] ?? json['position'])?.toString(),
      company: (json['company'] ?? json['organization'])?.toString(),
      period: (json['period'] ?? json['dates'] ?? json['duration'])?.toString(),
      location: json['location']?.toString(),
      highlights: highlights,
    );
  }
}

class CvEducation {
  const CvEducation({
    this.degree,
    this.institution,
    this.period,
    this.details,
  });

  final String? degree;
  final String? institution;
  final String? period;
  final String? details;

  factory CvEducation.fromJson(Map<String, dynamic> json) => CvEducation(
        degree: (json['degree'] ?? json['qualification'] ?? json['program'])
            ?.toString(),
        institution:
            (json['institution'] ?? json['school'] ?? json['university'])
                ?.toString(),
        period: (json['period'] ?? json['dates'] ?? json['year'])?.toString(),
        details: (json['details'] ?? json['description'])?.toString(),
      );
}

class CvProject {
  const CvProject({
    this.name,
    this.link,
    this.highlights = const [],
    this.tech = const [],
  });

  final String? name;
  final String? link;
  final List<String> highlights;
  final List<String> tech;

  factory CvProject.fromJson(Map<String, dynamic> json) {
    List<String> asList(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList();
      }
      if (v is String && v.trim().isNotEmpty) return [v.trim()];
      return <String>[];
    }

    return CvProject(
      name: (json['name'] ?? json['title'])?.toString(),
      link: (json['link'] ?? json['url'] ?? json['href'])?.toString(),
      highlights: asList(json['highlights'] ?? json['bullets'] ?? json['description']),
      tech: asList(json['tech'] ?? json['technologies'] ?? json['stack']),
    );
  }
}
