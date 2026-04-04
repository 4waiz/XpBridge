import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:url_launcher/url_launcher.dart';

import '../../app.dart';
import '../../config/legal_urls.dart';
import '../../data/dummy_data.dart';
import '../../models/student_profile.dart';
import '../../services/asset_upload_service.dart';
import '../../services/link_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_page_scaffold.dart';
import '../../widgets/xp_selectors.dart';

class StudentProfileScreen extends StatefulWidget {
  const StudentProfileScreen({super.key});

  @override
  State<StudentProfileScreen> createState() => _StudentProfileScreenState();
}

class _StudentProfileScreenState extends State<StudentProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _educationController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _githubController = TextEditingController();
  List<String> _skills = [];
  double _hours = 10;
  String? _resumeUrl;
  String? _resumeFileName;
  String? _resumeMimeType;
  bool _isSaving = false;
  String? _submitError;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final profile = AppStateScope.of(context).studentProfile;
    if (profile != null) {
      _applyProfile(profile);
    }
    _loaded = true;
  }

  void _applyProfile(StudentProfile profile) {
    _nameController.text = profile.name;
    _bioController.text = profile.bio ?? '';
    _educationController.text = profile.education ?? '';
    _portfolioController.text = profile.portfolioUrl ?? '';
    _githubController.text = profile.githubUrl ?? '';
    _skills = List<String>.from(profile.skills);
    _hours = profile.availabilityHours.clamp(2.0, 30.0);
    _resumeUrl = profile.resumeUrl;
    _resumeFileName = profile.resumeFileName;
    _resumeMimeType = profile.resumeMimeType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _educationController.dispose();
    _portfolioController.dispose();
    _githubController.dispose();
    super.dispose();
  }

  Future<void> _pickResume() async {
    final user = SupabaseService.currentUser;
    if (user == null) return;
    try {
      setState(() => _isSaving = true);
      final picked = await AssetUploadService.pickResume();
      if (picked == null) return;
      final url = await AssetUploadService.uploadResume(user.id, picked);
      setState(() {
        _resumeUrl = url;
        _resumeFileName = picked.fileName;
        _resumeMimeType = picked.mimeType;
      });
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _save() async {
    final appState = AppStateScope.of(context);
    final current = appState.studentProfile;
    final user = SupabaseService.currentUser;
    if (current == null || user == null) return;
    if (!_formKey.currentState!.validate()) return;
    if (_skills.length < 2 || (_resumeUrl ?? '').isEmpty) {
      setState(
        () => _submitError = 'Keep 2-4 skills selected and make sure a CV is uploaded.',
      );
      return;
    }

    setState(() {
      _isSaving = true;
      _submitError = null;
    });

    final updated = current.copyWith(
      name: _nameController.text.trim(),
      bio: _bioController.text.trim(),
      education: _educationController.text.trim(),
      skills: _skills,
      availabilityHours: _hours,
      portfolioUrl: _portfolioController.text.trim().isEmpty
          ? null
          : _portfolioController.text.trim(),
      githubUrl: _githubController.text.trim().isEmpty
          ? null
          : _githubController.text.trim(),
      resumeUrl: _resumeUrl,
      resumeFileName: _resumeFileName,
      resumeMimeType: _resumeMimeType,
    );

    try {
      await appState.persistStudentProfile(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated.'),
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

  Future<void> _showDeleteDialog() async {
    final appState = AppStateScope.of(context);
    final passwordController = TextEditingController();
    String? dialogError;
    bool processing = false;
    bool obscure = true;

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
                      'This action is PERMANENT. All your data, levels, and progress will be erased forever.',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const Text(
                      'Enter your password to confirm:',
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: passwordController,
                      obscureText: obscure,
                      decoration: InputDecoration(
                        hintText: 'Your password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          icon: Icon(obscure
                              ? Icons.visibility_off_rounded
                              : Icons.visibility_rounded),
                          onPressed: () =>
                              setDialogState(() => obscure = !obscure),
                        ),
                      ),
                    ),
                    if (dialogError != null) ...[
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        dialogError!,
                        style: const TextStyle(
                            color: AppTheme.error, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: AppSpacing.lg),
                    XPButton(
                      label: 'Delete Forever',
                      backgroundColor: AppTheme.error,
                      loading: processing,
                      onPressed: processing
                          ? null
                          : () async {
                              final password =
                                  passwordController.text.trim();
                              if (password.isEmpty) {
                                setDialogState(() => dialogError =
                                    'Enter your password to continue.');
                                return;
                              }
                              setDialogState(() {
                                processing = true;
                                dialogError = null;
                              });
                              try {
                                await appState
                                    .deleteAccountWithPassword(password);
                                if (!dialogContext.mounted ||
                                    !context.mounted) {
                                  return;
                                }
                                Navigator.pop(dialogContext);
                                context.goNamed('login');
                              } catch (e) {
                                final errorText = e is XpServiceException
                                    ? e.message
                                    : e.toString();
                                if (errorText
                                    .contains('session has expired')) {
                                  if (!dialogContext.mounted ||
                                      !context.mounted) {
                                    return;
                                  }
                                  Navigator.pop(dialogContext);
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
                ),
              ),
              actions: [
                TextButton(
                  onPressed: processing
                      ? null
                      : () => Navigator.pop(dialogContext),
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
    final profile = appState.studentProfile;
    if (profile == null) {
      return XPPageScaffold(
        title: 'Your profile',
        subtitle: 'Not set up yet',
        showBack: true,
        compact: true,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: XPEmptyState(
              icon: Icons.person_outline_rounded,
              title: 'No student profile yet',
              message: 'Finish setup to manage your profile.',
              actionLabel: 'Go to setup',
              onAction: () => context.goNamed('studentSetup'),
            ),
          ),
        ),
      );
    }

    return XPPageScaffold(
      title: 'Your profile',
      subtitle: 'Keep your CV, links, and skills current.',
      showBack: true,
      compact: true,
      trailing: XPHeaderButton(
        icon: Icons.logout_rounded,
        onTap: _logout,
      ),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Level ${profile.level} • ${profile.xpPoints} XP',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _nameController,
                      validator: (value) =>
                          (value?.trim().isEmpty ?? true) ? 'Name is required' : null,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _educationController,
                      validator: (value) => (value?.trim().isEmpty ?? true)
                          ? 'Education is required'
                          : null,
                      decoration: const InputDecoration(
                        labelText: 'Education',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _bioController,
                      validator: (value) =>
                          (value?.trim().isEmpty ?? true) ? 'Bio is required' : null,
                      minLines: 3,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Bio',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPMultiSelectField(
                label: 'Skills',
                hint: 'Select 2-4 skills',
                options: DummyData.skillPool,
                values: _skills,
                minSelection: 2,
                maxSelection: 4,
                onChanged: (values) => setState(() => _skills = values),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPSection(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Links',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _portfolioController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Portfolio link',
                        prefixIcon: Icon(Icons.language_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _githubController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'GitHub link',
                        prefixIcon: Icon(Icons.code_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      backgroundColor: AppTheme.primarySoft,
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _resumeFileName ?? 'No CV uploaded',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _resumeUrl == null
                                      ? 'Upload a PDF or image CV.'
                                      : 'Current CV is available to startups.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          XPOutlinedButton(
                            label: _resumeUrl == null ? 'Upload' : 'Replace',
                            expand: false,
                            size: XPButtonSize.small,
                            onPressed: _isSaving ? null : _pickResume,
                          ),
                        ],
                      ),
                    ),
                    if ((_resumeUrl ?? '').isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.md),
                      XPOutlinedButton(
                        label: 'Open CV',
                        icon: Icons.open_in_new_rounded,
                        size: XPButtonSize.small,
                        onPressed: () => _openLink(_resumeUrl),
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
                    Text(
                      'Availability',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text('${_hours.round()} hours per week'),
                    Slider(
                      min: 2,
                      max: 30,
                      divisions: 28,
                      value: _hours,
                      onChanged: (value) => setState(() => _hours = value),
                    ),
                  ],
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
              const SizedBox(height: AppSpacing.xl),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(LegalUrls.privacyPolicy),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        'Privacy Policy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => launchUrl(
                        Uri.parse(LegalUrls.termsConditions),
                        mode: LaunchMode.externalApplication,
                      ),
                      child: Text(
                        'Terms & Conditions',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.textSecondary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
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
