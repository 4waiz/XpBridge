import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/application.dart';
import '../../models/mission.dart';
import '../../services/link_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_page_scaffold.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
<<<<<<< Updated upstream
  final TextEditingController _searchController = TextEditingController();
  String? _selectedIndustry;
  String? _selectedSkill;
  String _query = '';
  bool _feedExpanded = false;

  void _showApplySheet(
    BuildContext context, {
    required Map<String, dynamic> mission,
    required String title,
  }) {
    final appState = AppStateScope.of(context);
    final profile = appState.studentProfile;

    if (profile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please complete your profile first (add your name and bio).'),
          backgroundColor: AppTheme.error,
          action: SnackBarAction(
            label: 'Go to Profile',
            textColor: Colors.white,
            onPressed: () => context.pushNamed('studentProfile'),
          ),
        ),
      );
      return;
    }

    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => StatefulBuilder(
        builder: (context, setModalState) => XPPremiumSheet(
          title: 'Apply for $title',
          subtitle: 'Share why you are the right fit for this mission.',
          footer: XPButton(
            label: 'Submit application',
            icon: Icons.send_rounded,
            onPressed: () async {
              final application = Application(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                studentId: profile.id,
                startupId: mission['startup_id'] ?? '',
                studentName: profile.name,
                startupName: mission['startup_name'] ?? 'Startup',
                roleTitle: title,
                status: ApplicationStatus.pending,
                message: messageController.text.trim(),
                appliedAt: DateTime.now(),
              );

              // This updates local state AND pushes to Supabase
              await appState.addApplication(application);

              if (sheetCtx.mounted) Navigator.pop(sheetCtx);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Applied for $title! The startup will see your application instantly.'),
                    backgroundColor: AppTheme.successDark,
                  ),
                );
              }
            },
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              XPTextField(
                controller: messageController,
                labelText: 'Message',
                hintText: 'Share your background and interest...',
                maxLines: 4,
                prefixIcon: Icons.chat_bubble_outline_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<StartupProfile> _sortedStartups(List<String> studentSkills) {
    final startups = [..._filteredStartups];
    startups.sort((a, b) {
      final aMatch = a.requiredSkills
          .where((skill) => studentSkills.contains(skill))
          .length;
      final bMatch = b.requiredSkills
          .where((skill) => studentSkills.contains(skill))
          .length;
      return bMatch.compareTo(aMatch);
    });
    return startups;
  }

  List<StartupProfile> get _filteredStartups {
    var startups = <StartupProfile>[]; // No dummy fallback for demo fresh start

    if (_selectedIndustry != null) {
      startups = startups
          .where((startup) => startup.industry == _selectedIndustry)
          .toList();
    }

    if (_selectedSkill != null) {
      startups = startups
          .where((startup) => startup.requiredSkills.contains(_selectedSkill))
          .toList();
    }

    if (_query.trim().isNotEmpty) {
      final query = _query.trim().toLowerCase();
      startups = startups.where((startup) {
        final haystack = [
          startup.companyName,
          startup.description,
          startup.industry,
          ...startup.requiredSkills,
          ...startup.openRoles.map((role) => role.title),
        ].join(' ').toLowerCase();
        return haystack.contains(query);
      }).toList();
    }

    return startups;
  }
=======
  final _searchController = TextEditingController();
  String? _industryFilter;
  String? _skillFilter;
>>>>>>> Stashed changes

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
                      'Your uploaded CV, portfolio link, and GitHub link will be visible to the startup.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    XPTextField(
                      controller: controller,
                      labelText: 'Short note',
                      hintText: 'Why are you a fit for this mission?',
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
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openLink(String? link) async {
    try {
      await LinkService.openExternal(link);
    } on XpServiceException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final student = appState.studentProfile;

    if (student == null) {
      return XPPageScaffold(
        title: 'Discover missions',
        subtitle: 'Complete your setup first',
        compact: true,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: XPEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'Finish your student profile',
              message:
                  'Upload your CV, add your skills, and include at least one work link before applying.',
              actionLabel: 'Complete setup',
              onAction: () => context.goNamed('studentSetup'),
            ),
          ),
        ),
      );
    }

    final industries = appState.missions
        .map((mission) => mission.industry)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
    final skills = appState.missions
        .expand((mission) => mission.requiredSkills)
        .toSet()
        .toList()
      ..sort();

    final applications = appState.getApplicationsForStudent(student.id);
    final appliedMissionIds = applications
        .map((application) => application.missionId)
        .whereType<String>()
        .toSet();

    final filteredMissions = appState.missions.where((mission) {
      if (!mission.isOpen) return false;
      if (_industryFilter != null && mission.industry != _industryFilter) {
        return false;
      }
      if (_skillFilter != null && !mission.requiredSkills.contains(_skillFilter)) {
        return false;
      }
      final query = _searchController.text.trim().toLowerCase();
      if (query.isEmpty) return true;
      final haystack = [
        mission.title,
        mission.startupName,
        mission.description,
        mission.industry ?? '',
        ...mission.requiredSkills,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();

    return XPPageScaffold(
      title: 'Discover missions',
      subtitle: 'Search live startup work and apply with your existing profile.',
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          XPHeaderButton(
            icon: Icons.description_outlined,
            onTap: () => context.goNamed('myApplications'),
          ),
          const SizedBox(width: AppSpacing.sm),
          XPHeaderButton(
            icon: Icons.person_outline_rounded,
            onTap: () => context.goNamed('studentProfile'),
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
      body: RefreshIndicator(
        onRefresh: appState.refreshSession,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.page,
          ),
          children: [
            XPSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back, ${student.name.split(' ').first}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    '${applications.length} applications tracked, ${student.missionsCompletedCount} missions completed, ${student.xpPoints} XP.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Search missions',
                            hintText: 'Role, company, or skill',
                            prefixIcon: Icon(Icons.search_rounded),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _industryFilter,
                          decoration: const InputDecoration(
                            labelText: 'Industry',
                          ),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All industries'),
                            ),
                            ...industries.map(
                              (industry) => DropdownMenuItem<String>(
                                value: industry,
                                child: Text(industry),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _industryFilter = value),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: _skillFilter,
                          decoration: const InputDecoration(labelText: 'Skill'),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All skills'),
                            ),
                            ...skills.map(
                              (skill) => DropdownMenuItem<String>(
                                value: skill,
                                child: Text(skill),
                              ),
                            ),
                          ],
                          onChanged: (value) => setState(() => _skillFilter = value),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (filteredMissions.isEmpty)
              XPEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No missions match these filters',
                message:
                    'Try clearing one filter or search for a broader skill area.',
                actionLabel: 'Clear filters',
                onAction: () {
                  setState(() {
                    _industryFilter = null;
                    _skillFilter = null;
                    _searchController.clear();
                  });
                },
              )
            else
              LayoutBuilder(
                builder: (context, constraints) {
                  final columns = constraints.maxWidth >= 980 ? 2 : 1;
                  final itemWidth =
                      (constraints.maxWidth - ((columns - 1) * AppSpacing.lg)) /
                          columns;

                  return Wrap(
                    spacing: AppSpacing.lg,
                    runSpacing: AppSpacing.lg,
                    children: filteredMissions.map((mission) {
                      final applied = appliedMissionIds.contains(mission.id);
                      return SizedBox(
                        width: itemWidth,
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
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mission.startupName,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.labelLarge?.copyWith(
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.xs),
                                        Text(
                                          mission.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge,
                                        ),
                                      ],
                                    ),
                                  ),
                                  XPBadge(
                                    label: mission.industry ?? 'Startup',
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                mission.description,
                                maxLines: 4,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context).textTheme.bodyMedium,
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
                                  XPBadge(
                                    label: mission.requiredSkills.isEmpty
                                        ? 'No required skills listed'
                                        : '${mission.requiredSkills.length} skills',
                                  ),
                                  if (mission.durationWeeks != null)
                                    XPBadge(label: '${mission.durationWeeks} weeks'),
                                ],
                              ),
                              if (mission.requiredSkills.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.md),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: mission.requiredSkills
                                      .take(5)
                                      .map(
                                        (skill) => XPBadge(
                                          label: skill,
                                          color: student.skills.contains(skill)
                                              ? AppTheme.primarySoft
                                              : null,
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.xl),
                              Row(
                                children: [
                                  Expanded(
                                    child: XPOutlinedButton(
                                      label: 'View company',
                                      size: XPButtonSize.small,
                                      onPressed: () => context.pushNamed(
                                        'startupDetail',
                                        pathParameters: {'id': mission.startupId},
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: XPButton(
                                      label: applied ? 'Applied' : 'Apply',
                                      size: XPButtonSize.small,
                                      onPressed: applied
                                          ? null
                                          : () => _showApplySheet(mission),
                                    ),
                                  ),
                                ],
                              ),
                              if ((mission.websiteUrl ?? '').isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                XPOutlinedButton(
                                  label: 'Open website',
                                  icon: Icons.open_in_new_rounded,
                                  size: XPButtonSize.small,
                                  onPressed: () => _openLink(mission.websiteUrl),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
