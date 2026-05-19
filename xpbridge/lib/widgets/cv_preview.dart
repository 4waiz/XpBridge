import 'package:flutter/material.dart';

import '../models/cv_data.dart';
import '../theme/app_theme.dart';

class CvPreview extends StatelessWidget {
  const CvPreview({super.key, required this.cv});

  final CvData cv;

  @override
  Widget build(BuildContext context) {
    if (cv.isEmpty) {
      return const _EmptyPreview();
    }

    final line1 = <String>[
      if ((cv.phone ?? '').trim().isNotEmpty) cv.phone!.trim(),
      if ((cv.location ?? '').trim().isNotEmpty) cv.location!.trim(),
    ];
    final line2 = <String>[
      if ((cv.email ?? '').trim().isNotEmpty) cv.email!.trim(),
      ...cv.links.map((l) => l.label.isNotEmpty ? l.label : l.url),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
        boxShadow: AppTheme.glassShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xl,
          AppSpacing.xxxl,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Name
            Text(
              (cv.fullName ?? 'Your Name').trim(),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
                height: 1.1,
              ),
            ),
            // Headline
            if ((cv.headline ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                cv.headline!.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: AppTheme.text),
              ),
            ],
            // Contact line 1
            if (line1.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                line1.join('   ◇   '),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 11.5, color: AppTheme.textSecondary),
              ),
            ],
            // Contact line 2
            if (line2.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(
                line2.join('   ◇   '),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 11.5,
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppTheme.text, thickness: 1.5),
            const SizedBox(height: AppSpacing.md),
            // Sections (left-aligned from here)
            Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if ((cv.objective ?? '').trim().isNotEmpty)
                    _Section(
                      title: 'Objective',
                      child: Text(
                        cv.objective!.trim(),
                        style: const TextStyle(
                            fontSize: 13, color: AppTheme.text, height: 1.5),
                      ),
                    ),
                  if (cv.education.isNotEmpty)
                    _Section(
                      title: 'Education',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cv.education.map(_education).toList(),
                      ),
                    ),
                  if (cv.skillCategories.isNotEmpty)
                    _Section(
                      title: 'Skills & Abilities',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cv.skillCategories.map(_skillCategory).toList(),
                      ),
                    ),
                  if (cv.experience.isNotEmpty)
                    _Section(
                      title: 'Experience',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cv.experience.map(_experience).toList(),
                      ),
                    ),
                  if (cv.projects.isNotEmpty)
                    _Section(
                      title: 'Projects',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cv.projects.map(_project).toList(),
                      ),
                    ),
                  if (cv.achievements.isNotEmpty)
                    _Section(
                      title: 'Achievements',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: cv.achievements.map(_bullet).toList(),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _skillCategory(CvSkillCategory cat) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
        child: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: '${cat.category}: ',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.text,
                ),
              ),
              TextSpan(
                text: cat.items.join(', '),
                style: const TextStyle(fontSize: 13, color: AppTheme.text),
              ),
            ],
          ),
        ),
      );

  Widget _experience(CvExperience e) {
    final roleCompany = [e.role, e.company]
        .where((s) => (s ?? '').trim().isNotEmpty)
        .join(' — ');
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  roleCompany.isEmpty ? 'Role' : roleCompany,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.text),
                ),
              ),
              if ((e.period ?? '').trim().isNotEmpty)
                Text(e.period!.trim(),
                    style: const TextStyle(
                        fontSize: 11.5, color: AppTheme.textMuted)),
            ],
          ),
          if ((e.location ?? '').trim().isNotEmpty)
            Text(e.location!.trim(),
                style: const TextStyle(
                    fontSize: 11.5,
                    color: AppTheme.textMuted,
                    fontStyle: FontStyle.italic)),
          const SizedBox(height: AppSpacing.xxs),
          ...e.highlights.map(_bullet),
        ],
      ),
    );
  }

  Widget _project(CvProject p) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    (p.name ?? 'Project').trim(),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text),
                  ),
                ),
                if ((p.link ?? '').trim().isNotEmpty)
                  const Text('[Link]',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 3),
            ...p.highlights.map(_bullet),
            if (p.tech.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text('Stack: ${p.tech.join(', ')}',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppTheme.textMuted)),
            ],
          ],
        ),
      );

  Widget _education(CvEducation ed) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    [ed.degree, ed.institution]
                        .where((s) => (s ?? '').trim().isNotEmpty)
                        .join(', '),
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.text),
                  ),
                ),
                if ((ed.period ?? '').trim().isNotEmpty)
                  Text(ed.period!.trim(),
                      style: const TextStyle(
                          fontSize: 11.5, color: AppTheme.textMuted)),
              ],
            ),
            if ((ed.details ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(ed.details!.trim(),
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.textSecondary)),
            ],
          ],
        ),
      );

  Widget _bullet(String text) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xxs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 6, right: 8),
              child: Icon(Icons.circle, size: 5, color: AppTheme.primary),
            ),
            Expanded(
              child: Text(text,
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.text, height: 1.45)),
            ),
          ],
        ),
      );
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: AppTheme.text,
              letterSpacing: 1.2,
            ),
          ),
          const Divider(color: AppTheme.text, thickness: 0.8, height: 8),
          const SizedBox(height: AppSpacing.xs),
          child,
        ],
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
        boxShadow: AppTheme.glassShadow,
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxxl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.description_outlined,
                  size: 56, color: AppTheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Your CV will appear here',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Describe your background in the chat and the AI will build a polished CV for you.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
