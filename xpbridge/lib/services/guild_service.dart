import '../data/dummy_data.dart';
import '../models/application.dart';
import '../models/guild.dart';
import '../models/guild_application.dart';
import '../models/student_profile.dart';

class GuildService {
  static const teamRolePool = <String>[
    'Product',
    'Design',
    'Dev',
    'Marketing',
    'Data',
    'Operations',
  ];

  static List<Guild> seededGuilds() {
    return const [
      Guild(
        id: 'g1',
        name: 'Launch Loop',
        description:
            'A small builder squad combining product, UI, and mobile execution for startup MVPs.',
        ownerStudentId: 'st1',
        memberIds: ['st1', 'st2', 'st8'],
        skillTags: ['Flutter', 'Figma', 'Product Management', 'Firebase'],
        collaborationXp: 240,
        completedTeamMissionsCount: 2,
      ),
      Guild(
        id: 'g2',
        name: 'Signal Stack',
        description:
            'Growth-minded collaborators focused on research, content, and data-backed experiments.',
        ownerStudentId: 'st4',
        memberIds: ['st4', 'st16', 'st20'],
        skillTags: ['Social Media', 'Copywriting', 'User Research', 'SEO'],
        collaborationXp: 160,
        completedTeamMissionsCount: 1,
      ),
      Guild(
        id: 'g3',
        name: 'Prototype Guild',
        description:
            'Cross-functional teammates for product sprints, prototyping, and founder feedback loops.',
        ownerStudentId: 'st6',
        memberIds: ['st6', 'st15', 'st24'],
        skillTags: ['UI/UX Design', 'React', 'Node.js', 'Financial Modeling'],
        collaborationXp: 120,
        completedTeamMissionsCount: 1,
      ),
    ];
  }

  static List<GuildApplication> seededApplications() {
    return [
      GuildApplication(
        id: 'ga1',
        guildId: 'g1',
        missionId: 's9::Meal Planning Sprint Squad',
        startupId: 's9',
        startupName: 'FoodieBox',
        missionTitle: 'Meal Planning Sprint Squad',
        message:
            'We can cover product framing, UX polish, and Flutter delivery in one sprint.',
        status: ApplicationStatus.accepted,
        appliedAt: DateTime.now().subtract(const Duration(days: 6)),
        updatedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      GuildApplication(
        id: 'ga2',
        guildId: 'g2',
        missionId: 's10::Creator Growth Pod',
        startupId: 's10',
        startupName: 'SocialBuzz',
        missionTitle: 'Creator Growth Pod',
        message:
            'Our team can run user research, launch campaign tests, and package the findings clearly.',
        status: ApplicationStatus.pending,
        appliedAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
    ];
  }

  static Guild createGuild({
    required String name,
    required String description,
    required StudentProfile owner,
    List<String> skillTags = const [],
  }) {
    final mergedSkills = {...owner.skills, ...skillTags}.toList();
    return Guild(
      id: 'guild_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      ownerStudentId: owner.id,
      memberIds: [owner.id],
      skillTags: mergedSkills,
    );
  }

  static Guild mergeMemberSkills(Guild guild, List<StudentProfile> members) {
    final tags = {
      ...guild.skillTags,
      ...members.expand((member) => member.skills),
    }.toList();
    return guild.copyWith(skillTags: tags);
  }

  static GuildApplication createGuildApplication({
    required String guildId,
    required String startupId,
    required String startupName,
    required String missionTitle,
    required String message,
  }) {
    return GuildApplication(
      id: 'guild_app_${DateTime.now().millisecondsSinceEpoch}',
      guildId: guildId,
      missionId: '$startupId::$missionTitle',
      startupId: startupId,
      startupName: startupName,
      missionTitle: missionTitle,
      message: message,
      status: ApplicationStatus.pending,
      appliedAt: DateTime.now(),
    );
  }

  static ApplicationStatus nextStatus(ApplicationStatus current) {
    switch (current) {
      case ApplicationStatus.pending:
        return ApplicationStatus.interviewing;
      case ApplicationStatus.interviewing:
        return ApplicationStatus.accepted;
      case ApplicationStatus.accepted:
        return ApplicationStatus.hired;
      case ApplicationStatus.hired:
        return ApplicationStatus.completed;
      case ApplicationStatus.completed:
        return ApplicationStatus.completed;
      case ApplicationStatus.rejected:
        return ApplicationStatus.rejected;
    }
  }

  static List<String> roleMixForMembers(List<String> memberIds) {
    final skills = memberIds
        .map(
          (id) => DummyData.students
              .where((student) => student.id == id)
              .expand((student) => student.skills),
        )
        .expand((skills) => skills)
        .toSet()
        .toList();

    return teamRolePool
        .where((role) {
          final lowered = role.toLowerCase();
          return skills.any((skill) {
            final value = skill.toLowerCase();
            if (lowered == 'dev') {
              return value.contains('flutter') ||
                  value.contains('react') ||
                  value.contains('backend') ||
                  value.contains('frontend') ||
                  value.contains('python');
            }
            return value.contains(lowered);
          });
        })
        .toList();
  }
}
