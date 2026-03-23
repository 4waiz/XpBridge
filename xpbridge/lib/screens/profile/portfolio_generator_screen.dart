import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../models/application.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_premium.dart';

class PortfolioGeneratorScreen extends StatelessWidget {
  const PortfolioGeneratorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final profile = appState.studentProfile;
    final applications = profile != null
        ? appState.getApplicationsForStudent(profile.id)
        : <Application>[];

    final completedMissions = applications
        .where((app) =>
            app.status == ApplicationStatus.completed ||
            app.completedAt != null)
        .toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPScene(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              XPAppBar(
                title: 'Portfolio Generator',
                subtitle: 'Your verified Proof of Work',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.page),
                  child: Column(
                    children: [
                      _buildHeader(context, profile),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSummary(context, completedMissions),
                      const SizedBox(height: AppSpacing.xl),
                      _buildVerifiedMissions(context, completedMissions),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSkillMatrix(context, profile, completedMissions),
                      const SizedBox(height: AppSpacing.xxl),
                      XPButton(
                        label: 'Generate Public Link',
                        icon: Icons.link_rounded,
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Public portfolio link copied to clipboard!'),
                            ),
                          );
                        },
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

  Widget _buildHeader(BuildContext context, dynamic profile) {
    return XPGlassPanel(
      padding: const EdgeInsets.all(AppSpacing.xl),
      backgroundColor: AppTheme.primaryDeep.withValues(alpha: 0.9),
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.surface.withValues(alpha: 0.2),
            child: Text(
              profile?.name != null && profile!.name.isNotEmpty ? profile!.name[0] : '?',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppTheme.surface,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            profile?.name ?? 'Student',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppTheme.surface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Verified XPBridge Talent',
            style: TextStyle(
              color: AppTheme.surface.withValues(alpha: 0.8),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary(BuildContext context, List<Application> missions) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Missions',
            value: '${missions.length}',
            icon: Icons.assignment_turned_in_rounded,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _StatCard(
            label: 'Feedback',
            value: '${missions.where((m) => m.mentorRating != null).length}',
            icon: Icons.reviews_rounded,
          ),
        ),
      ],
    );
  }

  Widget _buildVerifiedMissions(BuildContext context, List<Application> missions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Verified Proof of Work',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        if (missions.isEmpty)
          const XPCard(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text('No completed missions yet. Build your proof!'),
              ),
            ),
          )
        else
          ...missions.map((mission) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: XPCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppTheme.success.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.verified_rounded,
                      color: AppTheme.successDark,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mission.roleTitle ?? 'Mission',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          mission.startupName,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppTheme.textMuted),
                ],
              ),
            ),
          )),
      ],
    );
  }

  Widget _buildSkillMatrix(BuildContext context, dynamic profile, List<Application> missions) {
    final allEndorsedSkills = missions.expand((m) => m.endorsedSkills).toSet();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Endorsed Skills',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: AppSpacing.md),
        if (allEndorsedSkills.isEmpty)
          const Text('No endorsed skills yet. Complete missions to earn them.', style: TextStyle(color: AppTheme.textSecondary))
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: allEndorsedSkills.map((skill) => XPSkillTag(
              label: skill,
              isMatched: true,
            )).toList(),
          ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.icon});
  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return XPCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.primary, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
