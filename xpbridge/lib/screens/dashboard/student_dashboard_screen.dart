import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/event_log_entry.dart';
import '../../models/startup_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_navigation.dart';
import '../../widgets/xp_section_title.dart';

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
  bool _statsExpanded = true;

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
    switch (level) {
      case 4:
        return 900;
      case 3:
        return 500;
      case 2:
        return 200;
      default:
        return 0;
    }
  }

  int? _nextLevelTarget(int level) {
    switch (level) {
      case 1:
        return 200;
      case 2:
        return 500;
      case 3:
        return 900;
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
    switch (level) {
      case 4:
        return 'Leader';
      case 3:
        return 'Achiever';
      case 2:
        return 'Contributor';
      default:
        return 'Explorer';
    }
  }

  String _firstName(String? name) {
    if (name == null || name.trim().isEmpty) return 'there';
    return name.trim().split(' ').first;
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
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
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
                        borderRadius: BorderRadius.circular(
                          AppTheme.pillRadius,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    'Level $level • ${_levelName(level)}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  XPProgressBar(progress: nextLevel != null ? progress : 1),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    nextLevel != null
                        ? '$xpInLevel / $xpNeeded XP in this level'
                        : 'Max level reached',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    'How to earn XP',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
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
            ),
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
                        'Filter missions',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Industry',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
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
                              onSelected: (_) => setModalState(
                                () => selectedIndustry = industry,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Skills',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
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
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: XPOutlinedButton(
                              label: 'Clear',
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
    final studentProfile = appState.studentProfile;
    final xpPoints = studentProfile?.xpPoints ?? 0;
    final level = studentProfile?.level ?? 1;
    final progress = _levelProgress(xpPoints, level);
    final nextLevel = _nextLevelTarget(level);
    final feedEvents = appState.eventLog;
    final feedOptOut = appState.xpFeedOptOut;
    final hasFilters = _selectedIndustry != null || _selectedSkill != null;
    final studentSkills = studentProfile?.skills ?? <String>[];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.page,
          ),
          children: [
            XPDashboardAppBar(
              eyebrow: 'Hello',
              title: _firstName(studentProfile?.name),
              subtitle:
                  'Discover startup missions that match your skills and growth goals.',
              leading: XPAvatar(initial: _firstName(studentProfile?.name)[0]),
              trailing: XPHeaderButton(
                icon: Icons.person_outline_rounded,
                onTap: () => context.pushNamed('studentProfile'),
              ),
              bottom: GestureDetector(
                onTap: () => _showLevelInfoSheet(context, xpPoints, level),
                child: XPContainer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          XPBadge(
                            label: 'Level $level',
                            color: AppTheme.primaryLight,
                          ),
                          const Spacer(),
                          Text(
                            '$xpPoints XP',
                            style: Theme.of(context).textTheme.labelLarge
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      XPProgressBar(progress: progress),
                      if (nextLevel != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${nextLevel - xpPoints} XP to Level ${level + 1}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ],
                  ),
                ),
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
                      hintText: 'Search missions, companies, or skills',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
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
                    child: Padding(
                      padding: EdgeInsets.zero,
                      child: Row(
                        children: [
                          Text(
                            'Your snapshot',
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
                  ),
                  if (_statsExpanded) ...[
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            label: 'Matches',
                            value: '${_filteredStartups.length}',
                            icon: Icons.rocket_launch_rounded,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MetricCard(
                            label: 'Skills',
                            value: '${studentProfile?.skills.length ?? 0}',
                            icon: Icons.psychology_alt_outlined,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: _MetricCard(
                            label: 'Hours',
                            value:
                                '${studentProfile?.availabilityHours.round() ?? 0}',
                            icon: Icons.schedule_rounded,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: _QuickActionCard(
                    title: 'AI Coach',
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => context.pushNamed('aiChat'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionCard(
                    title: 'Applications',
                    icon: Icons.description_outlined,
                    onTap: () => context.pushNamed('myApplications'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _QuickActionCard(
                    title: 'Profile',
                    icon: Icons.person_outline_rounded,
                    onTap: () => context.pushNamed('studentProfile'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            XPSection(
              title: 'Filters',
              action: hasFilters
                  ? TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedIndustry = null;
                          _selectedSkill = null;
                        });
                      },
                      child: const Text('Clear'),
                    )
                  : null,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                                  onTap: () => setState(
                                    () => _selectedIndustry = industry,
                                  ),
                                ),
                              ),
                            ),
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
                        ...studentSkills.map(
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
            if (!feedOptOut && feedEvents.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'XP Happening Now',
                action: TextButton(
                  onPressed: () =>
                      setState(() => _feedExpanded = !_feedExpanded),
                  child: Text(_feedExpanded ? 'Hide' : 'Show'),
                ),
                child: Column(
                  children:
                      (_feedExpanded ? feedEvents.take(4) : feedEvents.take(2))
                          .map((event) => _FeedRow(event: event))
                          .toList(),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            const XPSectionTitle(title: 'Recommended for you'),
            const SizedBox(height: AppSpacing.md),
            if (_filteredStartups.isEmpty)
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
                        Icons.search_off_rounded,
                        size: 34,
                        color: AppTheme.text,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'No matching missions',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Try clearing filters or updating your skills to expand the suggestions.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    XPOutlinedButton(
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
            else
              ..._filteredStartups.map((startup) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  child: _StartupCard(
                    startup: startup,
                    studentSkills: studentProfile?.skills ?? [],
                    onTap: () => context.pushNamed(
                      'startupDetail',
                      pathParameters: {'id': startup.id},
                    ),
                  ),
                );
              }),
          ],
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

class _MetricCard extends StatelessWidget {
  const _MetricCard({
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
          Icon(icon, color: AppTheme.text, size: 18),
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

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return XPCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            ),
            child: Icon(icon, color: AppTheme.text),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
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
                  style: Theme.of(
                    context,
                  ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  '$date • ${event.firstName}',
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

class _StartupCard extends StatelessWidget {
  const _StartupCard({
    required this.startup,
    required this.studentSkills,
    required this.onTap,
  });

  final StartupProfile startup;
  final List<String> studentSkills;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final matchCount = startup.requiredSkills
        .where((skill) => studentSkills.contains(skill))
        .length;
    final matchPercentage = startup.requiredSkills.isNotEmpty
        ? ((matchCount / startup.requiredSkills.length) * 100).round()
        : 0;

    return XPCard(
      onTap: onTap,
      elevated: true,
      radius: AppTheme.cornerRadiusLarge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(
                    AppTheme.cornerRadiusLarge,
                  ),
                ),
                child: Center(
                  child: Text(
                    startup.companyName[0].toUpperCase(),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      startup.companyName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      startup.industry,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (matchCount > 0)
                XPBadge(
                  label: '$matchPercentage% match',
                  color: AppTheme.primaryLight,
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            startup.description,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
          ),
          if (startup.openRoles.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: startup.openRoles
                  .take(2)
                  .map(
                    (role) => XPBadge(
                      label: role.title,
                      color: AppTheme.cardBackground,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: startup.requiredSkills
                .map(
                  (skill) => XPSkillTag(
                    label: skill,
                    isMatched: studentSkills.contains(skill),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.lg),
          XPOutlinedButton(
            label: 'View mission',
            icon: Icons.arrow_forward_rounded,
            onPressed: onTap,
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
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            ),
            child: Icon(icon, size: 18, color: AppTheme.text),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
          Text(
            xp,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
