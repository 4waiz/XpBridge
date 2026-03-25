import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../models/team_mission_config.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_section_title.dart';

class StartupSetupScreen extends StatefulWidget {
  const StartupSetupScreen({super.key});

  @override
  State<StartupSetupScreen> createState() => _StartupSetupScreenState();
}

class _StartupSetupScreenState extends State<StartupSetupScreen> {
  static const List<String> _teamRoleOptions = [
    'Product',
    'Design',
    'Dev',
    'Marketing',
    'Data',
    'Operations',
  ];

  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _projectDetailsController = TextEditingController();
  final _websiteController = TextEditingController();
  final _roleTitleController = TextEditingController();
  final _roleCommitmentController = TextEditingController();
  final _roleDescriptionController = TextEditingController();
  final _roleOutcomeController = TextEditingController();
  final _roleHoursController = TextEditingController();
  final _roleDurationController = TextEditingController();
  final _teamMinMembersController = TextEditingController(text: '2');
  final _teamMaxMembersController = TextEditingController(text: '4');
  String? _selectedIndustry;
  final Set<String> _requiredSkills = {};
  final List<StartupRole> _openRoles = [];
  final Set<String> _teamRequiredRoles = {};
  bool _isTeamMission = false;

  @override
  void initState() {
    super.initState();
    _selectedIndustry = DummyData.industries.first;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _projectDetailsController.dispose();
    _websiteController.dispose();
    _roleTitleController.dispose();
    _roleCommitmentController.dispose();
    _roleDescriptionController.dispose();
    _roleOutcomeController.dispose();
    _roleHoursController.dispose();
    _roleDurationController.dispose();
    _teamMinMembersController.dispose();
    _teamMaxMembersController.dispose();
    super.dispose();
  }

  bool get _canContinue {
    return _companyNameController.text.trim().isNotEmpty &&
        _descriptionController.text.trim().isNotEmpty &&
        _requiredSkills.length >= 2;
  }

  void _addRole() {
    final title = _roleTitleController.text.trim();
    final commitment = _roleCommitmentController.text.trim();
    final description = _roleDescriptionController.text.trim();
    final outcome = _roleOutcomeController.text.trim();
    final estimatedHours = int.tryParse(_roleHoursController.text.trim());
    final durationWeeks = int.tryParse(_roleDurationController.text.trim());
    final minMembers = int.tryParse(_teamMinMembersController.text.trim()) ?? 2;
    final maxMembers = int.tryParse(_teamMaxMembersController.text.trim()) ?? 4;

    if (title.isEmpty || outcome.isEmpty) {
      return;
    }

    final role = StartupRole(
      title: title,
      commitment: commitment.isNotEmpty ? commitment : null,
      description: description.isNotEmpty ? description : null,
      learningOutcome: outcome,
      estimatedHours: estimatedHours,
      durationWeeks: durationWeeks,
      teamMissionConfig: _isTeamMission
          ? TeamMissionConfig(
              requiredRoles: _teamRequiredRoles.toList(),
              maxMembers: maxMembers,
              teamSizeMin: minMembers,
              sharedLearningOutcome: outcome,
            )
          : null,
    );

    setState(() {
      _openRoles.add(role);
      _roleTitleController.clear();
      _roleCommitmentController.clear();
      _roleDescriptionController.clear();
      _roleOutcomeController.clear();
      _roleHoursController.clear();
      _roleDurationController.clear();
      _teamMinMembersController.text = '2';
      _teamMaxMembersController.text = '4';
      _teamRequiredRoles.clear();
      _isTeamMission = false;
    });
  }

