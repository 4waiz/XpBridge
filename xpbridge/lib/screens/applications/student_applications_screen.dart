import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/ai_interview.dart';
import '../../models/application.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_page_scaffold.dart';

class StudentApplicationsScreen extends StatelessWidget {
  const StudentApplicationsScreen({super.key});

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppTheme.warning;
      case ApplicationStatus.interviewing:
        return AppTheme.primary;
      case ApplicationStatus.accepted:
        return AppTheme.primaryDark;
      case ApplicationStatus.hired:
        return AppTheme.primaryDeep;
      case ApplicationStatus.completed:
        return AppTheme.successDark;
      case ApplicationStatus.rejected:
        return AppTheme.error;
    }
  }

  String _statusText(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return 'Pending review';
      case ApplicationStatus.interviewing:
        return 'Interviewing';
      case ApplicationStatus.accepted:
        return 'Accepted';
      case ApplicationStatus.hired:
        return 'In progress';
      case ApplicationStatus.completed:
        return 'Completed';
      case ApplicationStatus.rejected:
        return 'Rejected';
    }
  }

  Future<void> _showReflectionSheet(
    BuildContext context,
    Application application,
    AppState appState,
  ) async {
    final didController = TextEditingController(text: application.reflectionDid);
    final learnedController = TextEditingController(
      text: application.reflectionLearned,
    );
    final deliverableController = TextEditingController(
      text: application.deliverableUrl,
    );
    final hoursController = TextEditingController(
      text: application.hoursSpent?.toString() ?? '',
    );
    final selectedSkills = <String>{...application.skillsPracticed};
    final availableSkills = appState.studentProfile?.skills ?? [];
    String deliverableType = application.deliverableType ?? 'other';

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final mediaQuery = MediaQuery.of(context);
            final stackFields = mediaQuery.size.width < 420;
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  top: AppSpacing.md,
                  bottom: mediaQuery.viewInsets.bottom + AppSpacing.md,
                ),
                child: SizedBox(
                  height: mediaQuery.size.height * 0.84,
                  child: XPCard(
                    elevated: true,
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                    Text(
                      'Mission reflection',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    XPTextField(
                      controller: didController,
                      labelText: 'What did you ship?',
                      maxLines: 4,
                      prefixIcon: Icons.task_alt_outlined,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPTextField(
                      controller: learnedController,
                      labelText: 'What did you learn?',
                      maxLines: 4,
                      prefixIcon: Icons.lightbulb_outline_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (stackFields)
                      Column(
                        children: [
                          XPTextField(
                            controller: hoursController,
                            labelText: 'Hours spent',
                            keyboardType: TextInputType.number,
                            prefixIcon: Icons.schedule_rounded,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          DropdownButtonFormField<String>(
                            value: deliverableType,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Deliverable type',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'design', child: Text('Design')),
                              DropdownMenuItem(value: 'code', child: Text('Code')),
                              DropdownMenuItem(value: 'doc', child: Text('Document')),
                              DropdownMenuItem(value: 'other', child: Text('Other')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setModalState(() => deliverableType = value);
                              }
                            },
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: XPTextField(
                              controller: hoursController,
                              labelText: 'Hours spent',
                              keyboardType: TextInputType.number,
                              prefixIcon: Icons.schedule_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: deliverableType,
                              isExpanded: true,
                              decoration: const InputDecoration(
                                labelText: 'Deliverable type',
                              ),
                              items: const [
                                DropdownMenuItem(value: 'design', child: Text('Design')),
                                DropdownMenuItem(value: 'code', child: Text('Code')),
                                DropdownMenuItem(value: 'doc', child: Text('Document')),
                                DropdownMenuItem(value: 'other', child: Text('Other')),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setModalState(() => deliverableType = value);
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
                      keyboardType: TextInputType.url,
                      prefixIcon: Icons.link_rounded,
                    ),
                    if (availableSkills.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Skills practiced',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: availableSkills.map((skill) {
                          return FilterChip(
                            label: Text(skill),
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
                    ],
                              ],
                            ),
                          ),
                        ),
                    const SizedBox(height: AppSpacing.lg),
                    XPButton(
                      label: 'Save reflection',
                      icon: Icons.check_rounded,
                      onPressed: () async {
                        await appState.saveReflection(
                          application.id,
                          did: didController.text.trim(),
                          learned: learnedController.text.trim(),
                          skillsPracticed: selectedSkills.toList(),
                          hoursSpent: int.tryParse(hoursController.text.trim()),
                          deliverableUrl: deliverableController.text.trim().isEmpty
                              ? null
                              : deliverableController.text.trim(),
                          deliverableType: deliverableType,
                        );
                        if (application.status != ApplicationStatus.completed) {
                          await appState.updateApplicationStatus(
                            application.id,
                            ApplicationStatus.completed,
                          );
                        }
                        if (!context.mounted) return;
                        Navigator.pop(sheetContext);
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
    final student = appState.studentProfile;
    final applications = student == null
        ? <Application>[]
        : appState.getApplicationsForStudent(student.id);

    return XPPageScaffold(
      title: 'Applications',
      subtitle: 'Track status changes, interview requests, and completion reflections.',
      showBack: true,
      compact: true,
      body: student == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: XPEmptyState(
                  icon: Icons.person_outline_rounded,
                  title: 'Complete your profile first',
                  message:
                      'Your applications dashboard becomes available once setup is complete.',
                  actionLabel: 'Go to setup',
                  onAction: () => context.goNamed('studentSetup'),
                ),
              ),
            )
          : applications.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.page),
                    child: XPEmptyState(
                      icon: Icons.description_outlined,
                      title: 'No applications yet',
                      message:
                          'Apply to a live mission and it will appear here with status updates.',
                      actionLabel: 'Discover missions',
                      onAction: () => context.goNamed('studentDashboard'),
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
                  children: applications.map((application) {
                    final interview = appState.getInterviewForApplication(
                      application.id,
                    );
                    final needsReflection =
                        application.status == ApplicationStatus.completed;
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
                                        application.roleTitle ??
                                            'Mission application',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge,
                                      ),
                                      const SizedBox(height: AppSpacing.xs),
                                      Text(
                                        application.startupName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ),
                                XPBadge(
                                  label: _statusText(application.status),
                                  color: _statusColor(
                                    application.status,
                                  ).withValues(alpha: 0.14),
                                  textColor: _statusColor(application.status),
                                ),
                              ],
                            ),
                            if ((application.message ?? '').isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                application.message!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                            if (interview != null) ...[
                              const SizedBox(height: AppSpacing.md),
                              XPBadge(
                                label: interview.status == AiInterviewStatus.completed
                                    ? 'AI interview submitted'
                                    : interview.status == AiInterviewStatus.inProgress
                                        ? 'AI interview in progress'
                                        : 'AI interview requested',
                                icon: Icons.record_voice_over_rounded,
                                color: AppTheme.primarySoft,
                              ),
                            ],
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: [
                                XPOutlinedButton(
                                  label: 'View company',
                                  size: XPButtonSize.small,
                                  expand: false,
                                  onPressed: () => context.pushNamed(
                                    'startupDetail',
                                    pathParameters: {'id': application.startupId},
                                  ),
                                ),
                                if (interview != null)
                                  XPOutlinedButton(
                                    label: interview.status ==
                                            AiInterviewStatus.completed
                                        ? 'View interview'
                                        : 'Open interview',
                                    size: XPButtonSize.small,
                                    expand: false,
                                    onPressed: () => context.pushNamed(
                                      'aiInterview',
                                      pathParameters: {'id': interview.id},
                                    ),
                                  ),
                                if (needsReflection)
                                  XPButton(
                                    label: 'Reflection',
                                    size: XPButtonSize.small,
                                    expand: false,
                                    onPressed: () {
                                      if (!appState.requireAuthOr(context)) {
                                        return;
                                      }
                                      _showReflectionSheet(
                                        context,
                                        application,
                                        appState,
                                      );
                                    },
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
    );
  }
}
