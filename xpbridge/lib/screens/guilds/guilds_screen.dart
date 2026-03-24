import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../services/guild_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/team_mission_widgets.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_premium.dart';
import '../../widgets/xp_section_title.dart';

class GuildsScreen extends StatelessWidget {
  const GuildsScreen({super.key});

  void _showCreateGuildSheet(BuildContext context, AppState appState) {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final selectedSkills = <String>{};
    final currentStudent = appState.studentProfile;
    if (currentStudent == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return XPPremiumSheet(
              title: 'Create a guild',
              subtitle:
                  'Build a small cross-functional team for larger startup missions.',
              footer: XPButton(
                label: 'Create guild',
                icon: Icons.groups_rounded,
                onPressed: () async {
                  final guild = await appState.createGuild(
                    name: nameController.text.trim(),
                    description: descriptionController.text.trim(),
                    skillTags: selectedSkills.toList(),
                  );
                  if (!ctx.mounted || guild == null) return;
                  Navigator.pop(ctx);
                  context.pushNamed(
                    'guildDetail',
                    pathParameters: {'id': guild.id},
                  );
                },
              ),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    XPTextField(
                      controller: nameController,
                      labelText: 'Guild name',
                      hintText: 'e.g. Launch Loop',
                      prefixIcon: Icons.auto_awesome_rounded,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPTextField(
                      controller: descriptionController,
                      labelText: 'What does this guild do well?',
                      hintText:
                          'Describe the mix of roles, working style, and mission focus.',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 4,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Skill mix',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      children:
                          {...currentStudent.skills, ...GuildService.teamRolePool}
                              .map(
                                (skill) => XPChoiceChip(
                                  label: skill,
                                  selected: selectedSkills.contains(skill),
                                  onSelected: (selected) {
                                    setModalState(() {
                                      if (selected) {
                                        selectedSkills.add(skill);
                                      } else {
                                        selectedSkills.remove(skill);
                                      }
                                    });
                                  },
                                ),
                              )
                              .toList(),
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

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final student = appState.studentProfile;

    if (student == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: XPScene(
          compact: true,
          child: SafeArea(
            child: Column(
              children: const [
                XPAppBar(title: 'Guilds'),
                Expanded(
                  child: Center(
                    child: Text('Complete your student profile first.'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final currentGuild = appState.getGuildForStudent(student.id);
    final guilds = appState.guilds;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPScene(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              XPAppBar(
                title: 'Guilds',
                subtitle: 'Build with complementary teammates',
                trailing: XPHeaderButton(
                  icon: Icons.add_rounded,
                  foregroundColor: AppTheme.primaryDeep,
                  backgroundColor: AppTheme.surface.withValues(alpha: 0.72),
                  onTap: () => _showCreateGuildSheet(context, appState),
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    120,
                  ),
                  children: [
                    if (currentGuild != null) ...[
                      const XPSectionTitle(
                        title: 'Your guild',
                        subtitle:
                            'Shared collaboration XP and active team mission work.',
                      ),
                      const SizedBox(height: AppSpacing.md),
                      GuildPreviewCard(
                        guild: currentGuild,
                        members: appState.getGuildMembers(currentGuild.id),
                        activeMissions:
                            appState.getActiveGuildMissionCount(currentGuild.id),
                        onTap: () => context.pushNamed(
                          'guildDetail',
                          pathParameters: {'id': currentGuild.id},
                        ),
                        footer: Row(
                          children: [
                            Expanded(
                              child: XPOutlinedButton(
                                label: 'Open guild',
                                icon: Icons.visibility_outlined,
                                size: XPButtonSize.medium,
                                onPressed: () => context.pushNamed(
                                  'guildDetail',
                                  pathParameters: {'id': currentGuild.id},
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: XPButton(
                                label: 'Leave guild',
                                icon: Icons.exit_to_app_rounded,
                                size: XPButtonSize.medium,
                                onPressed: () async {
                                  await appState.leaveGuild(
                                    currentGuild.id,
                                    student.id,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                    ],
                    XPSection(
                      title: 'How guilds work',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          _InfoRow(
                            icon: Icons.groups_rounded,
                            label: 'Create or join a small team',
                          ),
                          _InfoRow(
                            icon: Icons.badge_outlined,
                            label: 'Apply to team missions with a clear role mix',
                          ),
                          _InfoRow(
                            icon: Icons.handshake_outlined,
                            label: 'Earn shared collaboration XP and visible completions',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    const XPSectionTitle(
                      title: 'Browse guilds',
                      subtitle:
                          'Join a team with complementary skills or start a new one.',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...guilds.map((guild) {
                      final isCurrent = currentGuild?.id == guild.id;
                      final members = appState.getGuildMembers(guild.id);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                        child: GuildPreviewCard(
                          guild: guild,
                          members: members,
                          activeMissions:
                              appState.getActiveGuildMissionCount(guild.id),
                          onTap: () => context.pushNamed(
                            'guildDetail',
                            pathParameters: {'id': guild.id},
                          ),
                          footer: Row(
                            children: [
                              Expanded(
                                child: XPOutlinedButton(
                                  label: 'View details',
                                  icon: Icons.visibility_outlined,
                                  size: XPButtonSize.medium,
                                  onPressed: () => context.pushNamed(
                                    'guildDetail',
                                    pathParameters: {'id': guild.id},
                                  ),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: XPButton(
                                  label: isCurrent
                                      ? 'Joined'
                                      : currentGuild == null
                                          ? 'Join guild'
                                          : 'Switch guild',
                                  icon: isCurrent
                                      ? Icons.check_circle_rounded
                                      : Icons.group_add_outlined,
                                  size: XPButtonSize.medium,
                                  onPressed: isCurrent
                                      ? null
                                      : () async {
                                          await appState.joinGuild(
                                            guild.id,
                                            student.id,
                                          );
                                        },
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGlowGradient,
              borderRadius: BorderRadius.circular(AppTheme.cornerRadiusSmall),
            ),
            child: Icon(icon, color: AppTheme.surface, size: 18),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
