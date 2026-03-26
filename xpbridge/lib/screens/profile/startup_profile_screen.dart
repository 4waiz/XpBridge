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
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_page_scaffold.dart';
import '../../widgets/xp_selectors.dart';

class StartupProfileScreen extends StatefulWidget {
  const StartupProfileScreen({super.key});

  @override
  State<StartupProfileScreen> createState() => _StartupProfileScreenState();
}

class _StartupProfileScreenState extends State<StartupProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _websiteController = TextEditingController();
  final _projectDetailsController = TextEditingController();
  String? _industry;
  List<String> _requiredSkills = [];
  String? _logoUrl;
  bool _isSaving = false;
  String? _submitError;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final profile = AppStateScope.of(context).startupProfile;
    if (profile != null) {
      _applyProfile(profile);
    }
    _loaded = true;
  }

  void _applyProfile(StartupProfile profile) {
    _companyNameController.text = profile.companyName;
    _descriptionController.text = profile.description;
    _websiteController.text = profile.websiteUrl ?? '';
    _projectDetailsController.text = profile.projectDetails ?? '';
    _industry = profile.industry;
    _requiredSkills = List<String>.from(profile.requiredSkills);
    _logoUrl = profile.logoUrl;
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    _descriptionController.dispose();
    _websiteController.dispose();
    _projectDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    try {
      setState(() => _isSaving = true);
      final picked = await AssetUploadService.pickLogo();
      if (picked == null) return;
      final url = await AssetUploadService.uploadLogo(user.id, picked);
      setState(() => _logoUrl = url);
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
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
                    Text('Add mission', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(labelText: 'Role title'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: descriptionController,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(labelText: 'Description'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: outcomeController,
                      minLines: 2,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Learning outcome',
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: commitmentController,
                      decoration: const InputDecoration(labelText: 'Commitment'),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: hoursController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Hours'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: TextField(
                            controller: durationController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(labelText: 'Weeks'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    SwitchListTile(
                      value: isTeamMission,
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Team mission'),
                      onChanged: (value) =>
                          setModalState(() => isTeamMission = value),
                    ),
                    if (isTeamMission) ...[
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        runSpacing: AppSpacing.sm,
                        children: [
                          'Product',
                          'Design',
                          'Dev',
                          'Marketing',
                          'Data',
                          'Operations',
                        ].map((role) {
                          return FilterChip(
                            label: Text(role),
                            selected: teamRoles.contains(role),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
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
                    const SizedBox(height: AppSpacing.xl),
                    XPButton(
                      label: 'Create mission',
                      onPressed: () async {
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
                        await AppStateScope.of(context).createMission(role);
                        if (!context.mounted) return;
                        Navigator.pop(sheetContext);
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

  Future<void> _save() async {
    final appState = AppStateScope.of(context);
    final current = appState.startupProfile;
    final user = SupabaseService.currentUser;
    if (current == null || user == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_industry == null || _requiredSkills.length < 2) {
      setState(() => _submitError = 'Select an industry and at least 2 skills.');
      return;
    }

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final updated = current.copyWith(
      companyName: _companyNameController.text.trim(),
      description: _descriptionController.text.trim(),
      websiteUrl: _websiteController.text.trim(),
      projectDetails: _projectDetailsController.text.trim(),
      industry: _industry,
      requiredSkills: _requiredSkills,
      logoUrl: _logoUrl,
    );

    try {
      await appState.persistStartupProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company profile updated.'),
          backgroundColor: AppTheme.successDark,
        ),
      );
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _logout() async {
    final appState = AppStateScope.of(context);
    await appState.logout();
    if (!mounted) return;
    context.goNamed('login');
  }

  Future<void> _showDeleteDialog() async {
    final appState = AppStateScope.of(context);
    final otpController = TextEditingController();
    final confirmTextController = TextEditingController();
    bool otpSent = false;
    String? dialogError;
    bool processing = false;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.sheetBackground,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              title: const Text(
                'Delete Account',
                style: TextStyle(color: AppTheme.error),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This action is PERMANENT. Your startup profile, missions, and all linked data will be deleted.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (!otpSent) ...[
                      const Text(
                        'To continue, we will send a 6-digit confirmation code to your registered email.',
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      XPButton(
                        label: 'Send OTP',
                        loading: processing,
                        onPressed: processing
                            ? null
                            : () async {
                                setDialogState(() {
                                  processing = true;
                                  dialogError = null;
                                });
                                try {
                                  await appState.requestDeleteAccount();
                                  setDialogState(() {
                                    otpSent = true;
                                    processing = false;
                                  });
                                } catch (e) {
                                  final errorText = e.toString();
                                  if (errorText.contains('session has expired')) {
                                    if (!dialogContext.mounted || !context.mounted) {
                                      return;
                                    }
                                    if (Navigator.of(dialogContext).canPop()) {
                                      Navigator.pop(dialogContext);
                                    }
                                    context.goNamed('login');
                                    return;
                                  }
                                  setDialogState(() {
                                    processing = false;
                                    dialogError = errorText;
                                  });
                                }
                              },
                      ),
                    ] else ...[
                      const Text(
                        'Enter the 6-digit code sent to your email:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: '000000',
                          counterText: '',
                        ),
                        maxLength: 6,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Type "DELETE" below to confirm final decision:',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextField(
                        controller: confirmTextController,
                        decoration: const InputDecoration(hintText: 'DELETE'),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      XPButton(
                        label: 'Verify & Delete Forever',
                        backgroundColor: AppTheme.error,
                        loading: processing,
                        onPressed: processing ? null : () async {
                          if (confirmTextController.text.trim() != 'DELETE') {
                            setDialogState(
                              () => dialogError = 'Please type DELETE to confirm.',
                            );
                            return;
                          }
                          if (otpController.text.trim().length != 6) {
                            setDialogState(
                              () => dialogError = 'Please enter a valid OTP.',
                            );
                            return;
                          }
                          setDialogState(() {
                            processing = true;
                            dialogError = null;
                          });
                          try {
                            await appState.confirmDeleteAccount(
                              otpController.text.trim(),
                            );
                            if (!mounted || !dialogContext.mounted || !context.mounted) {
                              return;
                            }
                            Navigator.pop(dialogContext); // Close dialog
                            context.goNamed('login');
                          } catch (e) {
                            final errorText = e.toString();
                            if (errorText.contains('session has expired')) {
                              if (!dialogContext.mounted || !context.mounted) {
                                return;
                              }
                              if (Navigator.of(dialogContext).canPop()) {
                                Navigator.pop(dialogContext);
                              }
                              context.goNamed('login');
                              return;
                            }
                            setDialogState(() {
                              processing = false;
                              dialogError = errorText;
                            });
                          }
                        },
                      ),
                    ],
                    if (dialogError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        dialogError!,
                        style: const TextStyle(color: AppTheme.error, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: processing ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final profile = appState.startupProfile;
    final missions = appState.missions
        .where((mission) => mission.startupId == profile?.id)
        .toList();

    if (profile == null) {
      return XPPageScaffold(
        title: 'Company profile',
        subtitle: 'Not set up yet',
        showBack: true,
        compact: true,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: XPEmptyState(
              icon: Icons.business_rounded,
              title: 'No startup profile yet',
              message: 'Finish setup to manage your company profile.',
              actionLabel: 'Go to setup',
              onAction: () => context.goNamed('startupSetup'),
            ),
          ),
        ),
      );
    }

    return XPPageScaffold(
      title: 'Company profile',
      subtitle: 'Edit public company details and mission inventory.',
      showBack: true,
      compact: true,
      trailing: XPHeaderButton(icon: Icons.logout_rounded, onTap: _logout),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.page,
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
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Company name is required'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Company name',
                        prefixIcon: Icon(Icons.business_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _descriptionController,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Description is required'
                          : null,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        prefixIcon: Icon(Icons.description_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _websiteController,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Website is required'
                          : null,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Website',
                        prefixIcon: Icon(Icons.language_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _projectDetailsController,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Project details are required'
                          : null,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Project details',
                        prefixIcon: Icon(Icons.lightbulb_outline_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPSingleSelectField(
                label: 'Industry',
                hint: 'Select an industry',
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Logo',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            _logoUrl == null
                                ? 'Optional, but recommended for trust.'
                                : 'Logo uploaded.',
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
              ),
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'Live missions',
                subtitle: 'These are visible to students right now.',
                action: XPOutlinedButton(
                  label: 'Add mission',
                  expand: false,
                  size: XPButtonSize.medium,
                  onPressed: _showRoleSheet,
                ),
                child: missions.isEmpty
                    ? const Text('No missions created yet.')
                    : Column(
                        children: missions.map((mission) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.md),
                            child: XPCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              backgroundColor: AppTheme.primarySoft,
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
                                              mission.title,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleMedium,
                                            ),
                                            const SizedBox(height: AppSpacing.xs),
                                            Text(
                                              mission.description,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall,
                                            ),
                                          ],
                                        ),
                                      ),
                                      XPOutlinedButton(
                                        label: 'Delete',
                                        expand: false,
                                        size: XPButtonSize.small,
                                        onPressed: () =>
                                            appState.deleteMission(mission.id),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      if ((mission.commitment ?? '').isNotEmpty)
                                        XPBadge(label: mission.commitment!),
                                      if (mission.isTeamMission)
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
              const SizedBox(height: AppSpacing.xl),
              XPButton(
                label: 'Save changes',
                icon: Icons.check_rounded,
                loading: _isSaving,
                onPressed: _isSaving ? null : _save,
              ),
              const SizedBox(height: AppSpacing.xxxl),
              Center(
                child: Opacity(
                  opacity: 0.6,
                  child: XPButton(
                    label: 'Delete account',
                    size: XPButtonSize.small,
                    backgroundColor: AppTheme.error,
                    onPressed: _showDeleteDialog,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
