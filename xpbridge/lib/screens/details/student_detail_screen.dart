import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_premium.dart';
import '../../widgets/xp_section_title.dart';

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  StudentProfile? get _student {
    try {
      return DummyData.students.firstWhere((s) => s.id == studentId);
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = _student;
    final appState = AppStateScope.of(context);
    final startupSkills = appState.startupProfile?.requiredSkills ?? [];

    if (student == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: XPScene(
          compact: true,
          child: SafeArea(
            child: Column(
              children: const [
                XPAppBar(title: 'Not Found'),
                Expanded(child: Center(child: Text('Student not found'))),
              ],
            ),
          ),
        ),
      );
    }

    final matchingSkills = student.skills
        .where((skill) => startupSkills.contains(skill))
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: XPScene(
        child: SafeArea(
          child: Column(
            children: [
              XPAppBar(
                title: student.name,
                subtitle: student.education ?? 'Student',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    130,
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
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface.withValues(
                                      alpha: 0.16,
                                    ),
                                    borderRadius: BorderRadius.circular(28),
                                    border: Border.all(
                                      color: AppTheme.surface.withValues(
                                        alpha: 0.18,
                                      ),
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      student.name[0].toUpperCase(),
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(color: AppTheme.surface),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        student.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .headlineMedium
                                            ?.copyWith(color: AppTheme.surface),
                                      ),
                                      if (student.education?.isNotEmpty ==
                                          true) ...[
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          student.education!,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.surface
                                                    .withValues(alpha: 0.78),
                                              ),
                                        ),
                                      ],
                                      const SizedBox(height: AppSpacing.sm),
                                      XPBadge(
                                        label:
                                            '${student.availabilityHours.round()} hrs / week',
                                        icon: Icons.schedule_rounded,
                                        color: AppTheme.surface.withValues(
                                          alpha: 0.12,
                                        ),
                                        textColor: AppTheme.surface,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (student.bio?.isNotEmpty == true) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Text(
                                student.bio!,
                                style: Theme.of(context).textTheme.bodyLarge
                                    ?.copyWith(
                                      color: AppTheme.surface.withValues(
                                        alpha: 0.82,
                                      ),
                                    ),
                              ),
                            ],
                            if (student.portfolioUrl?.isNotEmpty == true) ...[
                              const SizedBox(height: AppSpacing.md),
                              XPBadge(
                                label: student.portfolioUrl!,
                                icon: Icons.link_rounded,
                                color: AppTheme.surface.withValues(alpha: 0.12),
                                textColor: AppTheme.surface,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (matchingSkills.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Alignment',
                          subtitle:
                              'These are the skills already overlapping with your current search.',
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
                      const SizedBox(height: AppSpacing.xl),
                      const XPSectionTitle(title: 'Skills'),
                      const SizedBox(height: AppSpacing.md),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: student.skills.map((skill) {
                          return XPSkillTag(
                            label: skill,
                            isMatched: startupSkills.contains(skill),
                          );
                        }).toList(),
                      ),
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
          label: 'Contact student',
          icon: Icons.chat_bubble_outline_rounded,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Messaging coming soon!'),
                backgroundColor: AppTheme.primary,
              ),
            );
          },
        ),
      ),
    );
  }
}
