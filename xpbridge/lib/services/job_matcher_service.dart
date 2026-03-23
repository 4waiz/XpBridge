import '../data/dummy_data.dart';
import '../models/startup_profile.dart';
import '../models/startup_role.dart';

class MatchedRole {
  final StartupProfile startup;
  final StartupRole role;
  final double matchScore;
  final String matchReason;

  const MatchedRole({
    required this.startup,
    required this.role,
    required this.matchScore,
    required this.matchReason,
  });
}

class JobMatcherService {
  static List<MatchedRole> findMatchingRoles(
    List<String> recommendedRoles, {
    List<String>? userSkills,
  }) {
    final List<MatchedRole> matches = [];

    for (final startup in DummyData.startups) {
      for (final role in startup.openRoles) {
        final matchResult = _calculateMatch(
          role,
          startup,
          recommendedRoles,
          userSkills,
        );

        if (matchResult != null) {
          matches.add(matchResult);
        }
      }
    }

    // Sort by match score (highest first)
    matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return matches;
  }

  static MatchedRole? _calculateMatch(
    StartupRole role,
    StartupProfile startup,
    List<String> recommendedRoles,
    List<String>? userSkills,
  ) {
    double score = 0;
    final reasons = <String>[];

    final roleTitle = role.title.toLowerCase();
    final roleDescription = role.description?.toLowerCase() ?? '';

    // Check if role title matches any recommended role
    for (final recommended in recommendedRoles) {
      final recommendedLower = recommended.toLowerCase();

      // Direct title match
      if (roleTitle.contains(recommendedLower) ||
          recommendedLower.contains(roleTitle)) {
        score += 0.5;
        reasons.add('Matches recommended: $recommended');
        break;
      }

      // Keyword matching
      final keywords = _extractKeywords(recommendedLower);
      for (final keyword in keywords) {
        if (roleTitle.contains(keyword) || roleDescription.contains(keyword)) {
          score += 0.2;
          reasons.add('Related to: $recommended');
          break;
        }
      }
    }

    // Check skill overlap
    if (userSkills != null && userSkills.isNotEmpty) {
      final matchingSkills = userSkills
          .where(
            (skill) => startup.requiredSkills.any(
              (req) => req.toLowerCase() == skill.toLowerCase(),
            ),
          )
          .toList();

      if (matchingSkills.isNotEmpty) {
        score += 0.3 * (matchingSkills.length / startup.requiredSkills.length);
        reasons.add('Skills match: ${matchingSkills.join(", ")}');
      }
    }

    // Only return if there's some match
    if (score > 0) {
      return MatchedRole(
        startup: startup,
        role: role,
        matchScore: score.clamp(0.0, 1.0),
        matchReason: reasons.isNotEmpty ? reasons.first : 'Potential match',
      );
    }

    return null;
  }

  static List<String> _extractKeywords(String text) {
    // Common job-related keywords to look for
    final commonWords = {
      'intern',
      'junior',
      'senior',
      'lead',
      'manager',
      'the',
      'a',
      'an',
      'and',
      'or',
      'for',
      'with',
    };

    return text
        .split(RegExp(r'[\s/\-]+'))
        .where((word) => word.length > 2 && !commonWords.contains(word))
        .toList();
  }

  static List<MatchedRole> findRolesBySkills(List<String> skills) {
    final List<MatchedRole> matches = [];

    for (final startup in DummyData.startups) {
      final matchingSkills = skills
          .where(
            (skill) => startup.requiredSkills.any(
              (req) => req.toLowerCase() == skill.toLowerCase(),
            ),
          )
          .toList();

      if (matchingSkills.isNotEmpty) {
        final matchRatio =
            matchingSkills.length / startup.requiredSkills.length;

        for (final role in startup.openRoles) {
          matches.add(
            MatchedRole(
              startup: startup,
              role: role,
              matchScore: matchRatio,
              matchReason: 'Your skills: ${matchingSkills.join(", ")}',
            ),
          );
        }
      }
    }

    matches.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    return matches;
  }
}
