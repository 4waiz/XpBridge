import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/application.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_navigation.dart';

class StartupDashboardScreen extends StatefulWidget {
  const StartupDashboardScreen({super.key});

  @override
  State<StartupDashboardScreen> createState() => _StartupDashboardScreenState();
}

class _StartupDashboardScreenState extends State<StartupDashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;
  String? _selectedSkill;
  String _query = '';
  bool _statsExpanded = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  List<StudentProfile> get _filteredStudents {
    var students = DummyData.students;

    if (_selectedSkill != null) {
      students = students
          .where((student) => student.skills.contains(_selectedSkill))
          .toList();
    }

    if (_query.trim().isNotEmpty) {
      final query = _query.trim().toLowerCase();
      students = students.where((student) {
        final haystack = [
          student.name,
          student.education ?? '',
          student.bio ?? '',
          ...student.skills,
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    return students;
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
              builder: (context, setModalState) {
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
                        'Leave mentor feedback',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        application.studentName,
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
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
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: skills.map((skill) {
                          final selected = endorsedSkills.contains(skill);
                          final canSelect =
                              selected || endorsedSkills.length < 2;
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
                      const SizedBox(height: AppSpacing.xl),
                      XPButton(
                        label: 'Save feedback',
                        icon: Icons.save_outlined,
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

  void _showFiltersSheet(List<String> skillsForFilters) {
    String? selectedSkill = _selectedSkill;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: StatefulBuilder(
              builder: (context, setModalState) {
                return Padding(
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
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Filter students',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Wrap(
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
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: XPOutlinedButton(
                              label: 'Clear',
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
    final skillsForFilters = startupProfile?.requiredSkills ?? [];

    return Scaffold(
      backgroundColor: AppTheme.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.pushNamed('startupAiChat'),
        icon: const Icon(Icons.auto_awesome_rounded),
        label: const Text('AI Search'),
      ),
      bottomNavigationBar: XPBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            _tabController.animateTo(1);
          } else if (index == 2) {
            context.pushNamed('startupProfile');
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
      body: SafeArea(
        child: Padding(
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
                title: 'Find talent',
                subtitle:
                    'Review aligned students and manage active learner applications.',
                leading: XPAvatar(
                  initial: (startupProfile?.companyName.isNotEmpty == true
                      ? startupProfile!.companyName[0]
                      : '?'),
                ),
                trailing: XPHeaderButton(
                  icon: Icons.business_outlined,
                  onTap: () => context.pushNamed('startupProfile'),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (value) => setState(() => _query = value),
                      decoration: const InputDecoration(
                        hintText: 'Search students, skills, or profiles',
                        prefixIcon: Icon(Icons.search_rounded),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  XPHeaderButton(
                    icon: Icons.tune_rounded,
                    onTap: () => _showFiltersSheet(skillsForFilters),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              XPCard(
                radius: AppTheme.cornerRadiusLarge,
                child: Column(
                  children: [
                    InkWell(
                      onTap: () =>
                          setState(() => _statsExpanded = !_statsExpanded),
                      borderRadius: BorderRadius.circular(
                        AppTheme.cornerRadiusLarge,
                      ),
                      child: Row(
                        children: [
                          Text(
                            'Company snapshot',
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const Spacer(),
                          Icon(
                            _statsExpanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AppTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                    if (_statsExpanded) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _DashboardMetric(
                              label: 'Students',
                              value: '${_filteredStudents.length}',
                              icon: Icons.people_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _DashboardMetric(
                              label: 'Learners',
                              value: '${applications.length}',
                              icon: Icons.description_rounded,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: _DashboardMetric(
                              label: 'Roles',
                              value: '${startupProfile?.openRoles.length ?? 0}',
                              icon: Icons.work_outline_rounded,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPCard(
                radius: AppTheme.cornerRadiusLarge,
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppTheme.cardBackground,
                        borderRadius: BorderRadius.circular(
                          AppTheme.cornerRadiusLarge,
                        ),
                      ),
                      child: TabBar(
                        controller: _tabController,
                        indicator: BoxDecoration(
                          color: AppTheme.primary,
                          borderRadius: BorderRadius.circular(
                            AppTheme.cornerRadiusSmall,
                          ),
                        ),
                        tabs: [
                          Tab(text: 'Students (${_filteredStudents.length})'),
                          Tab(text: 'Learners (${applications.length})'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                                    onTap: () =>
                                        setState(() => _selectedSkill = skill),
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
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _BrowseStudentsTab(
                      students: _filteredStudents,
                      startupSkills: skillsForFilters,
                    ),
                    _ApplicationsTab(
                      applications: applications,
                      onMarkCompleted: _markApplicationCompleted,
                      onLeaveFeedback: _showFeedbackSheet,
                    ),
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

class _DashboardMetric extends StatelessWidget {
  const _DashboardMetric({
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
      backgroundColor: AppTheme.cardBackground,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.md,
      ),
      child: Column(
        children: [
          Icon(icon, size: 18, color: AppTheme.text),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
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
        children: [
          XPSection(
            child: Column(
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
                    Icons.person_search_rounded,
                    size: 34,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No students match this filter',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.page),
      itemCount: students.length,
      itemBuilder: (context, index) {
        final student = students[index];
        final matchedSkills = student.skills
            .where((skill) => startupSkills.contains(skill))
            .toList();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: XPCard(
            elevated: true,
            radius: AppTheme.cornerRadiusLarge,
            onTap: () => context.pushNamed(
              'studentDetail',
              pathParameters: {'id': student.id},
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    XPAvatar(initial: student.name[0]),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            student.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
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
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    XPBadge(
                      label: '${student.availabilityHours.round()} hrs/week',
                      icon: Icons.schedule_rounded,
                      color: AppTheme.cardBackground,
                    ),
                    XPBadge(
                      label: '${student.xpPoints} XP',
                      icon: Icons.auto_awesome_rounded,
                      color: AppTheme.primaryLight,
                    ),
                  ],
                ),
                if (student.bio?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    student.bio!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
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
    required this.applications,
    required this.onMarkCompleted,
    required this.onLeaveFeedback,
  });

  final List<Application> applications;
  final ValueChanged<Application> onMarkCompleted;
  final ValueChanged<Application> onLeaveFeedback;

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
        return const Color(0xFF5D7CE0);
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
        return 'In Progress';
      case ApplicationStatus.completed:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (applications.isEmpty) {
      return ListView(
        children: [
          XPSection(
            child: Column(
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
                    Icons.inbox_outlined,
                    size: 34,
                    color: AppTheme.text,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Text(
                  'No learner applications yet',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.page),
      itemCount: applications.length,
      itemBuilder: (context, index) {
        final application = applications[index];
        final canMarkCompleted =
            application.status != ApplicationStatus.completed;
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: XPCard(
            elevated: true,
            radius: AppTheme.cornerRadiusLarge,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    XPAvatar(initial: application.studentName[0], size: 52),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            application.studentName,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            application.roleTitle ?? 'Mission application',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    XPBadge(
                      label: _statusLabel(application.status),
                      color: _statusColor(
                        application.status,
                      ).withValues(alpha: 0.16),
                      textColor: _statusColor(application.status),
                    ),
                  ],
                ),
                if (application.message?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  XPContainer(
                    child: Text(
                      application.message!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
                if (application.reflectionDid?.isNotEmpty == true ||
                    application.reflectionLearned?.isNotEmpty == true) ...[
                  const SizedBox(height: AppSpacing.md),
                  XPContainer(
                    color: AppTheme.primaryLight,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Reflection submitted',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        if (application.reflectionDid?.isNotEmpty == true) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(application.reflectionDid!),
                        ],
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: XPOutlinedButton(
                        label: 'Leave feedback',
                        icon: Icons.feedback_outlined,
                        size: XPButtonSize.medium,
                        onPressed: () => onLeaveFeedback(application),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: XPButton(
                        label: canMarkCompleted ? 'Mark complete' : 'Completed',
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
      },
    );
  }
}
