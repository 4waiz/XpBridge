import 'package:flutter/material.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
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
        backgroundColor: AppTheme.background,
        appBar: const XPAppBar(title: 'Not Found'),
        body: const Center(child: Text('Student not found')),
      );
    }

    final matchingSkills =
        student.skills.where((skill) => startupSkills.contains(skill)).toList();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: XPAppBar(
        title: student.name,
        subtitle: student.education ?? 'Student',
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          120,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            XPSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
                        ),
                        child: Center(
                          child: Text(
                            student.name[0].toUpperCase(),
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  color: AppTheme.text,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              student.name,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (student.education?.isNotEmpty == true) ...[
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                student.education!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.sm),
                            XPBadge(
                              label: '${student.availabilityHours.round()} hrs / week',
                              icon: Icons.schedule_rounded,
                              color: AppTheme.primaryLight,
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
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
                    ),
                  ],
                  if (student.portfolioUrl?.isNotEmpty == true) ...[
                    const SizedBox(height: AppSpacing.md),
                    XPBadge(
                      label: student.portfolioUrl!,
                      icon: Icons.link_rounded,
                      color: AppTheme.cardBackground,
                    ),
                  ],
                ],
              ),
            ),
            if (matchingSkills.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              XPCard(
                backgroundColor: AppTheme.primaryLight,
                radius: AppTheme.cornerRadiusLarge,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppTheme.primary,
                        borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
                      ),
                      child: const Icon(Icons.check_rounded, color: AppTheme.text),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Relevant skill match',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            '${matchingSkills.length} of your requested skills are already present: ${matchingSkills.join(', ')}.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
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
