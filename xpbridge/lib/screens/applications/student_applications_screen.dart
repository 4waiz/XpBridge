import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/ai_interview.dart';
import '../../models/application.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_premium.dart';
import '../../widgets/xp_section_title.dart';

class StudentApplicationsScreen extends StatelessWidget {
  const StudentApplicationsScreen({super.key});

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppTheme.warning;
      case ApplicationStatus.accepted:
        return AppTheme.primaryDark;
      case ApplicationStatus.rejected:
        return AppTheme.error;
      case ApplicationStatus.interviewing:
        return AppTheme.primary;
      case ApplicationStatus.hired:
        return AppTheme.primaryDeep;
      case ApplicationStatus.completed:
        return AppTheme.successDark;
    }
  }

  String _statusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending review';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Closed';
      case ApplicationStatus.interviewing:
        return 'Interviewing';
      case ApplicationStatus.hired:
        return 'In progress';
      case ApplicationStatus.completed:
        return 'Completed';
    }
  }

  double _statusProgress(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 0.2;
      case ApplicationStatus.interviewing:
        return 0.45;
      case ApplicationStatus.accepted:
        return 0.62;
      case ApplicationStatus.hired:
        return 0.82;
      case ApplicationStatus.completed:
        return 1;
      case ApplicationStatus.rejected:
        return 1;
    }
  }

  String _statusSummary(Application application) {
    switch (application.status) {
      case ApplicationStatus.pending:
        return 'Your note has been delivered. The team is reviewing your fit.';
      case ApplicationStatus.interviewing:
        return 'You have made it into an active review cycle. Complete any requested AI interview to keep things moving.';
      case ApplicationStatus.accepted:
        return 'The startup wants to move forward with you.';
      case ApplicationStatus.hired:
        return 'You are actively working on this mission now.';
      case ApplicationStatus.completed:
        return 'Mission delivered. Add a reflection to capture what shipped.';
      case ApplicationStatus.rejected:
        return 'This one closed out. Keep momentum with the next match.';
    }
  }

  void _showReflectionSheet(
    BuildContext context, {
    required Application application,
    required AppState appState,
    required StudentProfile? student,
  }) {
    final didController = TextEditingController(
      text: application.reflectionDid,
    );
    final learnedController = TextEditingController(
      text: application.reflectionLearned,
    );
    final hoursController = TextEditingController(
      text: application.hoursSpent?.toString() ?? '',
    );
    final deliverableController = TextEditingController(
      text: application.deliverableUrl ?? '',
    );
    final selectedSkills = <String>{...application.skillsPracticed};
    String selectedDeliverableType =
        application.deliverableType?.isNotEmpty == true
        ? application.deliverableType!
        : 'other';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return XPPremiumSheet(
              title: 'Mission reflection',
              subtitle:
                  'Capture what you shipped, what changed, and the proof you can share.',
              footer: XPButton(
                label: 'Save reflection',
                icon: Icons.arrow_upward_rounded,
                onPressed: () async {
                  if (didController.text.trim().isEmpty ||
                      learnedController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Please fill in what you did and learned.',
                        ),
                        backgroundColor: AppTheme.error,
                      ),
                    );
                    return;
                  }

                  final hours = int.tryParse(hoursController.text.trim());

                  await appState.saveReflection(
                    application.id,
                    did: didController.text.trim(),
                    learned: learnedController.text.trim(),
                    skillsPracticed: selectedSkills.toList(),
                    hoursSpent: hours,
                    deliverableUrl: deliverableController.text.trim().isNotEmpty
                        ? deliverableController.text.trim()
                        : null,
                    deliverableType: selectedDeliverableType,
                  );
                  if (application.status != ApplicationStatus.completed) {
                    await appState.updateApplicationStatus(
                      application.id,
                      ApplicationStatus.completed,
                    );
                  }
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Reflection saved'),
                        backgroundColor: AppTheme.successDark,
                      ),
                    );
                  }
                },
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XPTextField(
                      controller: didController,
                      labelText: 'What did you do?',
                      prefixIcon: Icons.task_alt_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPTextField(
                      controller: learnedController,
                      labelText: 'What did you learn?',
                      prefixIcon: Icons.lightbulb_outline_rounded,
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Skills practiced',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: (student?.skills ?? []).map((skill) {
                        return XPChoiceChip(
                          label: skill,
                          selected: selectedSkills.contains(skill),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                selectedSkills.add(skill);
                              } else {
                                selectedSkills.remove(skill);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: XPTextField(
                            controller: hoursController,
                            labelText: 'Hours spent',
                            prefixIcon: Icons.timer_outlined,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedDeliverableType,
                            decoration: const InputDecoration(
                              labelText: 'Proof type',
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'design',
                                child: Text('Design'),
                              ),
                              DropdownMenuItem(
                                value: 'code',
                                child: Text('Code'),
                              ),
                              DropdownMenuItem(
                                value: 'doc',
                                child: Text('Doc'),
                              ),
                              DropdownMenuItem(
                                value: 'other',
                                child: Text('Other'),
                              ),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(
                                  () => selectedDeliverableType = value,
                                );
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPTextField(
                      controller: deliverableController,
                      labelText: 'Deliverable URL',
                      hintText: 'Optional link to what you shipped',
                      prefixIcon: Icons.link_rounded,
                      keyboardType: TextInputType.url,
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

  String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';

  String _interviewStatusLabel(AiInterviewStatus status) {
    switch (status) {
      case AiInterviewStatus.pending:
        return 'AI Interview Requested';
      case AiInterviewStatus.inProgress:
        return 'Interview in progress';
      case AiInterviewStatus.completed:
        return 'Interview Submitted';
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final student = appState.studentProfile;
    final applications = student != null
        ? appState.getApplicationsForStudent(student.id)
        : <Application>[];

    final activeCount = applications
        .where((app) => app.status != ApplicationStatus.completed)
        .length;
    final completedCount = applications
        .where((app) => app.status == ApplicationStatus.completed)
        .length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPScene(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              const XPAppBar(
                title: 'Applications',
                subtitle: 'Live mission tracking',
              ),
              Expanded(
                child: student == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.page),
                          child: Text(
                            'Complete your profile to view applications.',
                            style: Theme.of(context).textTheme.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : applications.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.page),
                          child: XPSection(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 92,
                                  height: 92,
                                  decoration: BoxDecoration(
                                    gradient: AppTheme.primaryGlowGradient,
                                    borderRadius: BorderRadius.circular(28),
                                    boxShadow: AppTheme.softGlowShadow,
                                  ),
                                  child: const Icon(
                                    Icons.description_outlined,
                                    size: 36,
                                    color: AppTheme.surface,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                Text(
                                  'No applications yet',
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Once you apply to opportunities, they will appear here with status updates and reflection prompts.',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.xl),
                                XPButton(
                                  label: 'Discover roles',
                                  onPressed: () =>
                                      context.goNamed('studentDashboard'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.page,
                          AppSpacing.md,
                          AppSpacing.page,
                          AppSpacing.page,
                        ),
                        children: [
                          XPGlassPanel(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            backgroundColor: AppTheme.surface.withValues(
                              alpha: 0.64,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _SummaryTile(
                                    label: 'Active',
                                    value: '$activeCount',
                                    icon: Icons.bolt_rounded,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: _SummaryTile(
                                    label: 'Completed',
                                    value: '$completedCount',
                                    icon: Icons.verified_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xl),
                          XPSectionTitle(
                            title: 'Your pipeline',
                            subtitle:
                                'Every application in motion, with reflection prompts when it matters.',
                          ),
                          const SizedBox(height: AppSpacing.md),
                          ...applications.map((application) {
                            final isCompleted =
                                application.status ==
                                ApplicationStatus.completed;
                            final interview = appState.getInterviewForApplication(
                              application.id,
                            );
                            final hasReflection =
                                application.reflectionDid?.isNotEmpty == true ||
                                application.reflectionLearned?.isNotEmpty ==
                                    true;

                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.lg,
                              ),
                              child: XPApplicationStatusCard(
                                title:
                                    application.roleTitle ??
                                    'Mission with ${application.startupName}',
                                subtitle:
                                    '${application.startupName} · Applied ${_dateLabel(application.appliedAt)}',
                                statusLabel: _statusText(application.status),
                                statusColor: _statusColor(application.status),
                                progress: _statusProgress(application.status),
                                summary: _statusSummary(application),
                                trailing: Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: [
                                    XPBadge(
                                      label: _dateLabel(application.appliedAt),
                                      icon: Icons.schedule_rounded,
                                    ),
                                    if (interview != null)
                                      XPBadge(
                                        label: _interviewStatusLabel(
                                          interview.status,
                                        ),
                                        icon: interview.status ==
                                                AiInterviewStatus.completed
                                            ? Icons.verified_rounded
                                            : Icons.record_voice_over_rounded,
                                        color: interview.status ==
                                                AiInterviewStatus.completed
                                            ? AppTheme.primarySoft
                                            : AppTheme.surface.withValues(
                                                alpha: 0.72,
                                              ),
                                      ),
                                    if (application.message?.isNotEmpty == true)
                                      XPBadge(
                                        label: 'Intro note sent',
                                        icon: Icons.chat_bubble_outline_rounded,
                                        color: AppTheme.primarySoft,
                                      ),
                                  ],
                                ),
                                footer: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    if (application.message?.isNotEmpty ==
                                        true) ...[
                                      XPContainer(
                                        child: Text(
                                          '"${application.message}"',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium
                                              ?.copyWith(
                                                color: AppTheme.textSecondary,
                                                fontStyle: FontStyle.italic,
                                              ),
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                    if (interview != null &&
                                        !isCompleted) ...[
                                      XPContainer(
                                        color: interview.status ==
                                                AiInterviewStatus.completed
                                            ? AppTheme.primarySoft
                                            : AppTheme.surface.withValues(
                                                alpha: 0.72,
                                              ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _interviewStatusLabel(
                                                interview.status,
                                              ),
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.xs,
                                            ),
                                            Text(
                                              interview.status ==
                                                      AiInterviewStatus
                                                          .completed
                                                  ? 'Your founder review summary has been submitted.'
                                                  : 'Complete the guided AI interview for a faster first review.',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                            const SizedBox(
                                              height: AppSpacing.md,
                                            ),
                                            XPButton(
                                              label: interview.status ==
                                                      AiInterviewStatus
                                                          .completed
                                                  ? 'View submission'
                                                  : interview.status ==
                                                          AiInterviewStatus
                                                              .inProgress
                                                      ? 'Continue interview'
                                                      : 'Start interview',
                                              icon: interview.status ==
                                                      AiInterviewStatus
                                                          .completed
                                                  ? Icons.visibility_outlined
                                                  : Icons.record_voice_over_rounded,
                                              size: XPButtonSize.medium,
                                              onPressed: () => context.pushNamed(
                                                'aiInterview',
                                                pathParameters: {
                                                  'id': interview.id,
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                    if (isCompleted && hasReflection) ...[
                                      XPContainer(
                                        color: AppTheme.primarySoft,
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Reflection saved',
                                              style: Theme.of(
                                                context,
                                              ).textTheme.titleMedium,
                                            ),
                                            if (application
                                                    .reflectionDid
                                                    ?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(application.reflectionDid!),
                                            ],
                                            if (application
                                                    .reflectionLearned
                                                    ?.isNotEmpty ==
                                                true) ...[
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(
                                                application.reflectionLearned!,
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ],
                                            if (application
                                                .skillsPracticed
                                                .isNotEmpty) ...[
                                              const SizedBox(
                                                height: AppSpacing.sm,
                                              ),
                                              Wrap(
                                                spacing: AppSpacing.xs,
                                                runSpacing: AppSpacing.xs,
                                                children: application
                                                    .skillsPracticed
                                                    .map(
                                                      (skill) => XPSkillTag(
                                                        label: skill,
                                                      ),
                                                    )
                                                    .toList(),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                    ],
                                    if (isCompleted && !hasReflection)
                                      XPButton(
                                        label: 'Add reflection',
                                        icon: Icons.auto_stories_rounded,
                                        onPressed: () => _showReflectionSheet(
                                          context,
                                          application: application,
                                          appState: appState,
                                          student: student,
                                        ),
                                      )
                                    else if (!isCompleted) ...[
                                      XPButton(
                                        label: 'Enter War Room',
                                        icon: Icons.rocket_launch_rounded,
                                        onPressed: () => context.pushNamed(
                                          'warRoom',
                                          pathParameters: {'id': application.id},
                                        ),
                                      ),
                                      const SizedBox(height: AppSpacing.md),
                                      XPContainer(
                                        child: Row(
                                          children: [
                                            const Icon(
                                              Icons.hourglass_bottom_rounded,
                                              size: 16,
                                              color: AppTheme.textSecondary,
                                            ),
                                            const SizedBox(
                                              width: AppSpacing.xs,
                                            ),
                                            Expanded(
                                              child: Text(
                                                'The next formal update appears here, but you can chat with the startup in the War Room.',
                                                style: Theme.of(
                                                  context,
                                                ).textTheme.bodySmall,
                                              ),
                                            ),
                                          ],
                                        ),
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
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return XPCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppTheme.surface.withValues(alpha: 0.52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGlowGradient,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            ),
            child: Icon(icon, size: 18, color: AppTheme.surface),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(value, style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
