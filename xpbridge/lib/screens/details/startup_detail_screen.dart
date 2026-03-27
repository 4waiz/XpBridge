import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/application.dart';
import '../../models/mission.dart';
import '../../services/link_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_page_scaffold.dart';

class StartupDetailScreen extends StatefulWidget {
  const StartupDetailScreen({super.key, required this.startupId});

  final String startupId;

  @override
  State<StartupDetailScreen> createState() => _StartupDetailScreenState();
}

class _StartupDetailScreenState extends State<StartupDetailScreen> {
  Future<void> _showApplySheet(Mission mission) async {
    final appState = AppStateScope.of(context);
    final student = appState.studentProfile;
    if (student == null) {
      context.goNamed('studentSetup');
      return;
    }

    final controller = TextEditingController();
    String? errorText;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                top: AppSpacing.md,
                bottom:
                    MediaQuery.of(context).viewInsets.bottom + AppSpacing.md,
              ),
              child: XPSection(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Apply to ${mission.title}',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Your profile, CV, and links go with this application automatically.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    XPTextField(
                      controller: controller,
                      labelText: 'Short note',
                      hintText: 'Why are you a strong fit for this mission?',
                      maxLines: 4,
                      prefixIcon: Icons.chat_bubble_outline_rounded,
                    ),
                    if (errorText != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        errorText!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.error,
                        ),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.xl),
                    XPButton(
                      label: 'Submit application',
                      icon: Icons.send_rounded,
                      onPressed: () async {
                        try {
                          final navigator = Navigator.of(sheetContext);
                          final application = Application(
                            id: 'local_${DateTime.now().millisecondsSinceEpoch}',
                            missionId: mission.id,
                            studentId: student.id,
                            startupId: mission.startupId,
                            studentName: student.name,
                            startupName: mission.startupName,
                            roleTitle: mission.title,
                            status: ApplicationStatus.pending,
                            message: controller.text.trim().isEmpty
                                ? null
                                : controller.text.trim(),
                            appliedAt: DateTime.now(),
                          );
                          await appState.addApplication(application);
                          navigator.pop();
                          if (!mounted) return;
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            const SnackBar(
                              content: Text('Application submitted.'),
                              backgroundColor: AppTheme.successDark,
                            ),
                          );
                        } on XpServiceException catch (error) {
                          setModalState(() => errorText = error.message);
                        }
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    XPOutlinedButton(
                      label: 'Go back',
                      icon: Icons.arrow_back_rounded,
                      onPressed: () => Navigator.of(sheetContext).pop(),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final startup = appState.getStartupById(widget.startupId);
    final missions = appState.missions
        .where((mission) => mission.startupId == widget.startupId)
        .toList();
    final myApplications = appState.studentProfile == null
        ? <Application>[]
        : appState.getApplicationsForStudent(appState.studentProfile!.id);

    if (startup == null) {
      return const XPPageScaffold(
        title: 'Company',
        subtitle: 'Not found',
        showBack: true,
        compact: true,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.page),
            child: XPEmptyState(
              icon: Icons.storefront_outlined,
              title: 'Company not found',
              message: 'This startup is no longer available.',
            ),
          ),
        ),
      );
    }

    return XPPageScaffold(
      title: startup.companyName,
      subtitle: startup.industry,
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
                      XPBadge(label: startup.industry),
                      if ((startup.websiteUrl ?? '').isNotEmpty)
                        XPBadge(
                          label: 'Website',
                          icon: Icons.language_rounded,
                          color: AppTheme.primarySoft,
                        ),
                      XPBadge(
                        label: '${missions.length} open missions',
                        icon: Icons.work_outline_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    startup.description,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                  if ((startup.projectDetails ?? '').isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      startup.projectDetails!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: startup.requiredSkills
                        .map((skill) => XPBadge(label: skill))
                        .toList(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  XPButton(
                    label: 'Open company website',
                    icon: Icons.open_in_new_rounded,
                      onPressed: () async {
                        try {
                          await LinkService.openExternal(startup.websiteUrl);
                        } on XpServiceException catch (error) {
                          if (!context.mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.message)),
                          );
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'Open missions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Clear, reviewable work scopes with direct apply actions.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),
            if (missions.isEmpty)
              const XPEmptyState(
                icon: Icons.work_history_outlined,
                title: 'No open missions',
                message: 'This startup has not published any active missions yet.',
              )
            else
              ...missions.map((mission) {
                final alreadyApplied = myApplications.any(
                  (application) => application.missionId == mission.id,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: XPCard(
                    elevated: true,
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
                                    mission.title,
                                    style: Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    mission.description,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            XPOutlinedButton(
                              label: alreadyApplied ? 'Applied' : 'Apply',
                              expand: false,
                              size: XPButtonSize.small,
                              onPressed: alreadyApplied
                                  ? null
                                  : () => _showApplySheet(mission),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Wrap(
                          spacing: AppSpacing.sm,
                          runSpacing: AppSpacing.sm,
                          children: [
                            if ((mission.commitment ?? '').isNotEmpty)
                              XPBadge(
                                label: mission.commitment!,
                                icon: Icons.schedule_rounded,
                              ),
                            if (mission.estimatedHours != null)
                              XPBadge(label: '${mission.estimatedHours} hrs'),
                            if (mission.durationWeeks != null)
                              XPBadge(label: '${mission.durationWeeks} weeks'),
                            if (mission.isTeamMission)
                              XPBadge(
                                label: 'Team mission',
                                icon: Icons.groups_rounded,
                                color: AppTheme.primarySoft,
                              ),
                          ],
                        ),
                        if (mission.requiredSkills.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.md),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: mission.requiredSkills
                                .map((skill) => XPBadge(label: skill))
                                .toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
