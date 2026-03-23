import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../models/application.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_section_title.dart';

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
    switch (level) {
      case 4:
        return 900;
      case 3:
        return 500;
      case 2:
        return 200;
      default:
        return 0;
    }
  }

  int? _nextLevelTarget(int level) {
    switch (level) {
      case 1:
        return 200;
      case 2:
        return 500;
      case 3:
        return 900;
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
    final applications =
        profile != null ? appState.getApplicationsForStudent(profile.id) : <Application>[];
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
              app.mentorRating != null || app.mentorFeedbackText?.isNotEmpty == true,
        )
        .toList();
    final portfolioItems = applications
        .where(
          (app) =>
              (app.status == ApplicationStatus.completed || app.completedAt != null) &&
              app.deliverableUrl?.isNotEmpty == true,
        )
        .toList();
    final xpPoints = profile?.xpPoints ?? 0;
    final level = profile?.level ?? 1;
    final levelProgress = _levelProgress(xpPoints, level);
    final nextLevel = _nextLevelTarget(level);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: XPAppBar(
        title: 'My Profile',
        trailing: XPHeaderButton(
          icon: Icons.logout_rounded,
          foregroundColor: AppTheme.error,
          backgroundColor: AppTheme.error.withValues(alpha: 0.1),
          onTap: () => _handleLogout(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.page,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            XPSection(
              child: Column(
                children: [
                  Container(
                    width: 104,
                    height: 104,
                    decoration: const BoxDecoration(
                      color: AppTheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        profile?.name.isNotEmpty == true ? profile!.name[0].toUpperCase() : '?',
                        style: Theme.of(context).textTheme.displaySmall?.copyWith(
                              color: AppTheme.text,
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    profile?.name ?? 'Student',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  if (profile?.education?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(profile!.education!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: XPCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          backgroundColor: AppTheme.primaryLight,
                          child: Column(
                            children: [
                              Text(
                                'L$level',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              const Text('Current level'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: XPCard(
                          padding: const EdgeInsets.all(AppSpacing.md),
                          backgroundColor: AppTheme.cardBackground,
                          child: Column(
                            children: [
                              Text(
                                '$xpPoints',
                                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              const Text('XP earned'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  XPProgressBar(progress: levelProgress),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    nextLevel != null
                        ? '${nextLevel - xpPoints} XP to Level ${level + 1}'
                        : 'Max level unlocked',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            if (profile?.bio?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'About me',
                child: Text(
                  profile!.bio!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
            if (profile?.skills.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'Skills',
                child: Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: profile!.skills.map((skill) => XPSkillTag(label: skill)).toList(),
                ),
              ),
            ],
            if (reflections.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'Reflections',
                child: Column(
                  children: reflections.map((app) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: XPCard(
                        backgroundColor: AppTheme.cardBackground,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${app.roleTitle ?? 'Mission'} • ${app.startupName}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (app.reflectionDid?.isNotEmpty == true) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(app.reflectionDid!),
                            ],
                            if (app.reflectionLearned?.isNotEmpty == true) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                app.reflectionLearned!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (app.skillsPracticed.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: app.skillsPracticed
                                    .map((skill) => XPSkillTag(label: skill))
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
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'Mentor feedback',
                child: Column(
                  children: feedbackEntries.map((app) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: XPCard(
                        backgroundColor: AppTheme.cardBackground,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${app.roleTitle ?? 'Mission'} • ${app.startupName}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
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
                            if (app.mentorFeedbackText?.isNotEmpty == true) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Text(
                                app.mentorFeedbackText!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (app.endorsedSkills.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              Wrap(
                                spacing: AppSpacing.xs,
                                runSpacing: AppSpacing.xs,
                                children: app.endorsedSkills
                                    .map((skill) => XPSkillTag(label: skill, isMatched: true))
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
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'Portfolio proof',
                child: Column(
                  children: portfolioItems.map((app) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: XPCard(
                        backgroundColor: AppTheme.cardBackground,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              app.roleTitle ?? 'Mission',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: AppSpacing.xxs),
                            Text(app.startupName, style: Theme.of(context).textTheme.bodySmall),
                            const SizedBox(height: AppSpacing.sm),
                            XPBadge(
                              label: app.deliverableUrl ?? '',
                              icon: Icons.link_rounded,
                              color: AppTheme.surface,
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              'Completed ${_dateLabel(app.completedAt ?? app.appliedAt)}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            XPSection(
              child: SwitchListTile(
                value: appState.xpFeedOptOut,
                onChanged: (value) => appState.setFeedOptOut(value),
                title: Text(
                  'Share XP updates',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                subtitle: const Text('Show my first name in the XP community feed'),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            XPSection(
              title: 'Availability',
              child: XPBadge(
                label: '${profile?.availabilityHours.round() ?? 0} hours per week',
                icon: Icons.schedule_rounded,
                color: AppTheme.primaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
