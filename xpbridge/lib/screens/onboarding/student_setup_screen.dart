import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../app.dart';
import '../../data/dummy_data.dart';
import '../../models/student_profile.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_section_title.dart';

class StudentSetupScreen extends StatefulWidget {
  const StudentSetupScreen({super.key});

  @override
  State<StudentSetupScreen> createState() => _StudentSetupScreenState();
}

class _StudentSetupScreenState extends State<StudentSetupScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _educationController = TextEditingController();
  final _portfolioController = TextEditingController();
  final Set<String> _skills = {};
  double _hours = 10;

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _educationController.dispose();
    _portfolioController.dispose();
    super.dispose();
  }

  bool get _canContinue =>
      _nameController.text.trim().isNotEmpty && _skills.length >= 2;

  Future<void> _saveProfile() async {
    if (!_canContinue) return;

    final appState = AppStateScope.of(context);
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString('user_email') ?? '';

    final profile = StudentProfile(
      id: 'user_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text,
      email: email,
      bio: _bioController.text.isNotEmpty ? _bioController.text : null,
      education: _educationController.text.isNotEmpty
          ? _educationController.text
          : null,
      skills: _skills.toList(),
      availabilityHours: _hours,
      portfolioUrl: _portfolioController.text.isNotEmpty
          ? _portfolioController.text
          : null,
      createdAt: DateTime.now(),
      xpPoints: 0,
      level: 1,
      missionsCompletedCount: 0,
    );

    await prefs.setString('profile_name', _nameController.text);
    await prefs.setString('profile_id', profile.id);
    await prefs.setString('profile_bio', _bioController.text);
    await prefs.setString('profile_education', _educationController.text);
    await prefs.setStringList('profile_skills', _skills.toList());
    await prefs.setDouble('profile_hours', _hours);
    await prefs.setBool('is_logged_in', true);

    if (!mounted) return;
    appState.saveStudentProfile(profile);
    context.goNamed('studentDashboard');
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
                          'Build your profile',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          'Help startups understand what you can do and how much time you can commit.',
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
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const XPSectionTitle(
                            title: 'Basic info',
                            subtitle: 'Keep it concise and useful.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          XPTextField(
                            controller: _nameController,
                            labelText: 'Full name',
                            hintText: 'Enter your name',
                            prefixIcon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPTextField(
                            controller: _educationController,
                            labelText: 'Education',
                            hintText: 'e.g. BSc Computer Science',
                            prefixIcon: Icons.school_outlined,
                            textCapitalization: TextCapitalization.words,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPTextField(
                            controller: _bioController,
                            labelText: 'Bio',
                            hintText: 'What should startups know about you?',
                            prefixIcon: Icons.edit_note_rounded,
                            maxLines: 4,
                            textCapitalization: TextCapitalization.sentences,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          XPTextField(
                            controller: _portfolioController,
                            labelText: 'Portfolio URL',
                            hintText: 'https://yourportfolio.com',
                            prefixIcon: Icons.link_rounded,
                            keyboardType: TextInputType.url,
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
                            title: 'Skills',
                            subtitle:
                                'Select between 2 and 4 areas you want to be matched on.',
                            actionLabel: '${_skills.length}/4',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Wrap(
                            spacing: AppSpacing.sm,
                            runSpacing: AppSpacing.sm,
                            children: DummyData.skillPool.map((skill) {
                              return XPChoiceChip(
                                label: skill,
                                selected: _skills.contains(skill),
                                onSelected: (selected) {
                                  setState(() {
                                    if (selected) {
                                      if (_skills.length < 4) {
                                        _skills.add(skill);
                                      }
                                    } else {
                                      _skills.remove(skill);
                                    }
                                  });
                                },
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
                          const XPSectionTitle(
                            title: 'Availability',
                            subtitle:
                                'Let startups know how much time you can give each week.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          XPCard(
                            padding: const EdgeInsets.all(AppSpacing.lg),
                            backgroundColor: AppTheme.cardBackground,
                            radius: AppTheme.cornerRadius,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_hours.round()} hours / week',
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Slider(
                                  min: 2,
                                  max: 25,
                                  divisions: 23,
                                  value: _hours,
                                  label: '${_hours.round()} hrs',
                                  onChanged: (value) =>
                                      setState(() => _hours = value),
                                ),
                              ],
                            ),
                          ),
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
