import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/application.dart';
import '../../models/event_log_entry.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_mission_widgets.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_navigation.dart';
import '../../widgets/xp_premium.dart';
import '../../widgets/xp_section_title.dart';
import '../../widgets/xp_input.dart';
import '../../services/supabase_service.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> {
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
    var startups = DummyData.startups;

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  int _levelBase(int level) {
    if (level >= 10) return 6000;
    if (level >= 9) return 4800;
    if (level >= 8) return 3800;
    if (level >= 7) return 3000;
    if (level >= 6) return 2200;
    if (level >= 5) return 1500;
    if (level >= 4) return 900;
    if (level >= 3) return 500;
    if (level >= 2) return 200;
    return 0;
  }

  int? _nextLevelTarget(int level) {
    if (level >= 10) return null;
    switch (level) {
      case 1:
        return 200;
      case 2:
        return 500;
      case 3:
        return 900;
      case 4:
        return 1500;
      case 5:
        return 2200;
      case 6:
        return 3000;
      case 7:
        return 3800;
      case 8:
        return 4800;
      case 9:
        return 6000;
      default:
        return null;
    }
  }

  double _levelProgress(int xp, int level) {
    final next = _nextLevelTarget(level);
    if (next == null) return 1;
    final base = _levelBase(level);
    final span = (next - base).toDouble();
    if (span <= 0) return 1;
    return ((xp - base) / span).clamp(0, 1);
  }

  String _levelName(int level) {
    if (level >= 10) return 'Master';
    if (level >= 8) return 'Operator';
    if (level >= 6) return 'Builder';
    if (level >= 4) return 'Leader';
    if (level >= 2) return 'Contributor';
    return 'Explorer';
  }

  String _firstName(String? name) {
    if (name == null || name.trim().isEmpty) return 'there';
    return name.trim().split(' ').first;
  }

  double _matchProgress(StartupProfile startup, List<String> studentSkills) {
    if (startup.requiredSkills.isEmpty) return 0;
    final matchCount = startup.requiredSkills
        .where((skill) => studentSkills.contains(skill))
        .length;
    return (matchCount / startup.requiredSkills.length).clamp(0, 1);
  }

  String _matchLabel(StartupProfile startup, List<String> studentSkills) {
    final percentage = (_matchProgress(startup, studentSkills) * 100).round();
    return '$percentage% match';
  }

  List<String> _metaForStartup(StartupProfile startup) {
    final primaryRole = startup.openRoles.isNotEmpty
        ? startup.openRoles.first.title
        : 'Open opportunity';
    final commitment = startup.openRoles.firstOrNull?.commitment;
    return [
      startup.industry,
      primaryRole,
      if (commitment != null && commitment.isNotEmpty) commitment,
    ];
  }

  List<MapEntry<StartupProfile, StartupRole>> _teamMissionEntries(
    List<StartupProfile> startups,
  ) {
    return startups
        .expand(
          (startup) => startup.openRoles
              .where((role) => role.teamMissionConfig != null)
              .map((role) => MapEntry(startup, role)),
        )
        .toList();
  }

  void _showLevelInfoSheet(BuildContext context, int xp, int level) {
    final nextLevel = _nextLevelTarget(level);
    final progress = _levelProgress(xp, level);
    final base = _levelBase(level);
    final xpInLevel = xp - base;
    final xpNeeded = nextLevel != null ? nextLevel - base : 0;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return XPPremiumSheet(
          title: 'Level $level · ${_levelName(level)}',
          subtitle: nextLevel != null
              ? '$xpInLevel of $xpNeeded XP in this level'
              : 'You have reached the current cap.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              XPProgressBar(
                progress: nextLevel != null ? progress : 1,
                height: 10,
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'How XP moves',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              const _XpEarnRow(
                icon: Icons.rocket_launch_rounded,
                label: 'Complete a mission',
                xp: '+100',
              ),
              const _XpEarnRow(
                icon: Icons.edit_note_rounded,
                label: 'Submit a reflection',
                xp: '+15',
              ),
              const _XpEarnRow(
                icon: Icons.feedback_outlined,
                label: 'Receive startup feedback',
                xp: '+25',
              ),
              const _XpEarnRow(
                icon: Icons.star_rounded,
                label: 'First mission bonus',
                xp: '+50',
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFiltersSheet(List<String> studentSkills) {
    String? selectedIndustry = _selectedIndustry;
    String? selectedSkill = _selectedSkill;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return XPPremiumSheet(
              title: 'Refine your search',
              subtitle:
                  'Mix industry and skill filters without leaving discovery.',
              footer: Row(
                children: [
                  Expanded(
                    child: XPOutlinedButton(
                      label: 'Reset',
                      onPressed: () {
                        setModalState(() {
                          selectedIndustry = null;
                          selectedSkill = null;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: XPButton(
                      label: 'Apply',
                      onPressed: () {
                        setState(() {
                          _selectedIndustry = selectedIndustry;
                          _selectedSkill = selectedSkill;
                        });
                        Navigator.pop(sheetContext);
                      },
                    ),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Industry',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      XPChoiceChip(
                        label: 'All industries',
                        selected: selectedIndustry == null,
                        onSelected: (_) =>
                            setModalState(() => selectedIndustry = null),
                      ),
                      ...DummyData.industries.map(
                        (industry) => XPChoiceChip(
                          label: industry,
                          selected: selectedIndustry == industry,
                          onSelected: (_) =>
                              setModalState(() => selectedIndustry = industry),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text('Skill', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: AppSpacing.sm),
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
                      ...studentSkills.map(
                        (skill) => XPChoiceChip(
                          label: skill,
                          selected: selectedSkill == skill,
                          onSelected: (_) =>
                              setModalState(() => selectedSkill = skill),
                        ),
                      ),
                    ],
                  ),
                ],
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
    final studentProfile = appState.studentProfile;
    final studentSkills = studentProfile?.skills ?? <String>[];
    final xpPoints = studentProfile?.xpPoints ?? 0;
    final level = studentProfile?.level ?? 1;
    final progress = _levelProgress(xpPoints, level);
    final nextLevel = _nextLevelTarget(level);
    final feedEvents = appState.eventLog;
    final feedOptOut = appState.xpFeedOptOut;
    final hasFilters = _selectedIndustry != null || _selectedSkill != null;
    final sortedStartups = _sortedStartups(studentSkills);
    final featuredStartup = sortedStartups.isNotEmpty
        ? sortedStartups.first
        : null;
    final secondaryStartups = sortedStartups.length > 1
        ? sortedStartups.sublist(1)
        : const <StartupProfile>[];
    final currentGuild = studentProfile != null
        ? appState.getGuildForStudent(studentProfile.id)
        : null;
    final teamMissionEntries = _teamMissionEntries(sortedStartups);

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: XPScene(
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              120,
            ),
            children: [
              XPDashboardAppBar(
                eyebrow: 'Discovery',
                title: _firstName(studentProfile?.name),
                subtitle:
                    'AI-curated startup roles tuned to your skills, pace, and momentum.',
                leading: XPAvatar(initial: _firstName(studentProfile?.name)[0]),
                trailing: XPHeaderButton(
                  icon: Icons.person_outline_rounded,
                  foregroundColor: AppTheme.surface,
                  backgroundColor: AppTheme.surface.withValues(alpha: 0.14),
                  onTap: () => context.pushNamed('studentProfile'),
                ),
                bottom: GestureDetector(
                  onTap: () => _showLevelInfoSheet(context, xpPoints, level),
                  child: XPGlassPanel(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    backgroundColor: AppTheme.surface.withValues(alpha: 0.12),
                    borderColor: AppTheme.surface.withValues(alpha: 0.16),
                    shadow: const [],
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            XPBadge(
                              label: 'Level $level · ${_levelName(level)}',
                              color: AppTheme.surface.withValues(alpha: 0.12),
                              textColor: AppTheme.surface,
                            ),
                            const Spacer(),
                            Text(
                              '$xpPoints XP',
                              style: Theme.of(context).textTheme.labelLarge
                                  ?.copyWith(color: AppTheme.surface),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Theme(
                          data: Theme.of(context).copyWith(
                            progressIndicatorTheme:
                                const ProgressIndicatorThemeData(
                                  color: AppTheme.surface,
                                  linearTrackColor: Color(0x33FFFFFF),
                                ),
                          ),
                          child: XPProgressBar(progress: progress),
                        ),
                        if (nextLevel != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${nextLevel - xpPoints} XP to reach Level ${level + 1}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: AppTheme.surface.withValues(
                                    alpha: 0.78,
                                  ),
                                ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Row(
                children: [
                  Expanded(
                    child: XPPremiumSearchBar(
                      controller: _searchController,
                      hintText: 'Search roles, companies, or skills',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  XPHeaderButton(
                    icon: Icons.tune_rounded,
                    onTap: () => _showFiltersSheet(studentSkills),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    XPFilterChip(
                      label: 'All industries',
                      isSelected: _selectedIndustry == null,
                      onTap: () => setState(() => _selectedIndustry = null),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    ...DummyData.industries
                        .take(6)
                        .map(
                          (industry) => Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: XPFilterChip(
                              label: industry,
                              isSelected: _selectedIndustry == industry,
                              onTap: () =>
                                  setState(() => _selectedIndustry = industry),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
              if (studentSkills.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
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
                      ...studentSkills.map(
                        (skill) => Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: XPFilterChip(
                            label: skill,
                            isSelected: _selectedSkill == skill,
                            onTap: () => setState(() => _selectedSkill = skill),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              XPGlassPanel(
                padding: const EdgeInsets.all(AppSpacing.lg),
                backgroundColor: AppTheme.surface.withValues(alpha: 0.62),
                child: Row(
                  children: [
                    Expanded(
                      child: _QuickLinkPill(
                        title: 'AI Coach',
                        subtitle: 'Career guidance',
                        icon: Icons.auto_awesome_rounded,
                        onTap: () => context.pushNamed('aiChat'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _QuickLinkPill(
                        title: 'Tracking',
                        subtitle: 'Live application status',
                        icon: Icons.stacked_line_chart_rounded,
                        onTap: () => context.pushNamed('myApplications'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              XPSection(
                title: 'Guilds',
                subtitle:
                    currentGuild != null
                    ? 'Your guild can apply to larger, role-based team missions.'
                    : 'Create or join a guild to unlock team missions.',
                action: XPOutlinedButton(
                  label: 'Open guilds',
                  icon: Icons.groups_rounded,
                  expand: false,
                  size: XPButtonSize.small,
                  onPressed: () => context.pushNamed('guilds'),
                ),
                child: currentGuild == null
                    ? XPContainer(
                        child: Row(
                          children: [
                            const Icon(
                              Icons.group_add_outlined,
                              color: AppTheme.primaryDark,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'Build a cross-functional squad for product, design, development, and growth missions.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GuildPreviewCard(
                        guild: currentGuild,
                        members: appState.getGuildMembers(currentGuild.id),
                        activeMissions:
                            appState.getActiveGuildMissionCount(currentGuild.id),
                        onTap: () => context.pushNamed(
                          'guildDetail',
                          pathParameters: {'id': currentGuild.id},
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.xl),
              XPSectionTitle(
                title: 'Featured recommendation',
                subtitle: hasFilters
                    ? 'Filtered results that best fit your profile right now.'
                    : 'Best current fit based on your profile and recent momentum.',
              ),
              const SizedBox(height: AppSpacing.md),
              if (featuredStartup == null)
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
                          Icons.search_off_rounded,
                          size: 36,
                          color: AppTheme.surface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'No matching opportunities',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        'Try clearing the active filters or broadening the search.',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      XPButton(
                        label: 'Clear filters',
                        onPressed: () {
                          setState(() {
                            _selectedIndustry = null;
                            _selectedSkill = null;
                          });
                        },
                      ),
                    ],
                  ),
                )
              else ...[
                XPOpportunityCard(
                  featured: true,
                  company: featuredStartup.companyName,
                  title:
                      featuredStartup.openRoles.firstOrNull?.title ??
                      'Open opportunity',
                  description: featuredStartup.description,
                  meta: _metaForStartup(featuredStartup),
                  matchLabel: _matchLabel(featuredStartup, studentSkills),
                  primaryLabel: 'View details',
                  onTap: () => context.pushNamed(
                    'startupDetail',
                    pathParameters: {'id': featuredStartup.id},
                  ),
                  onPrimaryTap: () => context.pushNamed(
                    'startupDetail',
                    pathParameters: {'id': featuredStartup.id},
                  ),
                  skills: featuredStartup.requiredSkills
                      .map(
                        (skill) => XPSkillTag(
                          label: skill,
                          isMatched: studentSkills.contains(skill),
                        ),
                      )
                      .toList(),
                ),
                if (teamMissionEntries.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  const XPSectionTitle(
                    title: 'Team missions',
                    subtitle:
                        'Larger missions built for guilds with complementary roles.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  IntrinsicHeight(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: teamMissionEntries.take(5).map((entry) {
                          final startup = entry.key;
                          final role = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.md),
                            child: SizedBox(
                              width: 300,
                              child: TeamMissionSummaryCard(
                                company: startup.companyName,
                                title: role.title,
                                description:
                                    role.description ?? startup.description,
                                config: role.teamMissionConfig!,
                                onTap: () => context.pushNamed(
                                  'startupDetail',
                                  pathParameters: {'id': startup.id},
                                ),
                                ctaLabel: currentGuild != null
                                    ? 'Apply as guild'
                                    : 'View mission',
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                XPSectionTitle(
                  title: 'Ultra Micro Missions',
                  subtitle:
                      'Short, targeted tasks (2-5 hrs) to build XP quickly.',
                ),
                const SizedBox(height: AppSpacing.md),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: DummyData.startups
                        .where(
                          (s) => s.openRoles.any(
                            (r) =>
                                r.estimatedHours != null &&
                                r.estimatedHours! <= 5,
                          ),
                        )
                        .map((startup) {
                      final microRole = startup.openRoles.firstWhere(
                        (r) =>
                            r.estimatedHours != null && r.estimatedHours! <= 5,
                      );
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.md),
                        child: SizedBox(
                          width: 280,
                          child: XPCard(
                            onTap: () => context.pushNamed(
                              'startupDetail',
                              pathParameters: {'id': startup.id},
                            ),
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            backgroundColor: AppTheme.surface.withValues(
                              alpha: 0.52,
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.1,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.bolt_rounded,
                                        color: AppTheme.primary,
                                        size: 20,
                                      ),
                                    ),
                                    const Spacer(),
                                    XPBadge(
                                      label: '${microRole.estimatedHours}h',
                                      color: AppTheme.primaryDeep,
                                      textColor: AppTheme.surface,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  microRole.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleLarge,
                                ),
                                const SizedBox(height: AppSpacing.xxs),
                                Text(
                                  startup.companyName,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  microRole.description ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (secondaryStartups.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  XPSectionTitle(
                    title: 'More roles for you',
                    subtitle:
                        'A lighter stack of strong matches to browse quickly.',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...secondaryStartups.take(5).map((startup) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                      child: XPOpportunityCard(
                        company: startup.companyName,
                        title:
                            startup.openRoles.firstOrNull?.title ??
                            'Open opportunity',
                        description: startup.description,
                        meta: _metaForStartup(startup),
                        matchLabel: _matchLabel(startup, studentSkills),
                        onTap: () => context.pushNamed(
                          'startupDetail',
                          pathParameters: {'id': startup.id},
                        ),
                        onPrimaryTap: () => context.pushNamed(
                          'startupDetail',
                          pathParameters: {'id': startup.id},
                        ),
                        skills: startup.requiredSkills
                            .take(4)
                            .map(
                              (skill) => XPSkillTag(
                                label: skill,
                                isMatched: studentSkills.contains(skill),
                              ),
                            )
                            .toList(),
                      ),
                    );
                  }),
                ],
              ],
              // ── Live Opportunities from Supabase (real-time) ──
              const SizedBox(height: AppSpacing.xl),
              const XPSectionTitle(
                title: 'Live opportunities',
                subtitle:
                    'Posted by startups right now — updates in real time.',
              ),
              const SizedBox(height: AppSpacing.md),
              StreamBuilder<List<Map<String, dynamic>>>(
                stream: SupabaseService.missionsStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(AppSpacing.xl),
                        child: CircularProgressIndicator(),
                      ),
                    );
                  }
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return XPGlassPanel(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      backgroundColor:
                          AppTheme.surface.withValues(alpha: 0.52),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.cloud_off_rounded,
                            color: AppTheme.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              snapshot.hasError
                                  ? 'Could not load live missions. Check your connection.'
                                  : 'No live missions yet — new ones will appear instantly.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  final missions = snapshot.data!;
                  return Column(
                    children: missions.take(6).map((mission) {
                      final title =
                          mission['title'] as String? ?? 'Untitled';
                      final desc =
                          mission['description'] as String? ?? '';
                      final skills = List<String>.from(
                        mission['required_skills'] ?? [],
                      );
                      final hours =
                          mission['estimated_hours'] as int?;
                      final commitment =
                          mission['commitment'] as String?;
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: AppSpacing.md,
                        ),
                        child: XPCard(
                          backgroundColor:
                              AppTheme.surface.withValues(alpha: 0.56),
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.successDark
                                          .withValues(alpha: 0.12),
                                      borderRadius:
                                          BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.wifi_tethering_rounded,
                                      color: AppTheme.successDark,
                                      size: 18,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Expanded(
                                    child: Text(
                                      title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                  if (hours != null)
                                    XPBadge(
                                      label: '${hours}h',
                                      color: AppTheme.primaryDeep,
                                      textColor: AppTheme.surface,
                                    ),
                                ],
                              ),
                              if (commitment != null &&
                                  commitment.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.xs),
                                XPBadge(
                                  label: commitment,
                                  icon: Icons.schedule_rounded,
                                ),
                              ],
                              if (desc.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  desc,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall,
                                ),
                              ],
                              if (skills.isNotEmpty) ...[
                                const SizedBox(height: AppSpacing.sm),
                                Wrap(
                                  spacing: AppSpacing.sm,
                                  runSpacing: AppSpacing.sm,
                                  children: skills
                                      .take(4)
                                      .map(
                                        (skill) => XPSkillTag(
                                          label: skill,
                                          isMatched: studentSkills
                                              .contains(skill),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ],
                              const SizedBox(height: AppSpacing.md),
                              XPButton(
                                label: 'Apply',
                                icon: Icons.send_rounded,
                                size: XPButtonSize.small,
                                onPressed: () {
                                  _showApplySheet(
                                    context,
                                    mission: mission,
                                    title: title,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              if (!feedOptOut && feedEvents.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                XPSection(
                  title: 'Momentum feed',
                  subtitle: 'Recent wins from the XPBridge community.',
                  action: TextButton(
                    onPressed: () =>
                        setState(() => _feedExpanded = !_feedExpanded),
                    child: Text(_feedExpanded ? 'Hide' : 'Show'),
                  ),
                  child: Column(
                    children:
                        (_feedExpanded
                                ? feedEvents.take(4)
                                : feedEvents.take(2))
                            .map((event) => _FeedRow(event: event))
                            .toList(),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
      bottomNavigationBar: XPBottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          if (index == 1) {
            context.pushNamed('aiChat');
          } else if (index == 2) {
            context.pushNamed('myApplications');
          } else if (index == 3) {
            context.pushNamed('studentProfile');
          }
        },
        items: const [
          XPBottomNavItem(
            label: 'Discover',
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
          ),
          XPBottomNavItem(
            label: 'AI Chat',
            icon: Icons.auto_awesome_outlined,
            activeIcon: Icons.auto_awesome_rounded,
          ),
          XPBottomNavItem(
            label: 'Apps',
            icon: Icons.description_outlined,
            activeIcon: Icons.description_rounded,
          ),
          XPBottomNavItem(
            label: 'Profile',
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
          ),
        ],
      ),
    );
  }
}

class _QuickLinkPill extends StatelessWidget {
  const _QuickLinkPill({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return XPCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      backgroundColor: AppTheme.surface.withValues(alpha: 0.52),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGlowGradient,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
              boxShadow: AppTheme.softGlowShadow,
            ),
            child: Icon(icon, color: AppTheme.surface, size: 20),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xxs),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _FeedRow extends StatelessWidget {
  const _FeedRow({required this.event});

  final EventLogEntry event;

  @override
  Widget build(BuildContext context) {
    final date = '${event.timestamp.month}/${event.timestamp.day}';
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          XPAvatar(
            initial: event.firstName.isNotEmpty ? event.firstName[0] : '?',
            size: 42,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.displayText,
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$date · ${event.firstName}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _XpEarnRow extends StatelessWidget {
  const _XpEarnRow({required this.icon, required this.label, required this.xp});

  final IconData icon;
  final String label;
  final String xp;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGlowGradient,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            ),
            child: Icon(icon, size: 18, color: AppTheme.surface),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
          Text(xp, style: Theme.of(context).textTheme.labelLarge),
        ],
      ),
    );
  }
}

extension<T> on List<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