  Future<void> _saveProfile() async {
    if (!_canContinue) return;

    final appState = AppStateScope.of(context);
    final user = SupabaseService.currentUser;
    if (user == null) {
      context.goNamed('login');
      return;
    }

    try {
      final profile = StartupProfile(
        id: user.id,
        companyName: _companyNameController.text,
        email: user.email ?? '',
        description: _descriptionController.text,
        industry: _selectedIndustry!,
        requiredSkills: _requiredSkills.toList(),
        openRoles: _openRoles.toList(),
        websiteUrl:
            _websiteController.text.isNotEmpty ? _websiteController.text : null,
        projectDetails: _projectDetailsController.text.isNotEmpty
            ? _projectDetailsController.text
            : null,
        createdAt: DateTime.now(),
      );

      // 1. Update Company Profile in the cloud
      await SupabaseService.updateProfile(
        id: user.id,
        data: {
          'company_name': profile.companyName,
          'industry': profile.industry,
          'website_url': profile.websiteUrl,
          'description': profile.description,
          'bio': profile.description, // Reusing for bio field
        },
      );

      // 2. Insert all Open Roles as Missions in the cloud
      for (final role in _openRoles) {
        await SupabaseService.createMission({
          'startup_id': user.id,
          'title': role.title,
          'description': role.description ?? profile.description,
          'commitment': role.commitment,
          'estimated_hours': role.estimatedHours,
          'learning_outcome': role.learningOutcome,
          'required_skills': profile.requiredSkills, // Company wide skills
          'status': 'open',
        });
      }

      // 3. Keep local cache for offline/instant use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('startup_name', _companyNameController.text);
      await prefs.setString('startup_id', profile.id);
      await prefs.setString('startup_description', _descriptionController.text);
      await prefs.setString('startup_industry', _selectedIndustry!);
      await prefs.setStringList('startup_skills', _requiredSkills.toList());
      await prefs.setString('startup_project', _projectDetailsController.text);
      await prefs.setString(
        'startup_roles',
        jsonEncode(_openRoles.map((role) => role.toMap()).toList()),
      );
      await prefs.setBool('is_logged_in', true);

      if (!mounted) return;
      appState.saveStartupProfile(profile);
      context.goNamed('startupDashboard');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save cloud startup profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                0,
              ),
              child: Row(
                children: [
                  XPHeaderButton(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => context.goNamed('signup'),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Set up your startup',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Create a polished company profile and define the roles students can apply to.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.lg,
                  AppSpacing.page,
                  120,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    XPSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const XPSectionTitle(
                            title: 'Company info',
                            subtitle: 'Present the company clearly and simply.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          XPTextField(
                            controller: _companyNameController,
                            labelText: 'Company name',
                            hintText: 'Enter your company name',
                            prefixIcon: Icons.business_rounded,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPTextField(
                            controller: _descriptionController,
                            labelText: 'Description',
                            hintText: 'What does your company do?',
                            prefixIcon: Icons.description_outlined,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPTextField(
                            controller: _websiteController,
                            labelText: 'Website',
                            hintText: 'https://yourcompany.com',
                            prefixIcon: Icons.language_rounded,
                            keyboardType: TextInputType.url,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPTextField(
                            controller: _projectDetailsController,
                            labelText: 'Project details',
                            hintText:
                                'What kind of work or learning opportunity are you offering?',
                            prefixIcon: Icons.lightbulb_outline_rounded,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    XPSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          XPSectionTitle(
                            title: 'Industry',
                            subtitle:
                                'Pick the category that best fits your company.',
                            actionLabel: _selectedIndustry,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: DummyData.industries.map((industry) {
                              return XPChoiceChip(
                                label: industry,
                                selected: _selectedIndustry == industry,
                                onSelected: (_) => setState(() {
                                  _selectedIndustry = industry;
                                }),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    XPSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          XPSectionTitle(
                            title: 'Required skills',
                            subtitle:
                                'Select between 2 and 4 skills students should have.',
                            actionLabel: '${_requiredSkills.length}/4',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          DropdownButtonFormField<String>(
                            key: ValueKey(
                              'required-skills-${_requiredSkills.join("|")}',
                            ),

                            decoration: const InputDecoration(
                              labelText: 'Add a skill',
                              hintText: 'Choose a required skill',
                              prefixIcon: Icon(Icons.auto_awesome_outlined),
                            ),
                            items: DummyData.skillPool
                                .where((skill) => !_requiredSkills.contains(skill))
                                .map((skill) {
                                  return DropdownMenuItem<String>(
                                    value: skill,
                                    child: Text(skill),
                                  );
                                })
                                .toList(),
                            onChanged: _requiredSkills.length >= 4
                                ? null
                                : (value) {
                                    if (value == null) return;
                                    setState(() {
                                      _requiredSkills.add(value);
                                    });
                                  },
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _requiredSkills.length >= 4
                                ? 'Maximum 4 skills selected.'
                                : 'Use the dropdown to add up to 4 skills.',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          if (_requiredSkills.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.lg),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _requiredSkills.map((skill) {
                                return XPSkillTag(
                                  label: skill,
                                  isMatched: true,
                                  onTap: () => setState(() {
                                    _requiredSkills.remove(skill);
                                  }),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    XPSection(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const XPSectionTitle(
                            title: 'Open roles',
                            subtitle:
                                'Draft roles students can apply for right away.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          XPTextField(
                            controller: _roleTitleController,
                            labelText: 'Role title',
                            hintText: 'e.g. Product Design Intern',
                            prefixIcon: Icons.work_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPTextField(
                            controller: _roleCommitmentController,
                            labelText: 'Commitment',
                            hintText: 'e.g. 10 hrs/week • Remote',
                            prefixIcon: Icons.schedule_rounded,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPTextField(
                            controller: _roleOutcomeController,
                            labelText: _isTeamMission
                                ? 'Shared learning outcome'
                                : 'Learning outcome',
                            hintText: 'What will the student walk away with?',
                            prefixIcon: Icons.rocket_launch_outlined,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SwitchListTile(
                            value: _isTeamMission,
                            onChanged: (value) =>
                                setState(() => _isTeamMission = value),
                            title: Text(
                              _isTeamMission
                                  ? 'Team mission'
                                  : 'Solo mission',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            subtitle: Text(
                              _isTeamMission
                                  ? 'Guilds can apply to this mission together.'
                                  : 'Single students can apply directly.',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                          if (_isTeamMission) ...[
                            const SizedBox(height: AppSpacing.md),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Required roles',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.sm,
                              runSpacing: AppSpacing.sm,
                              children: _teamRoleOptions.map((role) {
                                return XPChoiceChip(
                                  label: role,
                                  selected: _teamRequiredRoles.contains(role),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        _teamRequiredRoles.add(role);
                                      } else {
                                        _teamRequiredRoles.remove(role);
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
                                    controller: _teamMinMembersController,
                                    labelText: 'Min members',
                                    hintText: '2',
                                    prefixIcon: Icons.group_outlined,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.md),
                                Expanded(
                                  child: XPTextField(
                                    controller: _teamMaxMembersController,
                                    labelText: 'Max members',
                                    hintText: '4',
                                    prefixIcon: Icons.groups_rounded,
                                    keyboardType: TextInputType.number,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.md),
                          ],
                          XPTextField(
                            controller: _roleDescriptionController,
                            labelText: 'Role description',
                            hintText: 'Describe the work and expectations.',
                            prefixIcon: Icons.description_outlined,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          Row(
                            children: [
                              Expanded(
                                child: XPTextField(
                                  controller: _roleHoursController,
                                  labelText: 'Hours',
                                  hintText: '8',
                                  prefixIcon: Icons.timer_outlined,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: XPTextField(
                                  controller: _roleDurationController,
                                  labelText: 'Weeks',
                                  hintText: '6',
                                  prefixIcon: Icons.calendar_today_outlined,
                                  keyboardType: TextInputType.number,
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          XPOutlinedButton(
                            label: 'Add role',
                            icon: Icons.add_rounded,
                            onPressed: _addRole,
                          ),
                          if (_openRoles.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xl),
                            Column(
                              children: _openRoles.map((role) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: AppSpacing.md,
                                  ),
                                  child: XPCard(
                                    padding: const EdgeInsets.all(
                                      AppSpacing.lg,
                                    ),
                                    backgroundColor: AppTheme.cardBackground,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          role.title,
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleMedium
                                              ?.copyWith(
                                                fontWeight: FontWeight.w800,
                                              ),
                                        ),
                                        if (role.commitment != null) ...[
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            role.commitment!,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall,
                                          ),
                                        ],
                                        const SizedBox(height: AppSpacing.sm),
                                        if (role.teamMissionConfig != null) ...[
                                          XPBadge(
                                            label: 'Team Mission',
                                            icon: Icons.groups_rounded,
                                            color: AppTheme.primaryDeep,
                                            textColor: AppTheme.surface,
                                          ),
                                          const SizedBox(
                                            height: AppSpacing.sm,
                                          ),
                                        ],
                                        Text(
                                          role.learningOutcome,
                                          style: Theme.of(
                                            context,
                                          ).textTheme.bodyMedium,
                                        ),
                                        if (role.description?.isNotEmpty ==
                                            true) ...[
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            role.description!,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: AppTheme.textSecondary,
                                                ),
                                          ),
                                        ],
                                        if (role.teamMissionConfig != null) ...[
                                          const SizedBox(
                                            height: AppSpacing.sm,
                                          ),
                                          Wrap(
                                            spacing: AppSpacing.sm,
                                            runSpacing: AppSpacing.sm,
                                            children: [
                                              XPBadge(
                                                label:
                                                    '${role.teamMissionConfig!.teamSizeMin}-${role.teamMissionConfig!.maxMembers} members',
                                                icon: Icons.group_outlined,
                                              ),
                                              ...role.teamMissionConfig!
                                                  .requiredRoles
                                                  .map(
                                                    (item) => XPBadge(
                                                      label: item,
                                                      color:
                                                          AppTheme.primarySoft,
                                                    ),
                                                  ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: XPBottomActionBar(
        child: XPButton(
          label: 'Save and continue',
          icon: Icons.arrow_forward_rounded,
          onPressed: _canContinue ? _saveProfile : null,
        ),
      ),
    );
  }
}
