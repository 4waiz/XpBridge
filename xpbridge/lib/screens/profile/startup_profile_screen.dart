import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../models/team_mission_config.dart';
import '../../services/logo_image_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_premium.dart';

class StartupProfileScreen extends StatefulWidget {
  const StartupProfileScreen({super.key});

  @override
  State<StartupProfileScreen> createState() => _StartupProfileScreenState();
}

class _StartupProfileScreenState extends State<StartupProfileScreen> {
  static const List<String> _teamRoleOptions = [
    'Product',
    'Design',
    'Dev',
    'Marketing',
    'Data',
    'Operations',
  ];

  bool _savingLogo = false;

  Future<void> _handleLogout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!context.mounted) return;

    final appState = AppStateScope.of(context);
    appState.logout();
    context.goNamed('login');
  }

  Future<void> _persistRoles(List<StartupRole> roles) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'startup_roles',
      jsonEncode(roles.map((role) => role.toMap()).toList()),
    );
  }

  Future<void> _persistLogo(String base64) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(LogoImageService.storageKey, base64);
  }

  Future<ImageSource?> _chooseImageSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return XPPremiumSheet(
          title: 'Update logo',
          subtitle: 'Choose a source for your company mark.',
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Upload from gallery'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Take a photo'),
                onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _editLogo(AppState appState, StartupProfile? profile) async {
    if (profile == null || _savingLogo) return;

    final messenger = ScaffoldMessenger.of(context);
    final source = await _chooseImageSource();
    if (source == null) return;
    if (!mounted) return;

    setState(() => _savingLogo = true);
    try {
      final bytes = await LogoImageService.pickAndEdit(
        context: context,
        source: source,
      );
      if (bytes == null) return;

      final encoded = LogoImageService.encode(bytes);
      final updatedProfile = profile.copyWith(logoBase64: encoded);
      appState.saveStartupProfile(updatedProfile);
      await _persistLogo(encoded);

      if (!mounted) return;
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Company logo updated'),
          backgroundColor: AppTheme.successDark,
        ),
      );
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Could not update the logo. Please try again.'),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _savingLogo = false);
      }
    }
  }

  void _showAddRoleSheet(
    BuildContext context,
    AppState appState,
    StartupProfile? profile,
  ) {
    final titleController = TextEditingController();
    final commitmentController = TextEditingController();
    final descriptionController = TextEditingController();
    final outcomeController = TextEditingController();
    final hoursController = TextEditingController();
    final durationController = TextEditingController();
    final minMembersController = TextEditingController(text: '2');
    final maxMembersController = TextEditingController(text: '4');
    final selectedRoles = <String>{};
    bool isTeamMission = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) => XPPremiumSheet(
            title: 'Add a role',
            subtitle:
                'Create a polished opportunity without leaving this screen.',
            footer: XPButton(
            label: 'Add role',
            icon: Icons.add_rounded,
            onPressed: () async {
              final title = titleController.text.trim();
              final outcome = outcomeController.text.trim();
              if (title.isEmpty || outcome.isEmpty || profile == null) {
                return;
              }
              final hours = int.tryParse(hoursController.text.trim());
              final duration = int.tryParse(durationController.text.trim());
              final minMembers =
                  int.tryParse(minMembersController.text.trim()) ?? 2;
              final maxMembers =
                  int.tryParse(maxMembersController.text.trim()) ?? 4;

              final role = StartupRole(
                title: title,
                commitment: commitmentController.text.trim().isNotEmpty
                    ? commitmentController.text.trim()
                    : null,
                description: descriptionController.text.trim().isNotEmpty
                    ? descriptionController.text.trim()
                    : null,
                learningOutcome: outcome,
                estimatedHours: hours,
                durationWeeks: duration,
                teamMissionConfig: isTeamMission
                    ? TeamMissionConfig(
                        requiredRoles: selectedRoles.toList(),
                        maxMembers: maxMembers,
                        teamSizeMin: minMembers,
                        sharedLearningOutcome: outcome,
                      )
                    : null,
              );

              final updated = profile.copyWith(
                openRoles: [...profile.openRoles, role],
              );
              appState.saveStartupProfile(updated);
              await _persistRoles(updated.openRoles);
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added ${role.title}'),
                    backgroundColor: AppTheme.successDark,
                  ),
                );
              }
            },
            ),
            child: SingleChildScrollView(
            child: Column(
              children: [
                XPTextField(
                  controller: titleController,
                  labelText: 'Role title',
                  hintText: 'e.g. Software Engineer Intern',
                  prefixIcon: Icons.work_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                ),
                const SizedBox(height: AppSpacing.md),
                XPTextField(
                  controller: commitmentController,
                  labelText: 'Commitment',
                  hintText: '10 hrs/week · Remote',
                  prefixIcon: Icons.schedule_rounded,
                ),
                const SizedBox(height: AppSpacing.md),
                XPTextField(
                  controller: outcomeController,
                  labelText: isTeamMission
                      ? 'Shared learning outcome'
                      : 'Learning outcome',
                  hintText: 'What will the student learn or own?',
                  prefixIcon: Icons.rocket_launch_outlined,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                SwitchListTile(
                  value: isTeamMission,
                  onChanged: (value) =>
                      setModalState(() => isTeamMission = value),
                  title: Text(
                    isTeamMission ? 'Team mission' : 'Solo mission',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    isTeamMission
                        ? 'Guilds can apply as a team.'
                        : 'Single students apply directly.',
                  ),
                  contentPadding: EdgeInsets.zero,
                ),
                if (isTeamMission) ...[
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
                        selected: selectedRoles.contains(role),
                        onSelected: (selected) {
                          setModalState(() {
                            if (selected) {
                              selectedRoles.add(role);
                            } else {
                              selectedRoles.remove(role);
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
                          controller: minMembersController,
                          labelText: 'Min members',
                          hintText: '2',
                          prefixIcon: Icons.group_outlined,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: XPTextField(
                          controller: maxMembersController,
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
                  controller: descriptionController,
                  labelText: 'Description',
                  hintText: 'Describe the work and context.',
                  prefixIcon: Icons.description_outlined,
                  maxLines: 4,
                  textCapitalization: TextCapitalization.sentences,
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: XPTextField(
                        controller: hoursController,
                        labelText: 'Hours',
                        hintText: '8',
                        prefixIcon: Icons.timer_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: XPTextField(
                        controller: durationController,
                        labelText: 'Weeks',
                        hintText: '6',
                        prefixIcon: Icons.calendar_today_outlined,
                        keyboardType: TextInputType.number,
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

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final profile = appState.startupProfile;
    final Uint8List? logoBytes = LogoImageService.decode(profile?.logoBase64);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPScene(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              XPAppBar(
                title: 'Company Profile',
                subtitle: 'The surface candidates see first',
                trailing: XPHeaderButton(
                  icon: Icons.logout_rounded,
                  foregroundColor: AppTheme.error,
                  backgroundColor: AppTheme.surface.withValues(alpha: 0.72),
                  onTap: () => _handleLogout(context),
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    AppSpacing.page,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      XPGlassPanel(
                        backgroundColor: AppTheme.primaryDeep.withValues(
                          alpha: 0.82,
                        ),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryDeep,
                            AppTheme.primaryDark,
                            AppTheme.primary.withValues(alpha: 0.88),
                          ],
                        ),
                        borderColor: AppTheme.surface.withValues(alpha: 0.16),
                        shadow: AppTheme.heroCardShadow,
                        child: Column(
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  width: 118,
                                  height: 118,
                                  decoration: BoxDecoration(
                                    color: AppTheme.surface.withValues(
                                      alpha: 0.18,
                                    ),
                                    borderRadius: BorderRadius.circular(
                                      AppTheme.cornerRadiusLarge,
                                    ),
                                    image: logoBytes != null
                                        ? DecorationImage(
                                            image: MemoryImage(logoBytes),
                                            fit: BoxFit.cover,
                                          )
                                        : null,
                                  ),
                                  child: logoBytes != null
                                      ? null
                                      : Center(
                                          child: Text(
                                            profile?.companyName.isNotEmpty ==
                                                    true
                                                ? profile!.companyName[0]
                                                      .toUpperCase()
                                                : '?',
                                            style: Theme.of(context)
                                                .textTheme
                                                .displayMedium
                                                ?.copyWith(
                                                  color: AppTheme.surface,
                                                ),
                                          ),
                                        ),
                                ),
                                if (_savingLogo)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.black.withValues(
                                          alpha: 0.28,
                                        ),
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.cornerRadiusLarge,
                                        ),
                                      ),
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                AppTheme.surface,
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (profile != null)
                                  Positioned(
                                    right: -10,
                                    bottom: -10,
                                    child: XPHeaderButton(
                                      icon: Icons.edit_rounded,
                                      foregroundColor: AppTheme.surface,
                                      backgroundColor: AppTheme.surface
                                          .withValues(alpha: 0.18),
                                      onTap: () => _editLogo(appState, profile),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            Text(
                              profile?.companyName ?? 'Company',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium
                                  ?.copyWith(color: AppTheme.surface),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            XPBadge(
                              label: profile?.industry ?? 'Industry',
                              color: AppTheme.surface.withValues(alpha: 0.12),
                              textColor: AppTheme.surface,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      XPSection(
                        title: 'About company',
                        child: Text(
                          profile?.description ?? 'No description',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                      ),
                      if (profile?.websiteUrl?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Website',
                          child: XPBadge(
                            label: profile!.websiteUrl!,
                            icon: Icons.language_rounded,
                            color: AppTheme.primarySoft,
                          ),
                        ),
                      ],
                      if (profile?.requiredSkills.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Skills needed',
                          child: Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: profile!.requiredSkills
                                .map((skill) => XPSkillTag(label: skill))
                                .toList(),
                          ),
                        ),
                      ],
                      if (profile?.projectDetails?.isNotEmpty == true) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Project details',
                          child: Text(
                            profile!.projectDetails!,
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        ),
                      ],
                      const SizedBox(height: AppSpacing.xl),
                      XPSection(
                        title: 'Open roles',
                        action: XPOutlinedButton(
                          label: 'Add role',
                          icon: Icons.add_rounded,
                          expand: false,
                          size: XPButtonSize.small,
                          onPressed: () =>
                              _showAddRoleSheet(context, appState, profile),
                        ),
                        child: profile?.openRoles.isNotEmpty == true
                            ? Column(
                                children: profile!.openRoles.map((role) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: AppSpacing.md,
                                    ),
                                    child: XPCard(
                                      backgroundColor: AppTheme.surface
                                          .withValues(alpha: 0.56),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            role.title,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.titleLarge,
                                          ),
                                          if (role.teamMissionConfig != null) ...[
                                            const SizedBox(
                                              height: AppSpacing.xs,
                                            ),
                                            XPBadge(
                                              label: 'Team Mission',
                                              icon: Icons.groups_rounded,
                                              color: AppTheme.primaryDeep,
                                              textColor: AppTheme.surface,
                                            ),
                                          ],
                                          if (role.commitment?.isNotEmpty ==
                                              true) ...[
                                            const SizedBox(
                                              height: AppSpacing.xs,
                                            ),
                                            XPBadge(
                                              label: role.commitment!,
                                              icon: Icons.schedule_rounded,
                                            ),
                                          ],
                                          const SizedBox(height: AppSpacing.sm),
                                          Text(
                                            role.learningOutcome,
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodyMedium,
                                          ),
                                          if (role.description?.isNotEmpty ==
                                              true) ...[
                                            const SizedBox(
                                              height: AppSpacing.xs,
                                            ),
                                            Text(
                                              role.description!,
                                              style: Theme.of(
                                                context,
                                              ).textTheme.bodySmall,
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
                                          if (role.estimatedHours != null ||
                                              role.durationWeeks != null) ...[
                                            const SizedBox(
                                              height: AppSpacing.sm,
                                            ),
                                            Wrap(
                                              spacing: AppSpacing.sm,
                                              runSpacing: AppSpacing.sm,
                                              children: [
                                                if (role.estimatedHours != null)
                                                  XPBadge(
                                                    label:
                                                        '${role.estimatedHours} hrs',
                                                    icon: Icons.timer_outlined,
                                                  ),
                                                if (role.durationWeeks != null)
                                                  XPBadge(
                                                    label:
                                                        '${role.durationWeeks} weeks',
                                                    icon: Icons
                                                        .calendar_today_outlined,
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              )
                            : Text(
                                'No roles added yet.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                      ),
                    ],
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
