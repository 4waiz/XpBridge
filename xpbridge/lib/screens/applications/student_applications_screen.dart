import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/application.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';

class StudentApplicationsScreen extends StatelessWidget {
  const StudentApplicationsScreen({super.key});

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppTheme.warning;
      case ApplicationStatus.accepted:
        return AppTheme.success;
      case ApplicationStatus.rejected:
        return AppTheme.error;
      case ApplicationStatus.interviewing:
        return AppTheme.primary;
      case ApplicationStatus.hired:
        return const Color(0xFF5D7CE0);
      case ApplicationStatus.completed:
        return AppTheme.successDark;
    }
  }

  String _statusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.rejected:
        return 'Rejected';
      case ApplicationStatus.interviewing:
        return 'Interviewing';
      case ApplicationStatus.hired:
        return 'In Progress';
      case ApplicationStatus.completed:
        return 'Completed';
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
        return Padding(
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
            child: StatefulBuilder(
              builder: (ctx, setModalState) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Center(
                        child: Container(
                          width: 48,
                          height: 5,
                          decoration: BoxDecoration(
                            color: AppTheme.cardBackground,
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Submit reflection',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Capture what you shipped, what you learned, and the proof you can show.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xl),
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
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Skills practiced',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
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
                                labelText: 'Type',
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
                        hintText: 'Optional proof link',
                        prefixIcon: Icons.link_rounded,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      XPButton(
                        label: 'Save reflection',
                        icon: Icons.save_outlined,
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

                          final hours = int.tryParse(
                            hoursController.text.trim(),
                          );

                          await appState.saveReflection(
                            application.id,
                            did: didController.text.trim(),
                            learned: learnedController.text.trim(),
                            skillsPracticed: selectedSkills.toList(),
                            hoursSpent: hours,
                            deliverableUrl:
                                deliverableController.text.trim().isNotEmpty
                                ? deliverableController.text.trim()
                                : null,
                            deliverableType: selectedDeliverableType,
                          );
                          if (application.status !=
                              ApplicationStatus.completed) {
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
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }

  String _dateLabel(DateTime date) => '${date.month}/${date.day}/${date.year}';

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final student = appState.studentProfile;
    final applications = student != null
        ? appState.getApplicationsForStudent(student.id)
        : <Application>[];

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: const XPAppBar(title: 'My Applications'),
      body: student == null
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
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: AppTheme.primaryLight,
                          borderRadius: BorderRadius.circular(
                            AppTheme.cornerRadiusLarge,
                          ),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          size: 36,
                          color: AppTheme.text,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'No applications yet',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Once you apply to missions, they will show up here with progress updates and reflection prompts.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      XPButton(
                        label: 'Discover missions',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => context.goNamed('studentDashboard'),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.page,
              ),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final application = applications[index];
                final isCompleted =
                    application.status == ApplicationStatus.completed;
                final hasReflection =
                    application.reflectionDid?.isNotEmpty == true ||
                    application.reflectionLearned?.isNotEmpty == true;

                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: XPCard(
                    elevated: true,
                    radius: AppTheme.cornerRadiusLarge,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 58,
                              height: 58,
                              decoration: BoxDecoration(
                                color: AppTheme.primaryLight,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.cornerRadiusSmall,
                                ),
                              ),
                              child: Center(
                                child: Text(
                                  application.startupName.isNotEmpty
                                      ? application.startupName[0].toUpperCase()
                                      : '?',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    application.roleTitle ??
                                        'Mission with ${application.startupName}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.w800),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    application.startupName,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            XPBadge(
                              label: _statusText(application.status),
                              color: _statusColor(
                                application.status,
                              ).withValues(alpha: 0.16),
                              textColor: _statusColor(application.status),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        XPContainer(
                          child: Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                size: 16,
                                color: AppTheme.textSecondary,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              Text(
                                'Applied ${_dateLabel(application.appliedAt)}',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        if (application.message?.isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.md),
                          XPContainer(
                            child: Text(
                              '"${application.message}"',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: AppTheme.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                            ),
                          ),
                        ],
                        if (isCompleted && hasReflection) ...[
                          const SizedBox(height: AppSpacing.md),
                          XPContainer(
                            color: AppTheme.primaryLight,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Reflection',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                if (application.reflectionDid?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(application.reflectionDid!),
                                ],
                                if (application.reflectionLearned?.isNotEmpty ==
                                    true) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    application.reflectionLearned!,
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodyMedium
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                                if (application.skillsPracticed.isNotEmpty) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.xs,
                                    runSpacing: AppSpacing.xs,
                                    children: application.skillsPracticed
                                        .map(
                                          (skill) => XPSkillTag(label: skill),
                                        )
                                        .toList(),
                                  ),
                                ],
                                if (application.hoursSpent != null ||
                                    application.deliverableUrl?.isNotEmpty ==
                                        true) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      if (application.hoursSpent != null)
                                        XPBadge(
                                          label:
                                              '${application.hoursSpent} hrs',
                                          icon: Icons.timer_outlined,
                                        ),
                                      if (application
                                              .deliverableUrl
                                              ?.isNotEmpty ==
                                          true)
                                        XPBadge(
                                          label: 'Deliverable linked',
                                          icon: Icons.link_rounded,
                                        ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.md),
                        if (isCompleted && !hasReflection)
                          XPButton(
                            label: 'Submit reflection',
                            icon: Icons.note_add_outlined,
                            onPressed: () => _showReflectionSheet(
                              context,
                              application: application,
                              appState: appState,
                              student: student,
                            ),
                          )
                        else if (!isCompleted)
                          XPContainer(
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.hourglass_bottom_rounded,
                                  size: 16,
                                  color: AppTheme.textSecondary,
                                ),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    'Waiting for the startup to mark this mission complete.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
