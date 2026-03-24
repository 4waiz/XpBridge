import 'package:flutter/material.dart';

import '../models/guild.dart';
import '../models/student_profile.dart';
import '../models/team_mission_config.dart';
import '../theme/app_theme.dart';
import 'xp_button.dart';
import 'xp_card.dart';
import 'xp_chip.dart';

class TeamMissionBadge extends StatelessWidget {
  const TeamMissionBadge({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return XPBadge(
      label: compact ? 'Team Mission' : 'Team Mission',
      icon: Icons.groups_rounded,
      color: AppTheme.primaryDeep,
      textColor: AppTheme.surface,
    );
  }
}

class TeamMissionHighlights extends StatelessWidget {
  const TeamMissionHighlights({
    super.key,
    required this.config,
    this.showOutcome = true,
  });

  final TeamMissionConfig config;
  final bool showOutcome;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            XPBadge(
              label: '${config.teamSizeMin}-${config.maxMembers} members',
              icon: Icons.group_outlined,
              color: AppTheme.primarySoft,
            ),
            ...config.requiredRoles.map(
              (role) => XPBadge(
                label: role,
                icon: Icons.work_outline_rounded,
                color: AppTheme.surface.withValues(alpha: 0.72),
              ),
            ),
          ],
        ),
        if (showOutcome) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            config.sharedLearningOutcome,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ],
    );
  }
}

class TeamMissionSummaryCard extends StatelessWidget {
  const TeamMissionSummaryCard({
    super.key,
    required this.company,
    required this.title,
    required this.description,
    required this.config,
    required this.onTap,
    this.ctaLabel = 'View mission',
  });

  final String company;
  final String title;
  final String description;
  final TeamMissionConfig config;
  final VoidCallback onTap;
  final String ctaLabel;

  @override
  Widget build(BuildContext context) {
    return XPCard(
      onTap: onTap,
      padding: const EdgeInsets.all(AppSpacing.lg),
      backgroundColor: AppTheme.surface.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TeamMissionBadge(compact: true),
              const Spacer(),
              XPBadge(
                label: '${config.requiredRoles.length} roles',
                color: AppTheme.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(company, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: AppSpacing.md),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          TeamMissionHighlights(config: config),
          const SizedBox(height: AppSpacing.md),
          XPOutlinedButton(
            label: ctaLabel,
            icon: Icons.arrow_forward_rounded,
            size: XPButtonSize.small,
            onPressed: onTap,
          ),
        ],
      ),
    );
  }
}

class GuildPreviewCard extends StatelessWidget {
  const GuildPreviewCard({
    super.key,
    required this.guild,
    required this.members,
    required this.activeMissions,
    this.onTap,
    this.footer,
  });

  final Guild guild;
  final List<StudentProfile> members;
  final int activeMissions;
  final VoidCallback? onTap;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    final roleMix = members
        .expand((member) => member.skills)
        .where(
          (skill) =>
              const ['Flutter', 'React', 'UI/UX Design', 'Product Management',
                  'Copywriting', 'Data Analysis', 'Python']
                  .contains(skill),
        )
        .take(4)
        .toList();

    return XPCard(
      onTap: onTap,
      backgroundColor: AppTheme.surface.withValues(alpha: 0.72),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      guild.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      guild.description,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              XPBadge(
                label: '${guild.collaborationXp} XP',
                icon: Icons.handshake_outlined,
                color: AppTheme.primarySoft,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              XPBadge(
                label: '${members.length} members',
                icon: Icons.people_outline_rounded,
              ),
              XPBadge(
                label: '$activeMissions active',
                icon: Icons.rocket_launch_outlined,
              ),
              XPBadge(
                label: '${guild.completedTeamMissionsCount} completed',
                icon: Icons.check_circle_outline_rounded,
              ),
            ],
          ),
          if (roleMix.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: roleMix
                  .map((skill) => XPSkillTag(label: skill, isMatched: true))
                  .toList(),
            ),
          ],
          if (members.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: members
                  .take(4)
                  .map(
                    (member) => XPBadge(
                      label: member.name,
                      icon: Icons.person_outline_rounded,
                      color: AppTheme.surface.withValues(alpha: 0.78),
                    ),
                  )
                  .toList(),
            ),
          ],
          if (footer != null) ...[
            const SizedBox(height: AppSpacing.md),
            footer!,
          ],
        ],
      ),
    );
  }
}
