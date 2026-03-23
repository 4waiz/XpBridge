import 'package:flutter/material.dart';

import '../../app.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_mission_widgets.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_premium.dart';

class GuildDetailScreen extends StatelessWidget {
  const GuildDetailScreen({super.key, required this.guildId});

  final String guildId;

  String _inviteCode(String guildId) =>
      guildId.toUpperCase().replaceAll('_', '-');

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final guild = appState.getGuildById(guildId);
    final currentStudent = appState.studentProfile;

    if (guild == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: XPScene(
          compact: true,
          child: SafeArea(
            child: Column(
              children: const [
                XPAppBar(title: 'Guild'),
                Expanded(child: Center(child: Text('Guild not found'))),
              ],
            ),
          ),
        ),
      );
    }

    final members = appState.getGuildMembers(guild.id);
    final applications = appState.getGuildApplicationsForGuild(guild.id);
    final isMember =
        currentStudent != null && guild.memberIds.contains(currentStudent.id);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPScene(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              XPAppBar(title: guild.name, subtitle: 'Guild detail'),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    140,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GuildPreviewCard(
                        guild: guild,
                        members: members,
                        activeMissions:
                            appState.getActiveGuildMissionCount(guild.id),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      XPSection(
                        title: 'Invite',
                        subtitle:
                            'Share this code with a teammate for the local MVP flow.',
                        child: XPBadge(
                          label: _inviteCode(guild.id),
                          icon: Icons.qr_code_rounded,
                          color: AppTheme.primarySoft,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      XPSection(
                        title: 'Members',
                        subtitle:
                            'Complementary skill mix across product, design, and execution.',
                        child: Column(
                          children: members.map((member) {
                            return Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.md,
                              ),
                              child: XPCard(
                                backgroundColor:
                                    AppTheme.surface.withValues(alpha: 0.56),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            member.name,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleMedium,
                                          ),
                                        ),
                                        XPBadge(
                                          label:
                                              '${member.availabilityHours.round()} h/w',
                                          icon: Icons.schedule_rounded,
                                        ),
                                      ],
                                    ),
                                    if (member.education?.isNotEmpty == true) ...[
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        member.education!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                    const SizedBox(height: AppSpacing.sm),
                                    Wrap(
                                      spacing: AppSpacing.sm,
                                      runSpacing: AppSpacing.sm,
                                      children: member.skills
                                          .take(5)
                                          .map(
                                            (skill) => XPSkillTag(
                                              label: skill,
                                              isMatched:
                                                  guild.skillTags.contains(skill),
                                            ),
                                          )
                                          .toList(),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      if (applications.isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        XPSection(
                          title: 'Team mission pipeline',
                          subtitle:
                              'Current and previous guild applications in one place.',
                          child: Column(
                            children: applications.map((application) {
                              return Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.md,
                                ),
                                child: XPCard(
                                  backgroundColor:
                                      AppTheme.surface.withValues(alpha: 0.56),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        application.missionTitle,
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium,
                                      ),
                                      const SizedBox(height: AppSpacing.xxs),
                                      Text(
                                        application.startupName,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      Text(
                                        application.message,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                      const SizedBox(height: AppSpacing.sm),
                                      XPBadge(
                                        label: application.status.name
                                            .replaceAll('_', ' ')
                                            .toUpperCase(),
                                        icon: Icons.flag_outlined,
                                        color: AppTheme.primarySoft,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: currentStudent == null
          ? null
          : XPBottomActionBar(
              child: XPButton(
                label: isMember ? 'Leave guild' : 'Join guild',
                icon: isMember
                    ? Icons.exit_to_app_rounded
                    : Icons.group_add_outlined,
                onPressed: () async {
                  if (isMember) {
                    await appState.leaveGuild(guild.id, currentStudent.id);
                  } else {
                    await appState.joinGuild(guild.id, currentStudent.id);
                  }
                  if (context.mounted) {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ),
    );
  }
}
