import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../models/application.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_mission_widgets.dart';
import '../../widgets/verified_badges_section.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_premium.dart';

class StudentProfileScreen extends StatelessWidget {
  const StudentProfileScreen({super.key});

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    final appState = AppStateScope.of(context);
    appState.logout();
    context.goNamed('login');
  }

  int _levelBase(int level) {
    if (level >= 10) return 6000;
    if (level >= 9) return 4800;
    if (level >= 8) return 3800;
    if (level >= 7) return 3000;
    if (level >= 6) return 2200;
    if (level >= 5) return 1500;
    if (level >= 4) return 900;
    if (level >= 3) return 500;
    if (level >= 2) return 200;
    return 0;
  }

  int? _nextLevelTarget(int level) {
    if (level >= 10) return null;
    switch (level) {
      case 1:
        return 200;
      case 2:
        return 500;
      case 3:
        return 900;
      case 4:
        return 1500;
      case 5:
        return 2200;
      case 6:
        return 3000;
      case 7:
        return 3800;
      case 8:
        return 4800;
      case 9:
        return 6000;
      default:
        return null;
    }
  }

  double _levelProgress(int xp, int level) {
    final next = _nextLevelTarget(level);
    if (next == null) return 1;
    final base = _levelBase(level);
    final span = (next - base).toDouble();
    if (span <= 0) return 1;
    return ((xp - base) / span).clamp(0, 1);
  }

  String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final profile = appState.studentProfile;
    final applications = profile != null
        ? appState.getApplicationsForStudent(profile.id)
        : <Application>[];
    final reflections = applications
        .where(
          (app) =>
              app.reflectionDid?.isNotEmpty == true ||
              app.reflectionLearned?.isNotEmpty == true,
        )
        .toList();
    final feedbackEntries = applications
        .where(
          (app) =>
              app.mentorRating != null ||
              app.mentorFeedbackText?.isNotEmpty == true,
        )
        .toList();
    final portfolioItems = applications
        .where(
          (app) =>
              (app.status == ApplicationStatus.completed ||
                  app.completedAt != null) &&
              app.deliverableUrl?.isNotEmpty == true,
        )
        .toList();
    final xpPoints = profile?.xpPoints ?? 0;
    final level = profile?.level ?? 1;
    final levelProgress = _levelProgress(xpPoints, level);
    final nextLevel = _nextLevelTarget(level);
    final badges = profile != null
        ? appState.getBadgesForStudent(profile.id)
        : const [];
    final currentGuild = profile != null
        ? appState.getGuildForStudent(profile.id)
        : null;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPScene(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              XPAppBar(
                title: 'Profile',
                subtitle: 'Your public career layer',
                trailing: XPHeaderButton(
                  icon: Icons.logout_rounded,
                  foregroundColor: AppTheme.error,
                  backgroundColor: AppTheme.surface.withValues(alpha: 0.72),
                  onTap: () => _handleLogout(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    AppSpacing.page,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      XPGlassPanel(
                        backgroundColor: AppTheme.primaryDeep.withValues(
                          alpha: 0.82,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryDeep,
                            AppTheme.primaryDark,
                            AppTheme.primary.withValues(alpha: 0.88),
                          ],
                        ),
                        borderColor: AppTheme.surface.withValues(alpha: 0.18),
                        shadow: AppTheme.heroCardShadow,
                        child: Column(
                          children: [
                            Container(
                              width: 108,
                              height: 108,
                              decoration: BoxDecoration(
                                color: AppTheme.surface.withValues(alpha: 0.16),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.surface.withValues(
                                    alpha: 0.24,
                                  ),
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  profile?.name.isNotEmpty == true
                                      ? profile!.name[0].toUpperCase()
                                      : '?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displayMedium
                                      ?.copyWith(
                                        color: AppTheme.surface,
                                        fontSize: 52,
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              profile?.name ?? 'Student',
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: AppTheme.surface),
                              textAlign: TextAlign.center,
                            ),
                            if (profile?.education?.isNotEmpty == true) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                profile!.education!,
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(
                                      color: AppTheme.surface.withValues(
                                        alpha: 0.82,
                                      ),
                                    ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            Row(
                              children: [
                                Expanded(
                                  child: _HeroMetric(
                                    label: 'Level',
                                    value: 'L$level',
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _HeroMetric(
                                    label: 'XP',
                                    value: '$xpPoints',
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _HeroMetric(
                                    label: 'Completed',
                                    value:
                                        '${profile?.missionsCompletedCount ?? 0}',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Theme(
                              data: Theme.of(context).copyWith(
                                progressIndicatorTheme:
                                    const ProgressIndicatorThemeData(
                                      color: AppTheme.surface,
                                      linearTrackColor: Color(0x33FFFFFF),
                                    ),
                              ),
                              child: XPProgressBar(progress: levelProgress),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              nextLevel != null
                                  ? '${nextLevel - xpPoints} XP to Level ${level + 1}'
                                  : 'Current level cap reached',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: AppTheme.surface.withValues(
                                      alpha: 0.76,
                                    ),
                                  ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      XPButton(
                        label: 'Proof of Work Portfolio',
                        icon: Icons.auto_fix_high_rounded,
                        onPressed: () => context.pushNamed('portfolioGenerator'),
                      ),
                      if (profile?.bio?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'About',
                          child: Text(
                            profile!.bio!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      if (profile?.skills.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Skills',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: profile!.skills
                                .map((skill) => XPSkillTag(label: skill))
                                .toList(),
                          ),
                        ),
                      ],
                      if (currentGuild != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Guild',
                          subtitle:
                              'Your current team, collaboration XP, and shared mission progress.',
                          action: XPOutlinedButton(
                            label: 'Open guild',
                            icon: Icons.groups_rounded,
                            expand: false,
                            size: XPButtonSize.small,
                            onPressed: () => context.pushNamed(
                              'guildDetail',
                              pathParameters: {'id': currentGuild.id},
                            ),
                          ),
                          child: GuildPreviewCard(
                            guild: currentGuild,
                            members: appState.getGuildMembers(currentGuild.id),
                            activeMissions:
                                appState.getActiveGuildMissionCount(
                                  currentGuild.id,
                                ),
                            onTap: () => context.pushNamed(
                              'guildDetail',
                              pathParameters: {'id': currentGuild.id},
                            ),
                          ),
                        ),
                      ],
                      if (profile != null) ...[
                        const SizedBox(height: AppSpacing.xl),
                        VerifiedBadgesSection(badges: badges),
                      ],
                      if (reflections.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Reflections',
                          subtitle:
                              'Snapshots of what you shipped and learned.',
                          child: Column(
                            children: reflections.map((app) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: XPCard(
                                  backgroundColor: AppTheme.surface.withValues(
                                    alpha: 0.56,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${app.roleTitle ?? 'Mission'} · ${app.startupName}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      if (app.reflectionDid?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(app.reflectionDid!),
                                      ],
                                      if (app.reflectionLearned?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          app.reflectionLearned!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                      if (app.skillsPracticed.isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Wrap(
                                          spacing: AppSpacing.xs,
                                          runSpacing: AppSpacing.xs,
                                          children: app.skillsPracticed
                                              .map(
                                                (skill) =>
                                                    XPSkillTag(label: skill),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      if (feedbackEntries.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Mentor feedback',
                          child: Column(
                            children: feedbackEntries.map((app) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: XPCard(
                                  backgroundColor: AppTheme.surface.withValues(
                                    alpha: 0.56,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${app.roleTitle ?? 'Mission'} · ${app.startupName}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      if (app.mentorRating != null) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Row(
                                          children: List.generate(
                                            5,
                                            (index) => Icon(
                                              index < app.mentorRating!
                                                  ? Icons.star_rounded
                                                  : Icons.star_border_rounded,
                                              color: AppTheme.primary,
                                              size: 18,
                                            ),
                                          ),
                                        ),
                                      ],
                                      if (app.mentorFeedbackText?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Text(
                                          app.mentorFeedbackText!,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodySmall,
                                        ),
                                      ],
                                      if (app.endorsedSkills.isNotEmpty) ...[
                                        const SizedBox(height: AppSpacing.sm),
                                        Wrap(
                                          spacing: AppSpacing.xs,
                                          runSpacing: AppSpacing.xs,
                                          children: app.endorsedSkills
                                              .map(
                                                (skill) => XPSkillTag(
                                                  label: skill,
                                                  isMatched: true,
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      if (portfolioItems.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Proof of work',
                          child: Column(
                            children: portfolioItems.map((app) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: XPCard(
                                  backgroundColor: AppTheme.surface.withValues(
                                    alpha: 0.56,
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        app.roleTitle ?? 'Mission',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        app.startupName,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      XPBadge(
                                        label: app.deliverableUrl ?? '',
                                        icon: Icons.link_rounded,
                                        color: AppTheme.primarySoft,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        'Completed ${_dateLabel(app.completedAt ?? app.appliedAt)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      XPSection(
                        child: SwitchListTile(
                          value: appState.xpFeedOptOut,
                          onChanged: (value) => appState.setFeedOptOut(value),
                          title: Text(
                            'Share XP updates',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          subtitle: const Text(
                            'Show my first name in the XP community feed',
                          ),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      XPSection(
                        title: 'Availability',
                        child: XPBadge(
                          label:
                              '${profile?.availabilityHours.round() ?? 0} hours per week',
                          icon: Icons.schedule_rounded,
                          color: AppTheme.primarySoft,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return XPGlassPanel(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      backgroundColor: AppTheme.surface.withValues(alpha: 0.12),
      borderColor: AppTheme.surface.withValues(alpha: 0.16),
      shadow: const [],
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: AppTheme.surface),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppTheme.surface.withValues(alpha: 0.76),
            ),
          ),
        ],
      ),
    );
  }
}
