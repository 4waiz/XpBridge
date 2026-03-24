import '../models/application.dart';
import '../models/guild.dart';
import '../models/guild_application.dart';
import '../models/skill_badge.dart';
import '../models/student_profile.dart';

class BadgeService {
  static List<SkillBadge> issueEligibleBadges({
    required List<StudentProfile> students,
    required List<Application> applications,
    required List<Guild> guilds,
    required List<GuildApplication> guildApplications,
    required List<SkillBadge> existingBadges,
  }) {
    final badges = <SkillBadge>[...existingBadges];
    final existingKeys = badges
        .map((badge) => '${badge.studentId}:${badge.badgeType.name}')
        .toSet();

    int completedCount(String studentId) {
      return applications
          .where(
            (app) =>
                app.studentId == studentId &&
                (app.status == ApplicationStatus.completed ||
                    app.completedAt != null),
          )
          .length;
    }

    bool hasPremiumEndorsement(String studentId) {
      return applications.any(
        (app) =>
            app.studentId == studentId &&
            (app.mentorRating ?? 0) >= 5 &&
            app.endorsedSkills.length >= 2,
      );
    }

    int collaborationXp(String studentId) {
      final guild = guilds.where((item) => item.memberIds.contains(studentId));
      if (guild.isEmpty) return 0;
      return guild.first.collaborationXp;
    }

    for (final student in students) {
      final completedFromApps = completedCount(student.id);
      final completed = student.missionsCompletedCount > completedFromApps
          ? student.missionsCompletedCount
          : completedFromApps;
      final collabXp = collaborationXp(student.id);
      final sharedWins = guildApplications.where(
        (item) =>
            guilds.any(
              (guild) =>
                  guild.id == item.guildId &&
                  guild.memberIds.contains(student.id) &&
                  item.status == ApplicationStatus.completed,
            ),
      );

      void maybeAddBadge({
        required SkillBadgeType type,
        required String title,
        required String description,
        required String earnedFrom,
      }) {
        final key = '${student.id}:${type.name}';
        if (existingKeys.contains(key)) return;
        badges.add(
          SkillBadge(
            id: 'badge_${student.id}_${type.name}',
            studentId: student.id,
            title: title,
            description: description,
            issuedAt: DateTime.now(),
            badgeType: type,
            earnedFrom: earnedFrom,
            verificationStatus: SkillBadgeVerificationStatus.blockchainReady,
            tokenIdOrReference:
                'XPB-${type.name.toUpperCase()}-${student.id.toUpperCase()}',
          ),
        );
        existingKeys.add(key);
      }

      if (student.level >= 10) {
        maybeAddBadge(
          type: SkillBadgeType.level10Achieved,
          title: 'Level 10 Achieved',
          description:
              'Milestone credential for sustained learning and delivery across missions.',
          earnedFrom: 'Reached Level 10 on XPBridge',
        );
      }

      if (completed >= 5) {
        maybeAddBadge(
          type: SkillBadgeType.fiveCompletedMissions,
          title: '5 Completed Missions',
          description:
              'Verified badge for completing five startup learning missions.',
          earnedFrom: 'Completed $completed missions',
        );
      }

      if (hasPremiumEndorsement(student.id)) {
        maybeAddBadge(
          type: SkillBadgeType.premiumMentorEndorsement,
          title: 'Premium Mentor Endorsement',
          description:
              'Issued after standout mentor feedback and multi-skill endorsement.',
          earnedFrom: 'Earned a top mentor endorsement',
        );
      }

      if (collabXp >= 180 || sharedWins.isNotEmpty) {
        maybeAddBadge(
          type: SkillBadgeType.topCollaborationContributor,
          title: 'Top Collaboration Contributor',
          description:
              'Non-transferable badge for meaningful contribution in guild-based missions.',
          earnedFrom: 'Reached $collabXp collaboration XP',
        );
      }
    }

    badges.sort((a, b) => b.issuedAt.compareTo(a.issuedAt));
    return badges;
  }
}
