import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/application.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
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

  void _showApplyDialog(BuildContext context, {StartupRole? role}) {
    final roleTitle = role?.title;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetContext).viewInsets.bottom,
          left: AppSpacing.md,
          right: AppSpacing.md,
          top: AppSpacing.md,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
            boxShadow: AppTheme.elevatedShadow,
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  roleTitle != null
                      ? 'Apply for $roleTitle'
                      : 'Apply to ${_startup?.companyName}',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  roleTitle != null
                      ? 'Share a short note explaining why you are a fit for this role.'
                      : 'Introduce yourself and explain why this startup caught your attention.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: AppSpacing.xl),
                XPTextField(
                  controller: _messageController,
                  labelText: 'Message',
                  hintText: 'Why are you interested in this opportunity?',
                  prefixIcon: Icons.chat_bubble_outline_rounded,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.xl),
                XPButton(
                  label: 'Send application',
                  icon: Icons.send_rounded,
                  onPressed: () async {
                    final appState = AppStateScope.of(context);
                    final student = appState.studentProfile;

                    if (student != null && _startup != null) {
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
              ],
            ),
          ),
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
        backgroundColor: AppTheme.background,
        appBar: const XPAppBar(title: 'Not Found'),
        body: const Center(child: Text('Startup not found')),
      );
    }

    final matchingSkills =
        startup.requiredSkills.where((skill) => studentSkills.contains(skill)).toList();
    StartupRole? nextRoleToApply;
    for (final role in startup.openRoles) {
      if (!_appliedRoleTitles.contains(role.title)) {
        nextRoleToApply = role;
        break;
      }
    }
    final roleCta = nextRoleToApply;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: XPAppBar(
        title: startup.companyName,
        subtitle: startup.industry,
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
                        width: 74,
                        height: 74,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
                        ),
                        child: Center(
                          child: Text(
                            startup.companyName[0].toUpperCase(),
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
                            XPBadge(
                              label: startup.industry,
                              color: AppTheme.primaryLight,
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              startup.companyName,
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            if (startup.websiteUrl != null) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                startup.websiteUrl!,
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: AppTheme.textSecondary,
                                    ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    startup.description,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                  ),
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
                      child: const Icon(
                        Icons.check_rounded,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Strong skill match',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            'You already match ${matchingSkills.length} required skill${matchingSkills.length > 1 ? 's' : ''}: ${matchingSkills.join(', ')}.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (startup.openRoles.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              const XPSectionTitle(title: 'Open roles'),
              const SizedBox(height: AppSpacing.md),
              ...startup.openRoles.map((role) {
                final alreadyApplied = _appliedRoleTitles.contains(role.title);
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: XPCard(
                    elevated: true,
                    radius: AppTheme.cornerRadiusLarge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.title,
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.w800,
                                        ),
                                  ),
                                  if (role.commitment?.isNotEmpty == true) ...[
                                    const SizedBox(height: AppSpacing.xxs),
                                    Text(
                                      role.commitment!,
                                      style: Theme.of(context).textTheme.bodySmall,
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            XPOutlinedButton(
                              label: alreadyApplied ? 'Applied' : 'Apply',
                              expand: false,
                              size: XPButtonSize.small,
                              onPressed: alreadyApplied
                                  ? null
                                  : () => _showApplyDialog(context, role: role),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          role.learningOutcome,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (role.description?.isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            role.description!,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.textSecondary,
                                ),
                          ),
                        ],
                        if (role.estimatedHours != null || role.durationWeeks != null) ...[
                          const SizedBox(height: AppSpacing.sm),
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
                                  label: '${role.durationWeeks} weeks',
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
            const SizedBox(height: AppSpacing.lg),
            const XPSectionTitle(title: 'Skills they need'),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: startup.requiredSkills.map((skill) {
                return XPSkillTag(
                  label: skill,
                  isMatched: studentSkills.contains(skill),
                );
              }).toList(),
            ),
            if (startup.projectDetails?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'What they are looking for',
                child: Text(
                  startup.projectDetails!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: XPBottomActionBar(
        child: XPButton(
          label: startup.openRoles.isNotEmpty
              ? (roleCta != null ? 'Apply for ${roleCta.title}' : 'Applications sent')
              : (_hasApplied ? 'Application sent' : 'Apply now'),
          icon: startup.openRoles.isNotEmpty
              ? (roleCta != null ? Icons.work_outline_rounded : Icons.check_circle_rounded)
              : (_hasApplied ? Icons.check_circle_rounded : Icons.send_rounded),
          onPressed: startup.openRoles.isNotEmpty
              ? (roleCta != null ? () => _showApplyDialog(context, role: roleCta) : null)
              : (_hasApplied ? null : () => _showApplyDialog(context)),
        ),
      ),
    );
  }
}
