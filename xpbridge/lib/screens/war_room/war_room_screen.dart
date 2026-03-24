import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../app.dart';
import '../../models/application.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_premium.dart';
import '../../widgets/xp_section_title.dart';

class WarRoomScreen extends StatefulWidget {
  const WarRoomScreen({super.key, required this.applicationId});

  final String applicationId;

  @override
  State<WarRoomScreen> createState() => _WarRoomScreenState();
}

class _WarRoomScreenState extends State<WarRoomScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final application = appState.getApplicationById(widget.applicationId);

    if (application == null) {
      return const Scaffold(body: Center(child: Text('Mission not found')));
    }

    final isStudent = appState.isStudent;
    final otherPartyName = isStudent ? application.startupName : application.studentName;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPScene(
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.page),
                child: Column(
                  children: [
                    XPDashboardAppBar(
                      eyebrow: 'Collaborative War Room',
                      title: otherPartyName,
                      subtitle: application.roleTitle ?? 'Active Mission',
                      leading: IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => context.pop(),
                      ),
                      trailing: XPHeaderButton(
                        icon: Icons.info_outline_rounded,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _MissionStatusBar(status: application.status),
                    const SizedBox(height: AppSpacing.lg),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primary,
                      unselectedLabelColor: AppTheme.textSecondary,
                      indicatorColor: AppTheme.primary,
                      dividerColor: Colors.transparent,
                      tabs: const [
                        Tab(text: 'Workspace'),
                        Tab(text: 'Files'),
                        Tab(text: 'Tasks'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _WorkspaceTab(applicationId: widget.applicationId),
                  _FilesTab(applicationId: widget.applicationId),
                  _TasksTab(applicationId: widget.applicationId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MissionStatusBar extends StatelessWidget {
  const _MissionStatusBar({required this.status});
  final ApplicationStatus status;

  @override
  Widget build(BuildContext context) {
    final stages = ['Applied', 'Interview', 'Hired', 'Complete'];
    int currentStage = 0;
    if (status == ApplicationStatus.interviewing) currentStage = 1;
    if (status == ApplicationStatus.hired || status == ApplicationStatus.accepted) currentStage = 2;
    if (status == ApplicationStatus.completed) currentStage = 3;

    return XPGlassPanel(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md, horizontal: AppSpacing.lg),
      backgroundColor: AppTheme.surface.withValues(alpha: 0.12),
      borderColor: AppTheme.surface.withValues(alpha: 0.16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: List.generate(stages.length, (index) {
          final isActive = index <= currentStage;
          return Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: isActive ? AppTheme.primary : Colors.white24,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Icon(
                        index < currentStage ? Icons.check : Icons.circle,
                        size: 12,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stages[index],
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: isActive ? AppTheme.surface : Colors.white38,
                        ),
                  ),
                ],
              ),
              if (index < stages.length - 1)
                Container(
                  width: 30,
                  height: 1,
                  margin: const EdgeInsets.only(bottom: 14),
                  color: index < currentStage ? AppTheme.primary : Colors.white12,
                ),
            ],
          );
        }),
      ),
    );
  }
}

class _WorkspaceTab extends StatelessWidget {
  const _WorkspaceTab({required this.applicationId});
  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.page),
            reverse: true,
            children: [
              _SystemEventCard(
                text: 'Student shared "Updated Proposal.pdf"',
                icon: Icons.file_present_rounded,
                timestamp: '11:45 AM',
              ),
              _ChatBubble(
                message: 'Looking forward to shipping this week!',
                isMe: true,
                timestamp: '11:42 AM',
              ),
              _ChatBubble(
                message: 'Thanks for the quick turnaround on the brief.',
                isMe: false,
                timestamp: '10:15 AM',
              ),
              _SystemEventCard(
                text: 'Mission stage updated to "Hired"',
                icon: Icons.celebration_rounded,
                timestamp: 'Yesterday',
              ),
            ],
          ).animate().fadeIn(),
        ),
        _buildMessageInput(context),
      ],
    );
  }

  Widget _buildMessageInput(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.page,
        AppSpacing.md,
        AppSpacing.page,
        MediaQuery.of(context).padding.bottom + AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface.withValues(alpha: 0.9),
      ),
      child: Row(
        children: [
          Expanded(
            child: XPTextField(
              hintText: 'Share an update...',
              prefixIcon: Icons.add_circle_outline_rounded,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          XPHeaderButton(
            icon: Icons.send_rounded,
            backgroundColor: AppTheme.primary,
            foregroundColor: Colors.white,
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class _FilesTab extends StatelessWidget {
  const _FilesTab({required this.applicationId});
  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        XPSectionTitle(title: 'Mission Assets', subtitle: 'All files shared in one place'),
        const SizedBox(height: AppSpacing.md),
        _FileCard(name: 'Brand Guidelines.pdf', size: '2.4 MB', type: 'PDF'),
        _FileCard(name: 'Homepage Draft.fig', size: '12.1 MB', type: 'Figma'),
        _FileCard(name: 'Mission Brief.docx', size: '45 KB', type: 'DOCX'),
      ],
    );
  }
}

class _TasksTab extends StatelessWidget {
  const _TasksTab({required this.applicationId});
  final String applicationId;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.page),
      children: [
        XPSectionTitle(title: 'Collaborative Checklist', subtitle: 'Shared action items'),
        const SizedBox(height: AppSpacing.md),
        _TaskItem(title: 'Define core persona', isDone: true),
        _TaskItem(title: 'Sketch homepage wireframes', isDone: true),
        _TaskItem(title: 'Deliver high-fidelity UI', isDone: false),
        _TaskItem(title: 'Final review and handoff', isDone: false),
      ],
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message, required this.isMe, required this.timestamp});
  final String message;
  final bool isMe;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primary : AppTheme.cardBackground,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              message,
              style: TextStyle(color: isMe ? Colors.white : AppTheme.text),
            ),
            const SizedBox(height: 4),
            Text(
              timestamp,
              style: TextStyle(
                fontSize: 10,
                color: isMe ? Colors.white70 : AppTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SystemEventCard extends StatelessWidget {
  const _SystemEventCard({required this.text, required this.icon, required this.timestamp});
  final String text;
  final IconData icon;
  final String timestamp;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: AppTheme.textSecondary),
            const SizedBox(width: 8),
            Text(
              '$text · $timestamp',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileCard extends StatelessWidget {
  const _FileCard({required this.name, required this.size, required this.type});
  final String name;
  final String size;
  final String type;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: XPGlassPanel(
        padding: const EdgeInsets.all(12),
        backgroundColor: Colors.white60,
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppTheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.file_copy_rounded, color: AppTheme.primary),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text('$type · $size', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            IconButton(icon: const Icon(Icons.download_rounded), onPressed: () {}),
          ],
        ),
      ),
    );
  }
}

class _TaskItem extends StatelessWidget {
  const _TaskItem({required this.title, required this.isDone});
  final String title;
  final bool isDone;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Checkbox(
            value: isDone,
            activeColor: AppTheme.primary,
            onChanged: (v) {},
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
          Text(
            title,
            style: TextStyle(
              decoration: isDone ? TextDecoration.lineThrough : null,
              color: isDone ? AppTheme.textSecondary : AppTheme.text,
            ),
          ),
        ],
      ),
    );
  }
}

extension on Widget {
  Widget animate() => this;
}

extension on Widget {
  Widget fadeIn() => this;
}
