import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../models/team_mission_config.dart';
import '../../services/asset_upload_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_mission_widgets.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_page_scaffold.dart';
import '../../widgets/xp_selectors.dart';

class StartupSetupScreen extends StatefulWidget {
  const StartupSetupScreen({super.key});

  @override
  State<StartupSetupScreen> createState() => _StartupSetupScreenState();
}

class _StartupSetupScreenState extends State<StartupSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _projectDetailsController = TextEditingController();
  String? _industry;
  List<String> _requiredSkills = [];
  List<StartupRole> _roles = [];
  String? _logoUrl;
  String? _logoName;
  bool _isSaving = false;
  String? _submitError;

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _projectDetailsController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String label) {
    if ((value?.trim() ?? '').isEmpty) {
      return '$label is required';
    }
    return null;
  }

  Future<void> _pickLogo() async {
    final user = SupabaseService.currentUser;
    if (user == null) {
      setState(() => _submitError = 'Please log in again.');
      return;
    }

    PickedAsset? picked;
    try {
      picked = await AssetUploadService.pickLogo();
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
      return;
    }
    if (picked == null) return;

    final previousUrl = _logoUrl;
    setState(() {
      _isSaving = true;
      _submitError = null;
    });
    try {
      final url = await AssetUploadService.uploadLogo(user.id, picked);
      await SupabaseService.updateProfile(
        id: user.id,
        data: {'logo_url': url},
      );
      if (previousUrl != null && previousUrl != url) {
        await SupabaseService.tryDeleteStorageObject(previousUrl);
      }
      if (!mounted) return;
      setState(() {
        _logoUrl = url;
        _logoName = picked!.fileName;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logo uploaded.')),
      );
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _showRoleSheet() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final outcomeController = TextEditingController();
    final commitmentController = TextEditingController();
    final hoursController = TextEditingController();
    final durationController = TextEditingController();
    final teamRoles = <String>[];
    bool isTeamMission = false;

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
                  height: mediaQuery.size.height * 0.88,
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
                    Text('Add mission', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: titleController,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Role title',
                        prefixIcon: Icon(Icons.work_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Role description',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: outcomeController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Learning outcome',
                        prefixIcon: Icon(Icons.auto_awesome_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (stackFields)
                      Column(
                        children: [
                          TextField(
                            controller: commitmentController,
                            decoration: const InputDecoration(
                              labelText: 'Commitment',
                              hintText: '10 hrs/week',
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          TextField(
                            controller: hoursController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Hours',
                              hintText: '8',
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: commitmentController,
                              decoration: const InputDecoration(
                                labelText: 'Commitment',
                                hintText: '10 hrs/week',
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: TextField(
                              controller: hoursController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Hours',
                                hintText: '8',
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: durationController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Duration in weeks',
                        hintText: '6',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      value: isTeamMission,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Team mission'),
                      subtitle: const Text(
                        'Enable this only if multiple students should apply together.',
                      ),
                      onChanged: (value) =>
                          setModalState(() => isTeamMission = value),
                    ),
                    if (isTeamMission) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: const [
                          'Product',
                          'Design',
                          'Dev',
                          'Marketing',
                          'Data',
                          'Operations',
                        ].map((role) {
                          final selected = teamRoles.contains(role);
                          return FilterChip(
                            label: Text(role),
                            selected: selected,
                            onSelected: (value) {
                              setModalState(() {
                                if (value) {
                                  teamRoles.add(role);
                                } else {
                                  teamRoles.remove(role);
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
                      label: 'Add mission',
                      onPressed: () {
                        final title = titleController.text.trim();
                        final description = descriptionController.text.trim();
                        final outcome = outcomeController.text.trim();
                        if (title.isEmpty || description.isEmpty || outcome.isEmpty) {
                          return;
                        }
                        final role = StartupRole(
                          title: title,
                          description: description,
                          learningOutcome: outcome,
                          commitment: commitmentController.text.trim().isEmpty
                              ? null
                              : commitmentController.text.trim(),
                          estimatedHours:
                              int.tryParse(hoursController.text.trim()),
                          durationWeeks:
                              int.tryParse(durationController.text.trim()),
                          teamMissionConfig: isTeamMission
                              ? TeamMissionConfig(
                                  requiredRoles: teamRoles,
                                  teamSizeMin: 2,
                                  maxMembers: 4,
                                  sharedLearningOutcome: outcome,
                                )
                              : null,
                        );
                        setState(() => _roles = [..._roles, role]);
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

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_industry == null) {
      setState(() => _submitError = 'Select an industry.');
      return;
    }
    if (_requiredSkills.length < 2 || _requiredSkills.length > 4) {
      setState(() => _submitError = 'Select between 2 and 4 required skills.');
      return;
    }
    if (_roles.isEmpty) {
      setState(() => _submitError = 'Add at least one mission before continuing.');
      return;
    }

    final user = SupabaseService.currentUser;
    if (user == null) {
      context.goNamed('login');
      return;
    }

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final profile = StartupProfile(
      id: user.id,
      companyName: _companyNameController.text.trim(),
      email: user.email ?? '',
      description: _descriptionController.text.trim(),
      industry: _industry!,
      requiredSkills: _requiredSkills,
      openRoles: const [],
      websiteUrl: _websiteController.text.trim().isEmpty
          ? null
          : _websiteController.text.trim(),
      logoUrl: _logoUrl,
      projectDetails: _projectDetailsController.text.trim().isEmpty
          ? null
          : _projectDetailsController.text.trim(),
      createdAt: DateTime.now(),
    );

    try {
      final appState = AppStateScope.of(context);
      await appState.persistStartupProfile(profile);
      for (final role in _roles) {
        await appState.createMission(role);
      }
      if (!mounted) return;
      context.goNamed('startupDashboard');
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return XPPageScaffold(
      title: 'Set up your startup',
      subtitle: 'Tight company details, a real website, and at least one mission keep this reviewable.',
      showBack: true,
      onBack: () => AppStateScope.of(context).logout(),
      compact: true,
      bottomBar: XPBottomActionBar(
        child: XPButton(
          label: 'Save and continue',
          icon: Icons.arrow_forward_rounded,
          loading: _isSaving,
          onPressed: _isSaving ? null : _saveProfile,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          130,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              XPSection(
                child: Column(
                  children: [
                    TextFormField(
                      controller: _companyNameController,
                      validator: (value) => _validateRequired(value, 'Company name'),
                      decoration: const InputDecoration(
                        labelText: 'Company name',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      minLines: 3,
                      maxLines: 4,
                      validator: (value) => _validateRequired(value, 'Description'),
                      decoration: const InputDecoration(
                        labelText: 'Company description',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _websiteController,
                      validator: (value) => _validateRequired(value, 'Website'),
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Company website',
                        hintText: 'https://company.com',
                        prefixIcon: Icon(Icons.language_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _projectDetailsController,
                      minLines: 3,
                      maxLines: 4,
                      validator: (value) => _validateRequired(value, 'Project details'),
                      decoration: const InputDecoration(
                        labelText: 'What are students joining?',
                        prefixIcon: Icon(Icons.lightbulb_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPSingleSelectField(
                label: 'Industry',
                hint: 'Select industry',
                options: DummyData.industries,
                value: _industry,
                onChanged: (value) => setState(() => _industry = value),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPMultiSelectField(
                label: 'Required skills',
                hint: 'Select 2-4 skills',
                options: DummyData.skillPool,
                values: _requiredSkills,
                minSelection: 2,
                maxSelection: 4,
                onChanged: (values) => setState(() => _requiredSkills = values),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Company logo',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.xs),
                              Text(
                                _logoName ?? 'Optional, but recommended.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                        XPOutlinedButton(
                          label: _logoUrl == null ? 'Upload' : 'Replace',
                          expand: false,
                          size: XPButtonSize.small,
                          onPressed: _isSaving ? null : _pickLogo,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                action: XPOutlinedButton(
                  label: 'Add mission',
                  expand: false,
                  size: XPButtonSize.medium,
                  onPressed: _showRoleSheet,
                ),
                title: 'Open missions',
                subtitle:
                    'Keep this tight. One or two clear roles is better than a huge wall of options.',
                child: _roles.isEmpty
                    ? const Text('No missions added yet.')
                    : Column(
                        children: _roles.map((role) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: XPCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              backgroundColor: AppTheme.primarySoft,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    role.title,
                                    style: Theme.of(context).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    role.description ?? role.learningOutcome,
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      if (role.commitment?.isNotEmpty == true)
                                        XPBadge(
                                          label: role.commitment!,
                                          icon: Icons.schedule_rounded,
                                        ),
                                      XPBadge(
                                        label: role.estimatedHours != null
                                            ? '${role.estimatedHours} hrs'
                                            : 'Flexible',
                                      ),
                                      if (role.teamMissionConfig != null)
                                        const TeamMissionBadge(compact: true),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
              ),
              if (_submitError != null) ...[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _submitError!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.error,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
