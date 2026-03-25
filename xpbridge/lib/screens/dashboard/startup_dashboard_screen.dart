import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/application.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_page_scaffold.dart';

class StartupDashboardScreen extends StatefulWidget {
  const StartupDashboardScreen({super.key});

  @override
  State<StartupDashboardScreen> createState() => _StartupDashboardScreenState();
}

class _StartupDashboardScreenState extends State<StartupDashboardScreen> {
  final _searchController = TextEditingController();
  int _segment = 0;
  String? _skillFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
        return 'Pending';
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

  Future<void> _showFeedbackSheet(Application application) async {
    final appState = AppStateScope.of(context);
    final student = appState.getStudentById(application.studentId);
    final feedbackController = TextEditingController(
      text: application.mentorFeedbackText ?? '',
    );
    int rating = application.mentorRating ?? 0;
    final strengths = <String>{...application.strengths};
    final growthAreas = <String>{...application.growthAreas};
    final endorsedSkills = <String>{...application.endorsedSkills};
    final strengthOptions = const [
      'Ownership',
      'Communication',
      'Craft',
      'Speed',
      'Collaboration',
    ];
    final growthOptions = const [
      'Planning',
      'Documentation',
      'Testing',
      'Autonomy',
      'Scope management',
    ];

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
                      'Mentor feedback',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      student?.name ?? application.studentName,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: List.generate(5, (index) {
                        final star = index + 1;
                        return IconButton(
                          onPressed: () => setModalState(() => rating = star),
                          icon: Icon(
                            star <= rating
                                ? Icons.star_rounded
                                : Icons.star_border_rounded,
                            color: AppTheme.primary,
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Strengths',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: strengthOptions.map((item) {
                        return FilterChip(
                          label: Text(item),
                          selected: strengths.contains(item),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                strengths.add(item);
                              } else {
                                strengths.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Growth areas',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: growthOptions.map((item) {
                        return FilterChip(
                          label: Text(item),
                          selected: growthAreas.contains(item),
                          onSelected: (selected) {
                            setModalState(() {
                              if (selected) {
                                growthAreas.add(item);
                              } else {
                                growthAreas.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    if (student != null && student.skills.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Endorsed skills',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: student.skills.map((skill) {
                          final selected = endorsedSkills.contains(skill);
                          final canSelect = selected || endorsedSkills.length < 3;
                          return FilterChip(
                            label: Text(skill),
                            selected: selected,
                            onSelected: canSelect
                                ? (value) {
                                    setModalState(() {
                                      if (value) {
                                        endorsedSkills.add(skill);
                                      } else {
                                        endorsedSkills.remove(skill);
                                      }
                                    });
                                  }
                                : null,
                          );
                        }).toList(),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: feedbackController,
                      minLines: 4,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Feedback note',
                        hintText: 'What went well, and what should improve next?',
                        prefixIcon: Icon(Icons.feedback_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    XPButton(
                      label: 'Save feedback',
                      icon: Icons.check_rounded,
                      onPressed: () async {
                        final navigator = Navigator.of(sheetContext);
                        await appState.saveMentorFeedback(
                          application.id,
                          rating: rating == 0 ? null : rating,
                          feedback: feedbackController.text.trim().isEmpty
                              ? null
                              : feedbackController.text.trim(),
                          strengths: strengths.toList(),
                          growthAreas: growthAreas.toList(),
                          endorsedSkills: endorsedSkills.toList(),
                        );
                        navigator.pop();
                        if (!mounted) return;
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          const SnackBar(
                            content: Text('Feedback saved.'),
                            backgroundColor: AppTheme.successDark,
                          ),
                        );
                      },
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

  Future<void> _requestInterview(Application application) async {
    final appState = AppStateScope.of(context);
    final interview = await appState.requestAiInterview(application.id);
    if (!mounted || interview == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('AI interview requested for ${application.studentName}.'),
        backgroundColor: AppTheme.successDark,
      ),
    );
  }

  Future<void> _changeStatus(
    Application application,
    ApplicationStatus status,
  ) async {
    final appState = AppStateScope.of(context);
    await appState.updateApplicationStatus(application.id, status);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${application.studentName} marked ${_statusText(status)}.'),
        backgroundColor: AppTheme.successDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final startup = appState.startupProfile;

    if (startup == null) {
      return XPPageScaffold(
        title: 'Startup dashboard',
        subtitle: 'Finish setup first',
        compact: true,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: XPEmptyState(
              icon: Icons.business_center_outlined,
              title: 'Finish your startup setup',
              message:
                  'Add your company details, website, and at least one mission before reviewing talent.',
              actionLabel: 'Complete setup',
              onAction: () => context.goNamed('startupSetup'),
            ),
          ),
        ),
      );
    }

    final applications = appState.getApplicationsForStartup(startup.id);
    final students = appState.students.where((student) {
      if (_skillFilter != null && !student.skills.contains(_skillFilter)) {
        return false;
      }
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      final haystack = [
        student.name,
        student.education ?? '',
        student.bio ?? '',
        ...student.skills,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    final availableSkills = appState.students
        .expand((student) => student.skills)
        .toSet()
        .toList()
      ..sort();

    return XPPageScaffold(
      title: startup.companyName,
      subtitle: 'Review applicants and browse verified student profiles.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          XPHeaderButton(
            icon: Icons.badge_outlined,
            onTap: () => context.goNamed('startupProfile'),
          ),
          if (appState.isAdmin) ...[
            const SizedBox(width: AppSpacing.sm),
            XPHeaderButton(
              icon: Icons.admin_panel_settings_outlined,
              onTap: () => context.goNamed('admin'),
            ),
          ],
        ],
      ),
<<<<<<< Updated upstream
      body: XPScene(
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.md,
                  AppSpacing.page,
                  0,
                ),
                child: Column(
                  children: [
                    XPDashboardAppBar(
                      eyebrow: startupProfile?.companyName ?? 'Your company',
                      title: 'Talent',
                      leading: XPAvatar(
                        initial: (startupProfile?.companyName.isNotEmpty == true
                            ? startupProfile!.companyName[0]
                            : '?'),
                      ),
                      trailing: XPHeaderButton(
                        icon: Icons.business_outlined,
                        foregroundColor: AppTheme.surface,
                        backgroundColor: AppTheme.surface.withValues(
                          alpha: 0.14,
                        ),
                        onTap: () => context.pushNamed('startupProfile'),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    XPPremiumSearchBar(
                      controller: _searchController,
                      hintText: 'Search students, skills, or profiles',
                      onChanged: (value) => setState(() => _query = value),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => _showFiltersSheet(skillsForFilters),
                            icon: const Icon(
                              Icons.tune_rounded,
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          IconButton(
                            onPressed: () => context.pushNamed('startupAiChat'),
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              color: AppTheme.primaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_bottomNavIndex == 0)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            XPFilterChip(
                              label: 'All skills',
                              isSelected: _selectedSkill == null,
                              onTap: () => setState(() => _selectedSkill = null),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            ...skillsForFilters
                                .take(8)
                                .map(
                                  (skill) => Padding(
                                    padding: const EdgeInsets.only(
                                      right: AppSpacing.sm,
                                    ),
                                    child: XPFilterChip(
                                      label: skill,
                                      isSelected: _selectedSkill == skill,
                                      onTap: () => setState(
                                        () => _selectedSkill = skill,
                                      ),
                                    ),
                                  ),
                                ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: _bottomNavIndex == 0
                    ? StreamBuilder<List<Map<String, dynamic>>>(
                        stream: SupabaseService.studentsStream(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                               ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final data = snapshot.data ?? [];
                          final cloudStudents = data
                              .map((m) => StudentProfile.fromMap(m))
                              .toList();

                          // Use cloud students only for demo fresh start
                          final students = cloudStudents;

                          return _BrowseStudentsTab(
                            students: _applyFilters(students),
                            startupSkills: skillsForFilters,
                          );
                        },
                      )
                    : StreamBuilder<List<Map<String, dynamic>>>(
                        stream: SupabaseService.applicationsStreamForStartup(
                          startupProfile?.id ?? '',
                        ),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                               ConnectionState.waiting &&
                              !snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(),
                            );
                          }

                          final data = snapshot.data ?? [];
                          final cloudApps = data
                              .map((m) => Application.fromMap(m))
                              .toList();

                          // Merge with local state to ensure no UI flicker
                          final localApps = startupProfile != null
                              ? appState.getApplicationsForStartup(startupProfile.id)
                              : <Application>[];
                          final merged = [...cloudApps];
                          for (final local in localApps) {
                            if (!merged.any((a) => a.id == local.id)) {
                              merged.add(local);
                            }
                          }
                          merged.sort((a, b) => b.appliedAt.compareTo(a.appliedAt));

                          return _ApplicationsTab(
                            appState: appState,
                            applications: merged,
                            guildApplications: guildApplications,
                            statusColor: _statusColor,
                            statusLabel: _statusLabel,
                            statusProgress: _statusProgress,
                            onMarkCompleted: _markApplicationCompleted,
                            onLeaveFeedback: _showFeedbackSheet,
                          );
                        },
                      ),
              ),
            ],
=======
      body: RefreshIndicator(
        onRefresh: appState.refreshSession,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.page,
>>>>>>> Stashed changes
          ),
          children: [
            XPSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${applications.length} applicant records, ${appState.missions.where((mission) => mission.startupId == startup.id).length} active missions.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(
                        value: 0,
                        icon: Icon(Icons.inbox_outlined),
                        label: Text('Applicants'),
                      ),
                      ButtonSegment<int>(
                        value: 1,
                        icon: Icon(Icons.search_rounded),
                        label: Text('Talent'),
                      ),
                    ],
                    selected: {_segment},
                    onSelectionChanged: (selection) {
                      setState(() => _segment = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _segment == 0
                          ? 'Search applicants'
                          : 'Search students',
                      hintText: 'Name, education, or skill',
                      prefixIcon: const Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<String>(
                    initialValue: _skillFilter,
                    decoration: const InputDecoration(
                      labelText: 'Filter by skill',
                    ),
                    items: [
                      const DropdownMenuItem<String>(
                        value: null,
                        child: Text('All skills'),
                      ),
                      ...availableSkills.map(
                        (skill) => DropdownMenuItem<String>(
                          value: skill,
                          child: Text(skill),
                        ),
                      ),
                    ],
                    onChanged: (value) => setState(() => _skillFilter = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_segment == 0)
              _ApplicantsView(
                applications: applications.where((application) {
                  final query = _searchController.text.trim().toLowerCase();
                  final skillPass = _skillFilter == null ||
                      (appState
                              .getStudentById(application.studentId)
                              ?.skills
                              .contains(_skillFilter) ??
                          false);
                  if (!skillPass) return false;
                  if (query.isEmpty) return true;
                  final haystack = [
                    application.studentName,
                    application.roleTitle ?? '',
                    application.startupName,
                  ].join(' ').toLowerCase();
                  return haystack.contains(query);
                }).toList(),
                statusText: _statusText,
                statusColor: _statusColor,
                onRequestInterview: _requestInterview,
                onFeedback: _showFeedbackSheet,
                onStatusChange: _changeStatus,
              )
            else
              _TalentView(students: students),
          ],
        ),
      ),
    );
  }
}

class _ApplicantsView extends StatelessWidget {
  const _ApplicantsView({
    required this.applications,
    required this.statusText,
    required this.statusColor,
    required this.onRequestInterview,
    required this.onFeedback,
    required this.onStatusChange,
  });

  final List<Application> applications;
  final String Function(ApplicationStatus) statusText;
  final Color Function(ApplicationStatus) statusColor;
  final Future<void> Function(Application) onRequestInterview;
  final Future<void> Function(Application) onFeedback;
  final Future<void> Function(Application, ApplicationStatus) onStatusChange;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return const XPEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No applicants yet',
        message:
            'New applications will appear here once students apply to your live missions.',
      );
    }

    return Column(
      children: applications.map((application) {
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
                            application.studentName,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            application.roleTitle ?? 'Mission application',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    XPBadge(
                      label: statusText(application.status),
                      color: statusColor(application.status).withValues(alpha: 0.14),
                      textColor: statusColor(application.status),
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
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    XPOutlinedButton(
                      label: 'View profile',
                      size: XPButtonSize.small,
                      expand: false,
                      onPressed: () => context.pushNamed(
                        'studentDetail',
                        pathParameters: {'id': application.studentId},
                      ),
                    ),
                    if (application.status == ApplicationStatus.pending)
                      XPOutlinedButton(
                        label: 'Request AI interview',
                        size: XPButtonSize.small,
                        expand: false,
                        onPressed: () => onRequestInterview(application),
                      ),
                    if (application.status != ApplicationStatus.accepted &&
                        application.status != ApplicationStatus.completed)
                      XPButton(
                        label: 'Accept',
                        size: XPButtonSize.small,
                        expand: false,
                        onPressed: () => onStatusChange(
                          application,
                          ApplicationStatus.accepted,
                        ),
                      ),
                    if (application.status == ApplicationStatus.accepted)
                      XPButton(
                        label: 'Mark complete',
                        size: XPButtonSize.small,
                        expand: false,
                        onPressed: () => onStatusChange(
                          application,
                          ApplicationStatus.completed,
                        ),
                      ),
                    XPOutlinedButton(
                      label: 'Feedback',
                      size: XPButtonSize.small,
                      expand: false,
                      onPressed: () => onFeedback(application),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _TalentView extends StatelessWidget {
  const _TalentView({required this.students});

  final List<StudentProfile> students;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return const XPEmptyState(
        icon: Icons.group_outlined,
        title: 'No student profiles match',
        message: 'Clear the current filters or wait for more profiles to be completed.',
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 980 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * AppSpacing.lg)) / columns;

        return Wrap(
          spacing: AppSpacing.lg,
          runSpacing: AppSpacing.lg,
          children: students.map((student) {
            return SizedBox(
              width: itemWidth,
              child: XPCard(
                elevated: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      student.education ?? 'Student',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      student.bio ?? 'No bio added yet.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: student.skills
                          .take(5)
                          .map((skill) => XPBadge(label: skill))
                          .toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Row(
                      children: [
                        Expanded(
                          child: XPOutlinedButton(
                            label: 'View profile',
                            size: XPButtonSize.small,
                            onPressed: () => context.pushNamed(
                              'studentDetail',
                              pathParameters: {'id': student.id},
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
