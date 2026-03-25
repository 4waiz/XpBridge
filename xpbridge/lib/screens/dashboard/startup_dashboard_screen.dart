import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../services/supabase_service.dart';
import '../../models/ai_interview.dart';
import '../../models/application.dart';
import '../../models/guild_application.dart';
import '../../models/student_profile.dart';
import '../../services/ai_interview_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_mission_widgets.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_navigation.dart';
import '../../widgets/xp_premium.dart';

class StartupDashboardScreen extends StatefulWidget {
  const StartupDashboardScreen({super.key});

  @override
  State<StartupDashboardScreen> createState() => _StartupDashboardScreenState();
}

class _StartupDashboardScreenState extends State<StartupDashboardScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _bottomNavIndex = 0;
  String? _selectedSkill;
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<StudentProfile> _applyFilters(List<StudentProfile> students) {
    var filtered = [...students];

    if (_selectedSkill != null) {
      filtered = filtered
          .where((student) => student.skills.contains(_selectedSkill))
          .toList();
    }

    if (_query.trim().isNotEmpty) {
      final query = _query.trim().toLowerCase();
      filtered = filtered.where((student) {
        final haystack = [
          student.name,
          student.education ?? '',
          student.bio ?? '',
          ...student.skills,
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    return filtered;
  }

  Future<void> _markApplicationCompleted(Application application) async {
    final appState = AppStateScope.of(context);
    await appState.updateApplicationStatus(
      application.id,
      ApplicationStatus.completed,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Marked as completed'),
        backgroundColor: AppTheme.successDark,
      ),
    );
  }

  void _showFeedbackSheet(Application application) {
    final appState = AppStateScope.of(context);
    StudentProfile? student;
    try {
      student = DummyData.students.firstWhere(
        (s) => s.id == application.studentId,
      );
    } catch (_) {
      student = null;
    }
    final skills = student?.skills ?? [];
    final strengthsOptions = [
      'Ownership',
      'Communication',
      'Craft',
      'Collaboration',
      'Speed',
    ];
    final growthOptions = [
      'Planning',
      'Documentation',
      'Testing',
      'Autonomy',
      'Focus',
    ];

    int rating = application.mentorRating ?? 0;
    final feedbackController = TextEditingController(
      text: application.mentorFeedbackText ?? '',
    );
    final selectedStrengths = <String>{...application.strengths};
    final selectedGrowth = <String>{...application.growthAreas};
    final endorsedSkills = <String>{...application.endorsedSkills};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return XPPremiumSheet(
              title: 'Leave mentor feedback',
              subtitle: application.studentName,
              footer: XPButton(
                label: 'Save feedback',
                icon: Icons.arrow_upward_rounded,
                onPressed: () async {
                  await appState.saveMentorFeedback(
                    application.id,
                    rating: rating == 0 ? null : rating,
                    feedback: feedbackController.text.trim().isNotEmpty
                        ? feedbackController.text.trim()
                        : null,
                    strengths: selectedStrengths.toList(),
                    growthAreas: selectedGrowth.toList(),
                    endorsedSkills: endorsedSkills.toList(),
                  );
                  if (sheetContext.mounted) {
                    Navigator.pop(sheetContext);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Feedback saved'),
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
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: strengthsOptions.map((item) {
                        return XPChoiceChip(
                          label: item,
                          selected: selectedStrengths.contains(item),
                          onSelected: (value) {
                            setModalState(() {
                              if (value) {
                                selectedStrengths.add(item);
                              } else {
                                selectedStrengths.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Growth areas',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: growthOptions.map((item) {
                        return XPChoiceChip(
                          label: item,
                          selected: selectedGrowth.contains(item),
                          onSelected: (value) {
                            setModalState(() {
                              if (value) {
                                selectedGrowth.add(item);
                              } else {
                                selectedGrowth.remove(item);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Endorse up to 2 skills',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children: skills.map((skill) {
                        final selected = endorsedSkills.contains(skill);
                        final canSelect = selected || endorsedSkills.length < 2;
                        return XPChoiceChip(
                          label: skill,
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
                              : (_) {},
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPTextField(
                      controller: feedbackController,
                      labelText: 'Feedback note',
                      hintText:
                          'What stood out, and what should they focus on next?',
                      prefixIcon: Icons.feedback_outlined,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
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

  void _showFiltersSheet(List<String> skillsForFilters) {
    String? selectedSkill = _selectedSkill;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return XPPremiumSheet(
              title: 'Filter students',
              subtitle: 'Narrow the list by the skills you need most.',
              footer: Row(
                children: [
                  Expanded(
                    child: XPOutlinedButton(
                      label: 'Reset',
                      onPressed: () =>
                          setModalState(() => selectedSkill = null),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: XPButton(
                      label: 'Apply',
                      onPressed: () {
                        setState(() => _selectedSkill = selectedSkill);
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  XPChoiceChip(
                    label: 'All skills',
                    selected: selectedSkill == null,
                    onSelected: (_) =>
                        setModalState(() => selectedSkill = null),
                  ),
                  ...skillsForFilters.map(
                    (skill) => XPChoiceChip(
                      label: skill,
                      selected: selectedSkill == skill,
                      onSelected: (_) =>
                          setModalState(() => selectedSkill = skill),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _statusColor(ApplicationStatus status) {
    switch (status) {
      case ApplicationStatus.pending:
        return AppTheme.warning;
      case ApplicationStatus.accepted:
        return AppTheme.successDark;
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

  String _statusLabel(ApplicationStatus status) {
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
      case ApplicationStatus.rejected:
        return 1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final startupProfile = appState.startupProfile;
    final startupApplications = startupProfile != null
        ? appState.getApplicationsForStartup(startupProfile.id)
        : <Application>[];
    final applications = startupApplications.isNotEmpty
        ? startupApplications
        : appState.applications;
    final guildApplications = startupProfile != null
        ? appState.getGuildApplicationsForStartup(startupProfile.id)
        : <GuildApplication>[];
    final skillsForFilters = startupProfile?.requiredSkills ?? [];

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      bottomNavigationBar: XPBottomNavBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 2) {
            context.pushNamed('startupProfile');
          } else {
            setState(() => _bottomNavIndex = index);
          }
        },
        items: const [
          XPBottomNavItem(
            label: 'Talent',
            icon: Icons.people_outline_rounded,
            activeIcon: Icons.people_rounded,
          ),
          XPBottomNavItem(
            label: 'Learners',
            icon: Icons.inbox_outlined,
            activeIcon: Icons.inbox_rounded,
          ),
          XPBottomNavItem(
            label: 'Profile',
            icon: Icons.business_outlined,
            activeIcon: Icons.business_rounded,
          ),
        ],
      ),
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

                          // Fallback to dummy data if cloud is empty
                          final students = cloudStudents.isNotEmpty
                              ? cloudStudents
                              : DummyData.students;

                          return _BrowseStudentsTab(
                            students: _applyFilters(students),
                            startupSkills: skillsForFilters,
                          );
                        },
                      )
                    : _ApplicationsTab(
                        appState: appState,
                        applications: applications,
                        guildApplications: guildApplications,
                        statusColor: _statusColor,
                        statusLabel: _statusLabel,
                        statusProgress: _statusProgress,
                        onMarkCompleted: _markApplicationCompleted,
                        onLeaveFeedback: _showFeedbackSheet,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BrowseStudentsTab extends StatelessWidget {
  const _BrowseStudentsTab({
    required this.students,
    required this.startupSkills,
  });

  final List<StudentProfile> students;
  final List<String> startupSkills;

  @override
  Widget build(BuildContext context) {
    if (students.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          XPSection(
            child: Column(
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
                    Icons.person_search_rounded,
                    size: 36,
                    color: AppTheme.surface,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No students match this filter',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        120,
      ),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final matchedSkills = student.skills
            .where((skill) => startupSkills.contains(skill))
            .toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: XPGlassPanel(
            onTap: () => context.pushNamed(
              'studentDetail',
              pathParameters: {'id': student.id},
            ),
            backgroundColor: AppTheme.surface.withValues(alpha: 0.78),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XPAvatar(initial: student.name[0]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  student.name,
                                  style: Theme.of(context).textTheme.titleLarge,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              XPBadge(
                                label: '${student.availabilityHours.round()} h/w',
                                icon: Icons.schedule_rounded,
                              ),
                              const SizedBox(width: AppSpacing.xs),
                              XPBadge(
                                label: '${student.xpPoints} XP',
                                icon: Icons.auto_awesome_rounded,
                                color: AppTheme.primarySoft,
                              ),
                            ],
                          ),
                          if (student.education?.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.xxs),
                            Text(
                              student.education!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
                if (student.bio?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    student.bio!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: student.skills
                      .take(6)
                      .map(
                        (skill) => XPSkillTag(
                          label: skill,
                          isMatched: matchedSkills.contains(skill),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ApplicationsTab extends StatelessWidget {
  const _ApplicationsTab({
    required this.appState,
    required this.applications,
    required this.guildApplications,
    required this.statusColor,
    required this.statusLabel,
    required this.statusProgress,
    required this.onMarkCompleted,
    required this.onLeaveFeedback,
  });

  final AppState appState;
  final List<Application> applications;
  final List<GuildApplication> guildApplications;
  final Color Function(ApplicationStatus status) statusColor;
  final String Function(ApplicationStatus status) statusLabel;
  final double Function(ApplicationStatus status) statusProgress;
  final ValueChanged<Application> onMarkCompleted;
  final ValueChanged<Application> onLeaveFeedback;

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty && guildApplications.isEmpty) {
      return ListView(
        padding: const EdgeInsets.all(AppSpacing.page),
        children: [
          XPSection(
            child: Column(
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
                    Icons.inbox_outlined,
                    size: 36,
                    color: AppTheme.surface,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No learner applications yet',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.page,
        0,
        AppSpacing.page,
        120,
      ),
      children: [
        ...applications.map((application) {
          final canMarkCompleted =
              application.status != ApplicationStatus.completed;
          final interview = appState.getInterviewForApplication(application.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: XPApplicationStatusCard(
              title: application.studentName,
              subtitle: application.roleTitle ?? 'Mission application',
              statusLabel: statusLabel(application.status),
              statusColor: statusColor(application.status),
              progress: statusProgress(application.status),
              summary: application.message?.isNotEmpty == true
                  ? application.message!
                  : 'Open the learner profile, leave feedback, or move this mission forward.',
              trailing: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.sm,
                children: [
                  if (interview != null)
                    XPBadge(
                      label: interview.status == AiInterviewStatus.completed
                          ? 'AI interview complete'
                          : interview.status == AiInterviewStatus.inProgress
                              ? 'AI interview live'
                              : 'AI interview requested',
                      icon: interview.status == AiInterviewStatus.completed
                          ? Icons.verified_rounded
                          : Icons.record_voice_over_rounded,
                      color: interview.status == AiInterviewStatus.completed
                          ? AppTheme.primarySoft
                          : AppTheme.surface.withValues(alpha: 0.72),
                    ),
                  if (application.reflectionDid?.isNotEmpty == true ||
                      application.reflectionLearned?.isNotEmpty == true)
                    XPBadge(
                      label: 'Reflection submitted',
                      icon: Icons.auto_stories_rounded,
                      color: AppTheme.primarySoft,
                    ),
                ],
              ),
              footer: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (interview == null) ...[
                    XPContainer(
                      color: AppTheme.primarySoft,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.record_voice_over_rounded,
                            color: AppTheme.primaryDark,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Trigger a short AI interview before manual review.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          XPButton(
                            label: 'Request',
                            icon: Icons.auto_awesome_rounded,
                            expand: false,
                            size: XPButtonSize.small,
                            onPressed: () => appState.requestAiInterview(
                              application.id,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ] else if (interview.status == AiInterviewStatus.completed) ...[
                    XPContainer(
                      color: AppTheme.primarySoft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'AI interview summary',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const Spacer(),
                              XPBadge(
                                label: interview.recommendation == null
                                    ? 'Ready'
                                    : AiInterviewService.recommendationLabel(
                                        interview.recommendation!,
                                      ),
                                color: AppTheme.primaryDeep,
                                textColor: AppTheme.surface,
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: [
                              XPBadge(
                                label:
                                    'Communication ${interview.communicationScore ?? 0}',
                              ),
                              XPBadge(
                                label:
                                    'Confidence ${interview.confidenceScore ?? 0}',
                              ),
                              XPBadge(
                                label:
                                    'Relevance ${interview.relevanceScore ?? 0}',
                              ),
                            ],
                          ),
                          if (interview.summary?.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.sm),
                            Text(
                              interview.summary!,
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: XPOutlinedButton(
                          label: 'Feedback',
                          icon: Icons.feedback_outlined,
                          size: XPButtonSize.medium,
                          onPressed: () => onLeaveFeedback(application),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: XPButton(
                          label: canMarkCompleted ? 'Finish' : 'Done',
                          icon: canMarkCompleted
                              ? Icons.check_circle_outline_rounded
                              : Icons.check_circle_rounded,
                          size: XPButtonSize.medium,
                          onPressed: canMarkCompleted
                              ? () => onMarkCompleted(application)
                              : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (guildApplications.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.sm),
          XPSection(
            title: 'Guild applications',
            subtitle:
                'Review cross-functional team submissions alongside individual learners.',
            child: Column(
              children: guildApplications.map((guildApplication) {
                final guild = appState.getGuildById(guildApplication.guildId);
                final members = appState.getGuildMembers(guildApplication.guildId);
                if (guild == null) {
                  return const SizedBox.shrink();
                }
                final role = appState.getStartupRole(
                  guildApplication.startupId,
                  guildApplication.missionTitle,
                );
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: GuildPreviewCard(
                    guild: guild,
                    members: members,
                    activeMissions: appState.getActiveGuildMissionCount(guild.id),
                    footer: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (role?.teamMissionConfig != null) ...[
                          TeamMissionHighlights(
                            config: role!.teamMissionConfig!,
                            showOutcome: false,
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Text(
                          '${guildApplication.missionTitle} • ${guildApplication.startupName}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          guildApplication.message,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Row(
                          children: [
                            Expanded(
                              child: XPOutlinedButton(
                                label: 'Advance',
                                icon: Icons.trending_up_rounded,
                                size: XPButtonSize.medium,
                                onPressed: () => appState.advanceGuildApplication(
                                  guildApplication.id,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: XPButton(
                                label: guildApplication.status ==
                                        ApplicationStatus.completed
                                    ? 'Completed'
                                    : 'Complete',
                                icon: Icons.check_circle_outline_rounded,
                                size: XPButtonSize.medium,
                                onPressed: guildApplication.status ==
                                        ApplicationStatus.completed
                                    ? null
                                    : () => appState.completeGuildApplication(
                                          guildApplication.id,
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
            ),
          ),
        ],
      ],
    );
  }
}
