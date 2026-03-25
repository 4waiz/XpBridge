import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/student_profile.dart';
import '../../services/asset_upload_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_page_scaffold.dart';
import '../../widgets/xp_selectors.dart';

class StudentSetupScreen extends StatefulWidget {
  const StudentSetupScreen({super.key});

  @override
  State<StudentSetupScreen> createState() => _StudentSetupScreenState();
}

class _StudentSetupScreenState extends State<StudentSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _educationController = TextEditingController();
  final _portfolioController = TextEditingController();
  final _githubController = TextEditingController();
  List<String> _skills = [];
  double _hours = 10;
  bool _isSaving = false;
  String? _resumeUrl;
  String? _resumeFileName;
  String? _resumeMimeType;
  String? _submitError;
  bool _loaded = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loaded) return;
    final profile = AppStateScope.of(context).studentProfile;
    if (profile != null) {
      _nameController.text = profile.name;
      _bioController.text = profile.bio ?? '';
      _educationController.text = profile.education ?? '';
      _portfolioController.text = profile.portfolioUrl ?? '';
      _githubController.text = profile.githubUrl ?? '';
      _skills = List<String>.from(profile.skills);
      _hours = profile.availabilityHours;
      _resumeUrl = profile.resumeUrl;
      _resumeFileName = profile.resumeFileName;
      _resumeMimeType = profile.resumeMimeType;
    }
    _loaded = true;
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
    try {
      final user = SupabaseService.currentUser;
      if (user == null) {
        throw const XpServiceException('Please log in again.');
      }
      final picked = await AssetUploadService.pickResume();
      if (picked == null) return;
      setState(() => _isSaving = true);
      final url = await AssetUploadService.uploadResume(user.id, picked);
      setState(() {
        _resumeUrl = url;
        _resumeFileName = picked.fileName;
        _resumeMimeType = picked.mimeType;
        _submitError = null;
      });
    } on XpServiceException catch (error) {
      setState(() => _submitError = error.message);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  String? _validateRequired(String? value, String label) {
    if ((value?.trim() ?? '').isEmpty) {
      return '$label is required';
    }
    return null;
  }

  Future<void> _saveProfile() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_skills.length < 2 || _skills.length > 4) {
      setState(() => _submitError = 'Select between 2 and 4 skills.');
      return;
    }
    if ((_resumeUrl ?? '').isEmpty) {
      setState(() => _submitError = 'Upload your CV as a PDF or image.');
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

    final profile = StudentProfile(
      id: user.id,
      name: _nameController.text.trim(),
      email: user.email ?? '',
      bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
      education: _educationController.text.trim().isEmpty
          ? null
          : _educationController.text.trim(),
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
      createdAt: DateTime.now(),
    );

    try {
      final appState = AppStateScope.of(context);
      await appState.persistStudentProfile(profile);
      if (!mounted) return;
      context.goNamed('studentDashboard');
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
      title: 'Build your profile',
      subtitle: 'Students must provide a CV, a few real skills, and at least one work link.',
      showBack: true,
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
                      controller: _nameController,
                      validator: (value) => _validateRequired(value, 'Full name'),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Full name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _educationController,
                      validator: (value) => _validateRequired(value, 'Education'),
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Education',
                        hintText: 'e.g. BSc Computer Science',
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _bioController,
                      minLines: 3,
                      maxLines: 4,
                      validator: (value) => _validateRequired(value, 'Bio'),
                      decoration: const InputDecoration(
                        labelText: 'Short bio',
                        hintText: 'What can a founder trust you with right now?',
                        prefixIcon: Icon(Icons.edit_note_rounded),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              XPMultiSelectField(
                label: 'Core skills',
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
                      'Links and proof',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _portfolioController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'Portfolio link',
                        hintText: 'https://yourportfolio.com',
                        prefixIcon: Icon(Icons.language_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: _githubController,
                      keyboardType: TextInputType.url,
                      decoration: const InputDecoration(
                        labelText: 'GitHub link',
                        hintText: 'https://github.com/username',
                        prefixIcon: Icon(Icons.code_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPCard(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      backgroundColor: AppTheme.primarySoft,
                      child: Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.description_outlined,
                              color: AppTheme.primaryDeep,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _resumeFileName ?? 'Upload your CV',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                Text(
                                  _resumeUrl == null
                                      ? 'Required. PDF or image files only.'
                                      : _resumeMimeType == 'application/pdf'
                                          ? 'PDF uploaded'
                                          : 'Image resume uploaded',
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
                    Text(
                      '${_hours.round()} hours per week',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Slider(
                      min: 2,
                      max: 30,
                      divisions: 28,
                      value: _hours,
                      label: '${_hours.round()} hrs',
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
            ],
          ),
        ),
      ),
    );
  }
}
