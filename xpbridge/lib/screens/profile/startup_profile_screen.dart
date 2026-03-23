import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../models/startup_profile.dart';
import '../../models/startup_role.dart';
import '../../services/logo_image_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';

class StartupProfileScreen extends StatefulWidget {
  const StartupProfileScreen({super.key});

  @override
  State<StartupProfileScreen> createState() => _StartupProfileScreenState();
}

class _StartupProfileScreenState extends State<StartupProfileScreen> {
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
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusLarge),
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: AppSpacing.sm),
                  Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                  ),
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
                  const SizedBox(height: AppSpacing.sm),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _editLogo(AppState appState, StartupProfile? profile) async {
    if (profile == null || _savingLogo) return;

    final source = await _chooseImageSource();
    if (source == null) return;

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Company logo updated'),
          backgroundColor: AppTheme.successDark,
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
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
            child: SingleChildScrollView(
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
                    'Add a role',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
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
                    hintText: '10 hrs/week • Remote',
                    prefixIcon: Icons.schedule_rounded,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  XPTextField(
                    controller: outcomeController,
                    labelText: 'Learning outcome',
                    hintText: 'What will the student learn or own?',
                    prefixIcon: Icons.rocket_launch_outlined,
                    maxLines: 2,
                    textCapitalization: TextCapitalization.sentences,
                  ),
                  const SizedBox(height: AppSpacing.md),
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
                  const SizedBox(height: AppSpacing.xl),
                  XPButton(
                    label: 'Add role',
                    icon: Icons.add_rounded,
                    onPressed: () async {
                      final title = titleController.text.trim();
                      final outcome = outcomeController.text.trim();
                      if (title.isEmpty || outcome.isEmpty || profile == null) {
                        return;
                      }
                      final hours = int.tryParse(hoursController.text.trim());
                      final duration = int.tryParse(
                        durationController.text.trim(),
                      );

                      final role = StartupRole(
                        title: title,
                        commitment: commitmentController.text.trim().isNotEmpty
                            ? commitmentController.text.trim()
                            : null,
                        description:
                            descriptionController.text.trim().isNotEmpty
                            ? descriptionController.text.trim()
                            : null,
                        learningOutcome: outcome,
                        estimatedHours: hours,
                        durationWeeks: duration,
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
                ],
              ),
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
      backgroundColor: AppTheme.background,
      appBar: XPAppBar(
        title: 'Company Profile',
        trailing: XPHeaderButton(
          icon: Icons.logout_rounded,
          foregroundColor: AppTheme.error,
          backgroundColor: AppTheme.error.withValues(alpha: 0.1),
          onTap: () => _handleLogout(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.md,
          AppSpacing.page,
          AppSpacing.page,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            XPSection(
              child: Column(
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 118,
                        height: 118,
                        decoration: BoxDecoration(
                          color: AppTheme.primary,
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
                                  profile?.companyName.isNotEmpty == true
                                      ? profile!.companyName[0].toUpperCase()
                                      : '?',
                                  style: Theme.of(context)
                                      .textTheme
                                      .displaySmall
                                      ?.copyWith(
                                        color: AppTheme.text,
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                              ),
                      ),
                      if (_savingLogo)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.28),
                              borderRadius: BorderRadius.circular(
                                AppTheme.cornerRadiusLarge,
                              ),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                        ),
                      if (profile != null)
                        Positioned(
                          right: -10,
                          bottom: -10,
                          child: XPHeaderButton(
                            icon: Icons.edit_rounded,
                            onTap: () => _editLogo(appState, profile),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    profile?.companyName ?? 'Company',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  XPBadge(
                    label: profile?.industry ?? 'Industry',
                    color: AppTheme.primaryLight,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            XPSection(
              title: 'About company',
              child: Text(
                profile?.description ?? 'No description',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
              ),
            ),
            if (profile?.websiteUrl?.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'Website',
                child: XPBadge(
                  label: profile!.websiteUrl!,
                  icon: Icons.language_rounded,
                  color: AppTheme.cardBackground,
                ),
              ),
            ],
            if (profile?.requiredSkills.isNotEmpty == true) ...[
              const SizedBox(height: AppSpacing.lg),
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
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                title: 'Project details',
                child: Text(
                  profile!.projectDetails!,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.lg),
            XPSection(
              title: 'Open roles',
              action: XPOutlinedButton(
                label: 'Add role',
                icon: Icons.add_rounded,
                expand: false,
                size: XPButtonSize.small,
                onPressed: () => _showAddRoleSheet(context, appState, profile),
              ),
              child: profile?.openRoles.isNotEmpty == true
                  ? Column(
                      children: profile!.openRoles.map((role) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.md),
                          child: XPCard(
                            backgroundColor: AppTheme.cardBackground,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.title,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                if (role.commitment?.isNotEmpty == true) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    role.commitment!,
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  role.learningOutcome,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                if (role.description?.isNotEmpty == true) ...[
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    role.description!,
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(
                                          color: AppTheme.textSecondary,
                                        ),
                                  ),
                                ],
                                if (role.estimatedHours != null ||
                                    role.durationWeeks != null) ...[
                                  const SizedBox(height: AppSpacing.sm),
                                  Wrap(
                                    spacing: AppSpacing.sm,
                                    runSpacing: AppSpacing.sm,
                                    children: [
                                      if (role.estimatedHours != null)
                                        XPBadge(
                                          label: '${role.estimatedHours} hrs',
                                          icon: Icons.timer_outlined,
                                        ),
                                      if (role.durationWeeks != null)
                                        XPBadge(
                                          label: '${role.durationWeeks} weeks',
                                          icon: Icons.calendar_today_outlined,
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
    );
  }
}
