import 'package:flutter/material.dart';

import '../../app.dart';
import '../../services/link_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_page_scaffold.dart';

class StudentDetailScreen extends StatelessWidget {
  const StudentDetailScreen({super.key, required this.studentId});

  final String studentId;

  Future<void> _openLink(BuildContext context, String? link) async {
    try {
      await LinkService.openExternal(link);
    } on XpServiceException catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final student = appState.getStudentById(studentId);
    final startupSkills = appState.startupProfile?.requiredSkills ?? [];

    if (student == null) {
      return const XPPageScaffold(
        title: 'Student',
        subtitle: 'Not found',
        showBack: true,
        compact: true,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.page),
            child: XPEmptyState(
              icon: Icons.person_search_outlined,
              title: 'Student not found',
              message: 'This profile is no longer available.',
            ),
          ),
        ),
      );
    }

    final matchingSkills = student.skills
        .where((skill) => startupSkills.contains(skill))
        .toList();
    final resumeIsImage =
        (student.resumeMimeType ?? '').toLowerCase().startsWith('image/');

    return XPPageScaffold(
      title: student.name,
      subtitle: student.education ?? 'Student profile',
      showBack: true,
      compact: true,
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
            XPCard(
              elevated: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      XPBadge(
                        label: '${student.availabilityHours.round()} hrs/week',
                        icon: Icons.schedule_rounded,
                      ),
                      XPBadge(label: 'Level ${student.level}'),
                      XPBadge(label: '${student.xpPoints} XP'),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    student.bio ?? 'No bio added yet.',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: student.skills
                        .map(
                          (skill) => XPBadge(
                            label: skill,
                            color: matchingSkills.contains(skill)
                                ? AppTheme.primarySoft
                                : null,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            XPSection(
              title: 'Proof of work',
              subtitle: 'Resume and external links are reviewable from here.',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((student.resumeUrl ?? '').isNotEmpty) ...[
                    if (resumeIsImage)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(
                          AppTheme.cornerRadius,
                        ),
                        child: Image.network(
                          student.resumeUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return XPBadge(
                              label: student.resumeFileName ?? 'Resume image',
                              icon: Icons.description_outlined,
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: AppSpacing.md),
                    XPButton(
                      label: 'Open CV',
                      icon: Icons.open_in_new_rounded,
                      onPressed: () => _openLink(context, student.resumeUrl),
                    ),
                  ] else
                    const Text('No CV uploaded yet.'),
                  if ((student.portfolioUrl ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    XPOutlinedButton(
                      label: 'Open portfolio',
                      icon: Icons.language_rounded,
                      onPressed: () => _openLink(context, student.portfolioUrl),
                    ),
                  ],
                  if ((student.githubUrl ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    XPOutlinedButton(
                      label: 'Open GitHub',
                      icon: Icons.code_rounded,
                      onPressed: () => _openLink(context, student.githubUrl),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
