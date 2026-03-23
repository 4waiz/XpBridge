import 'package:flutter/material.dart';

import '../models/skill_badge.dart';
import '../theme/app_theme.dart';
import 'xp_card.dart';

class VerifiedBadgesSection extends StatelessWidget {
  const VerifiedBadgesSection({
    super.key,
    required this.badges,
    this.title = 'Verified Badges',
    this.subtitle =
        'Blockchain-ready milestone credentials issued as non-transferable proof.',
  });

  final List<SkillBadge> badges;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return XPSection(
      title: title,
      subtitle: subtitle,
      child: badges.isEmpty
          ? Text(
              'No verified badges yet. Milestone credentials appear here as you level up, complete missions, and earn high-trust endorsements.',
              style: Theme.of(context).textTheme.bodySmall,
            )
          : Column(
              children: badges.map((badge) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: _BadgeCard(badge: badge),
                );
              }).toList(),
            ),
    );
  }
}

class VerifiedBadgeStrip extends StatelessWidget {
  const VerifiedBadgeStrip({super.key, required this.badges});

  final List<SkillBadge> badges;

  @override
  Widget build(BuildContext context) {
    if (badges.isEmpty) {
      return Text(
        'No verified badges yet',
        style: Theme.of(context).textTheme.bodySmall,
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: badges.take(4).map((badge) {
          return Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: XPBadge(
              label: badge.title,
              icon: Icons.verified_rounded,
              color: _statusColor(badge.verificationStatus),
              textColor: badge.verificationStatus ==
                      SkillBadgeVerificationStatus.blockchainReady
                  ? AppTheme.primaryDeep
                  : AppTheme.surface,
            ),
          );
        }).toList(),
      ),
    );
  }

  Color _statusColor(SkillBadgeVerificationStatus status) {
    switch (status) {
      case SkillBadgeVerificationStatus.verified:
        return AppTheme.primaryDeep;
      case SkillBadgeVerificationStatus.pending:
        return AppTheme.surface.withValues(alpha: 0.78);
      case SkillBadgeVerificationStatus.blockchainReady:
        return AppTheme.primarySoft;
    }
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({required this.badge});

  final SkillBadge badge;

  String _dateLabel(DateTime date) =>
      '${date.month}/${date.day}/${date.year}';

  String _statusLabel(SkillBadgeVerificationStatus status) {
    switch (status) {
      case SkillBadgeVerificationStatus.verified:
        return 'Verified';
      case SkillBadgeVerificationStatus.pending:
        return 'Pending';
      case SkillBadgeVerificationStatus.blockchainReady:
        return 'Blockchain-ready';
    }
  }

  Color _statusColor(SkillBadgeVerificationStatus status) {
    switch (status) {
      case SkillBadgeVerificationStatus.verified:
        return AppTheme.primaryDeep;
      case SkillBadgeVerificationStatus.pending:
        return AppTheme.warning;
      case SkillBadgeVerificationStatus.blockchainReady:
        return AppTheme.primarySoft;
    }
  }

  Color _statusTextColor(SkillBadgeVerificationStatus status) {
    switch (status) {
      case SkillBadgeVerificationStatus.blockchainReady:
        return AppTheme.primaryDeep;
      case SkillBadgeVerificationStatus.pending:
        return AppTheme.text;
      case SkillBadgeVerificationStatus.verified:
        return AppTheme.surface;
    }
  }

  @override
  Widget build(BuildContext context) {
    return XPCard(
      backgroundColor: AppTheme.surface.withValues(alpha: 0.58),
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
                      badge.title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      badge.description,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              XPBadge(
                label: _statusLabel(badge.verificationStatus),
                icon: Icons.verified_outlined,
                color: _statusColor(badge.verificationStatus),
                textColor: _statusTextColor(badge.verificationStatus),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              XPBadge(
                label: 'Issued ${_dateLabel(badge.issuedAt)}',
                icon: Icons.schedule_rounded,
              ),
              XPBadge(
                label: badge.earnedFrom,
                icon: Icons.workspace_premium_outlined,
                color: AppTheme.primarySoft,
              ),
              XPBadge(
                label: badge.isTransferable
                    ? 'Transferable'
                    : 'Non-transferable',
                icon: Icons.lock_outline_rounded,
                color: AppTheme.surface.withValues(alpha: 0.72),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Ref ${badge.tokenIdOrReference}',
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
