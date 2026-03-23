import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/application.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_mission_widgets.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_premium.dart';
import '../../widgets/xp_section_title.dart';

class StartupDetailScreen extends StatefulWidget {
  const StartupDetailScreen({super.key, required this.startupId});

  final String startupId;

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen> {
  final _messageController = TextEditingController();
  bool _hasApplied = false;
  final Set<String> _appliedRoleTitles = {};

  StartupProfile? get _startup {
    try {
      return DummyData.startups.firstWhere((s) => s.id == widget.startupId);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  double _matchProgress(StartupProfile startup, List<String> studentSkills) {
    if (startup.requiredSkills.isEmpty) return 0;
    final matchCount = startup.requiredSkills
        .where((skill) => studentSkills.contains(skill))
        .length;
    return (matchCount / startup.requiredSkills.length).clamp(0, 1);
  }

  void _showApplyDialog(BuildContext context, {StartupRole? role}) {
    final roleTitle = role?.title;
    final appState = AppStateScope.of(context);
    final student = appState.studentProfile;
    final guild = student != null ? appState.getGuildForStudent(student.id) : null;
    final isTeamMission = role?.teamMissionConfig != null;

    if (isTeamMission && guild == null) {
      showModalBottomSheet(
        context: context,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => XPPremiumSheet(
          title: 'Guild required',
          subtitle:
              'This is a team mission. Join or create a guild before applying.',
          footer: XPButton(
            label: 'Open guilds',
            icon: Icons.groups_rounded,
            onPressed: () {
              Navigator.pop(sheetContext);
              context.pushNamed('guilds');
            },
          ),
          child: role?.teamMissionConfig != null
              ? TeamMissionHighlights(config: role!.teamMissionConfig!)
              : const SizedBox.shrink(),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => XPPremiumSheet(
        title: roleTitle != null
            ? isTeamMission
                ? 'Apply as guild'
                : 'Apply for $roleTitle'
            : 'Apply to ${_startup?.companyName}',
        subtitle: roleTitle != null
            ? isTeamMission
                ? 'Send a short team note explaining how your guild will cover the mission.'
                : 'Share a short note on why you are the right fit.'
            : 'Introduce yourself and explain why this company stands out.',
        footer: XPButton(
          label: isTeamMission ? 'Send guild application' : 'Send application',
          icon: Icons.arrow_upward_rounded,
          onPressed: () async {
            if (_startup == null) return;
            if (isTeamMission && guild != null && roleTitle != null) {
              final guildApplication = await appState.submitGuildApplication(
                guildId: guild.id,
                startupId: _startup!.id,
                startupName: _startup!.companyName,
                missionTitle: roleTitle,
                message: _messageController.text.isNotEmpty
                    ? _messageController.text
                    : 'Our guild is ready to take this team mission on.',
              );
              if (guildApplication == null) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Your guild already applied to this mission'),
                  ),
                );
                return;
              }
              _messageController.clear();
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Guild application sent for $roleTitle at ${_startup!.companyName}',
                  ),
                  backgroundColor: AppTheme.successDark,
                ),
              );
              return;
            }

            if (student != null) {
              final application = Application(
                id: 'app_${DateTime.now().millisecondsSinceEpoch}',
                studentId: student.id,
                startupId: _startup!.id,
                studentName: student.name,
                startupName: _startup!.companyName,
                roleTitle: roleTitle,
                status: ApplicationStatus.pending,
                message: _messageController.text.isNotEmpty
                    ? _messageController.text
                    : null,
                appliedAt: DateTime.now(),
              );
              await appState.addApplication(application);
              setState(() {
                if (roleTitle != null) {
                  _appliedRoleTitles.add(roleTitle);
                } else {
                  _hasApplied = true;
                }
              });
              _messageController.clear();
              if (!sheetContext.mounted) return;
              Navigator.pop(sheetContext);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    roleTitle != null
                        ? 'Applied for $roleTitle at ${_startup!.companyName}'
                        : 'Applied to ${_startup!.companyName}',
                  ),
                  backgroundColor: AppTheme.successDark,
                ),
              );
            }
          },
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isTeamMission && role?.teamMissionConfig != null) ...[
              XPContainer(
                color: AppTheme.primarySoft,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const TeamMissionBadge(compact: true),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          guild?.name ?? 'Guild',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TeamMissionHighlights(config: role!.teamMissionConfig!),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            XPTextField(
              controller: _messageController,
              labelText: isTeamMission ? 'Guild note' : 'Message',
              hintText: isTeamMission
                  ? 'How will your team split the work and communicate progress?'
                  : 'Why are you interested in this opportunity?',
              prefixIcon: Icons.chat_bubble_outline_rounded,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final startup = _startup;
    final appState = AppStateScope.of(context);
    final studentSkills = appState.studentProfile?.skills ?? [];

    if (startup == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: XPScene(
          compact: true,
          child: SafeArea(
            child: Column(
              children: const [
                XPAppBar(title: 'Not Found'),
                Expanded(child: Center(child: Text('Startup not found'))),
              ],
            ),
          ),
        ),
      );
    }

    final matchingSkills = startup.requiredSkills
        .where((skill) => studentSkills.contains(skill))
        .toList();
    final missingSkills = startup.requiredSkills
        .where((skill) => !studentSkills.contains(skill))
        .toList();
    final matchProgress = _matchProgress(startup, studentSkills);
    final currentGuild = appState.studentProfile != null
        ? appState.getGuildForStudent(appState.studentProfile!.id)
        : null;
    StartupRole? nextRoleToApply;
    for (final role in startup.openRoles) {
      if (!_appliedRoleTitles.contains(role.title)) {
        nextRoleToApply = role;
        break;
      }
    }
    final roleCta = nextRoleToApply;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: XPScene(
        child: SafeArea(
          child: Column(
            children: [
              XPAppBar(title: startup.companyName, subtitle: startup.industry),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      XPOpportunityCard(
                        featured: true,
                        company: startup.companyName,
                        title:
                            startup.openRoles.firstOrNull?.title ??
                            'Open opportunity',
                        description: startup.description,
                        matchLabel: '${(matchProgress * 100).round()}% fit',
                        meta: [
                          startup.industry,
                          if (startup.openRoles.firstOrNull?.commitment != null)
                            startup.openRoles.first.commitment!,
                          '${startup.requiredSkills.length} key skills',
                        ],
                        primaryLabel: startup.websiteUrl != null
                            ? 'Explore'
                            : 'Apply',
                        onPrimaryTap: startup.websiteUrl != null
                            ? null
                            : () => _showApplyDialog(context, role: roleCta),
                        skills: startup.requiredSkills
                            .map(
                              (skill) => XPSkillTag(
                                label: skill,
                                isMatched: studentSkills.contains(skill),
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      XPSection(
                        child: Row(
                          children: [
                            Expanded(
                              child: _DetailMetric(
                                label: 'Fit score',
                                value: '${(matchProgress * 100).round()}%',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _DetailMetric(
                                label: 'Open roles',
                                value: '${startup.openRoles.length}',
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _DetailMetric(
                                label: 'Matched skills',
                                value: '${matchingSkills.length}',
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (matchingSkills.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Why it matches',
                          subtitle:
                              'You already line up with some of the skills this team cares about.',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: matchingSkills
                                .map(
                                  (skill) =>
                                      XPSkillTag(label: skill, isMatched: true),
                                )
                                .toList(),
                          ),
                        ),
                      ],
                      if (missingSkills.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPGlassPanel(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          backgroundColor: AppTheme.primaryDeep.withValues(
                            alpha: 0.05,
                          ),
                          borderColor:
                              AppTheme.primaryDeep.withValues(alpha: 0.15),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    color: AppTheme.primaryDeep,
                                    size: 20,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Text(
                                    'AI Skill Gap Bridge',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          color: AppTheme.primaryDeep,
                                          fontWeight: FontWeight.w700,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                'You’re missing ${missingSkills.length} key skills for this role. Bridge the gap with these recommended micro-tasks:',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              ...missingSkills.map(
                                (skill) => Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.sm,
                                  ),
                                  child: XPCard(
                                    padding: const EdgeInsets.all(AppSpacing.sm),
                                    backgroundColor: AppTheme.surface
                                        .withValues(alpha: 0.6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.play_circle_outline_rounded,
                                          size: 20,
                                          color: AppTheme.primary,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            'Learn $skill: 15-min interactive tutorial',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ),
                                        XPBadge(
                                          label: '+5 XP',
                                          color: AppTheme.primaryDeep,
                                          textColor: AppTheme.surface,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (startup.openRoles.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        const XPSectionTitle(
                          title: 'Open roles',
                          subtitle:
                              'Apply to the role that best fits your current momentum.',
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ...startup.openRoles.map((role) {
                          final alreadyApplied = role.teamMissionConfig == null
                              ? _appliedRoleTitles.contains(role.title)
                              : (currentGuild != null &&
                                  appState
                                      .getGuildApplicationsForGuild(
                                        currentGuild.id,
                                      )
                                      .any(
                                        (application) =>
                                            application.startupId == startup.id &&
                                            application.missionTitle ==
                                                role.title,
                                      ));
                          return Padding(
                            padding: const EdgeInsets.only(
                              bottom: AppSpacing.md,
                            ),
                            child: XPCard(
                              elevated: true,
                              radius: AppTheme.cornerRadiusLarge,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (role.teamMissionConfig != null) ...[
                                              const TeamMissionBadge(compact: true),
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                            ],
                                            Text(
                                              role.title,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleLarge,
                                            ),
                                            if (role.commitment?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              XPBadge(
                                                label: role.commitment!,
                                                icon: Icons.schedule_rounded,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: AppSpacing.md),
                                      XPOutlinedButton(
                                        label: alreadyApplied
                                            ? 'Applied'
                                            : role.teamMissionConfig != null
                                                ? 'Apply as guild'
                                                : 'Apply',
                                        expand: false,
                                        size: XPButtonSize.small,
                                        onPressed: alreadyApplied
                                            ? null
                                            : () => _showApplyDialog(
                                                context,
                                                role: role,
                                              ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    role.learningOutcome,
                                    style: Theme.of(context).textTheme.bodyLarge
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                  if (role.description?.isNotEmpty == true) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    Text(
                                      role.description!,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ],
                                  if (role.teamMissionConfig != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    TeamMissionHighlights(
                                      config: role.teamMissionConfig!,
                                    ),
                                  ],
                                  if (role.estimatedHours != null ||
                                      role.durationWeeks != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: [
                                        if (role.estimatedHours != null)
                                          XPBadge(
                                            label: '${role.estimatedHours} hrs',
                                            icon: Icons.timer_outlined,
                                          ),
                                        if (role.durationWeeks != null)
                                          XPBadge(
                                            label:
                                                '${role.durationWeeks} weeks',
                                            icon: Icons.calendar_today_outlined,
                                          ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          );
                        }),
                      ],
                      if (startup.projectDetails?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'What the team is building',
                          child: Text(
                            startup.projectDetails!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      if (startup.websiteUrl?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Company link',
                          child: XPBadge(
                            label: startup.websiteUrl!,
                            icon: Icons.language_rounded,
                            color: AppTheme.primarySoft,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: XPBottomActionBar(
        child: XPButton(
          label: startup.openRoles.isNotEmpty
              ? (roleCta != null
                    ? roleCta.teamMissionConfig != null && currentGuild == null
                        ? 'Join a guild to apply'
                        : roleCta.teamMissionConfig != null
                            ? 'Apply as guild for ${roleCta.title}'
                            : 'Quick apply for ${roleCta.title}'
                    : 'Applications sent')
              : (_hasApplied ? 'Application sent' : 'Apply now'),
          icon: startup.openRoles.isNotEmpty
              ? (roleCta != null
                    ? roleCta.teamMissionConfig != null
                        ? Icons.groups_rounded
                        : Icons.auto_awesome_rounded
                    : Icons.check_circle_rounded)
              : (_hasApplied ? Icons.check_circle_rounded : Icons.send_rounded),
          onPressed: startup.openRoles.isNotEmpty
              ? (roleCta != null
                    ? () => _showApplyDialog(context, role: roleCta)
                    : null)
              : (_hasApplied ? null : () => _showApplyDialog(context)),
        ),
      ),
    );
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return XPCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppTheme.surface.withValues(alpha: 0.5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
