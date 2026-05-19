/// Structured CV produced by the AI from the user's plain-English chat.
///
/// The AI returns this shape as JSON; we render it natively in Flutter for the
/// live preview and feed it into the PDF exporter. Every field is optional so a
/// partially-built CV still renders cleanly while the conversation is ongoing.
class CvData {
  const CvData({
    this.fullName,
    this.headline,
    this.email,
    this.phone,
    this.location,
    this.links = const [],
    this.summary,
    this.experience = const [],
    this.education = const [],
    this.projects = const [],
    this.skills = const [],
    this.certifications = const [],
  });

  final String? fullName;
  final String? headline;
  final String? email;
  final String? phone;
  final String? location;
  final List<CvLink> links;
  final String? summary;
  final List<CvExperience> experience;
  final List<CvEducation> education;
  final List<CvProject> projects;
  final List<String> skills;
  final List<String> certifications;

  static const CvData empty = CvData();

  /// True when the AI hasn't produced anything renderable yet.
  bool get isEmpty =>
      (fullName == null || fullName!.trim().isEmpty) &&
      (summary == null || summary!.trim().isEmpty) &&
      experience.isEmpty &&
      education.isEmpty &&
      projects.isEmpty &&
      skills.isEmpty;

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
      summary: str(json['summary'] ?? json['about']),
      experience:
          mapList(json['experience']).map(CvExperience.fromJson).toList(),
      education:
          mapList(json['education']).map(CvEducation.fromJson).toList(),
      projects: mapList(json['projects']).map(CvProject.fromJson).toList(),
      skills: strList(json['skills']),
      certifications: strList(json['certifications']),
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
  const CvProject({this.name, this.description, this.tech = const []});

  final String? name;
  final String? description;
  final List<String> tech;

  factory CvProject.fromJson(Map<String, dynamic> json) {
    final raw = json['tech'] ?? json['technologies'] ?? json['stack'];
    final tech = raw is List
        ? raw
            .map((e) => e?.toString().trim() ?? '')
            .where((e) => e.isNotEmpty)
            .toList()
        : <String>[];
    return CvProject(
      name: (json['name'] ?? json['title'])?.toString(),
      description: (json['description'] ?? json['summary'])?.toString(),
      tech: tech,
    );
  }
}
