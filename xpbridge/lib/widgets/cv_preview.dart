import 'package:flutter/material.dart';

import '../models/cv_data.dart';
import '../theme/app_theme.dart';

/// The "right side" of the CV builder: a paper-like, scrollable rendering of
/// the AI-generated [CvData]. Mirrors the layout of the exported PDF so the
/// preview matches what the user downloads.
class CvPreview extends StatelessWidget {
  const CvPreview({super.key, required this.cv});

  final CvData cv;

  @override
  Widget build(BuildContext context) {
    if (cv.isEmpty) {
      return const _EmptyPreview();
    }

    final contact = <String>[
      if ((cv.location ?? '').trim().isNotEmpty) cv.location!.trim(),
      if ((cv.email ?? '').trim().isNotEmpty) cv.email!.trim(),
      if ((cv.phone ?? '').trim().isNotEmpty) cv.phone!.trim(),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              (cv.fullName ?? 'Your Name').trim(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.text,
                height: 1.1,
              ),
            ),
            if ((cv.headline ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                cv.headline!.trim(),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryDark,
                ),
              ),
            ],
            if (contact.isNotEmpty || cv.links.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xxs,
                children: [
                  for (final c in contact)
                    Text(c,
                        style: const TextStyle(
                            fontSize: 12, color: AppTheme.textSecondary)),
                  for (final l in cv.links)
                    Text(
                      l.url.isNotEmpty ? l.url : l.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            const Divider(color: AppTheme.primary, thickness: 1.2),
            const SizedBox(height: AppSpacing.md),
            if ((cv.summary ?? '').trim().isNotEmpty)
              _Section(
                title: 'Profile',
                child: Text(
                  cv.summary!.trim(),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.text, height: 1.5),
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
            if (cv.education.isNotEmpty)
              _Section(
                title: 'Education',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cv.education.map(_education).toList(),
                ),
              ),
            if (cv.skills.isNotEmpty)
              _Section(
                title: 'Skills',
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: cv.skills.map(_chip).toList(),
                ),
              ),
            if (cv.certifications.isNotEmpty)
              _Section(
                title: 'Certifications',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: cv.certifications.map((c) => _bullet(c)).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _experience(CvExperience e) {
    final title = [e.role, e.company]
        .where((s) => (s ?? '').trim().isNotEmpty)
        .join(' · ');
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
                  title.isEmpty ? 'Role' : title,
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
                    fontSize: 11.5, color: AppTheme.textMuted)),
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
            Text((p.name ?? 'Project').trim(),
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.text)),
            if ((p.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(p.description!.trim(),
                  style: const TextStyle(
                      fontSize: 13, color: AppTheme.text, height: 1.45)),
            ],
            if (p.tech.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(p.tech.join(' · '),
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
                        .join(' · '),
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

  Widget _chip(String label) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppTheme.primarySoft,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label,
            style: const TextStyle(
                fontSize: 12,
                color: AppTheme.text,
                fontWeight: FontWeight.w600)),
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
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryDark,
              letterSpacing: 1.4,
            ),
          ),
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
