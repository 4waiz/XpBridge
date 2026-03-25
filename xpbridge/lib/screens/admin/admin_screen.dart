import 'package:flutter/material.dart';

import '../../app.dart';
import '../../models/application.dart';
import '../../models/mission.dart';
import '../../models/student_profile.dart';
import '../../models/startup_profile.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_page_scaffold.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  int _tabIndex = 0;

  String _pseudoUuid() {
    final timestamp =
        DateTime.now().microsecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-0000-0000-${timestamp.substring(0, 12)}';
  }

  Future<void> _refresh() => AppStateScope.of(context).refreshSession();

  Future<void> _showProfileEditor({
    StudentProfile? student,
    StartupProfile? startup,
  }) async {
    final isStartup = startup != null;
    final role = ValueNotifier<String>(isStartup ? 'startup' : 'student');
    final nameController = TextEditingController(
      text: startup?.companyName ?? student?.name ?? '',
    );
    final emailController = TextEditingController(
      text: startup?.email ?? student?.email ?? '',
    );
    final descriptionController = TextEditingController(
      text: startup?.description ?? student?.bio ?? '',
    );
    final auxController = TextEditingController(
      text: startup?.industry ?? student?.education ?? '',
    );
    final skillsController = TextEditingController(
      text: (startup?.requiredSkills ?? student?.skills ?? []).join(', '),
    );
    final linkController = TextEditingController(
      text: startup?.websiteUrl ?? student?.portfolioUrl ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(student != null || startup != null ? 'Edit profile' : 'Add profile'),
          content: SizedBox(
            width: 520,
            child: ValueListenableBuilder<String>(
              valueListenable: role,
              builder: (context, currentRole, child) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      DropdownButtonFormField<String>(
                        initialValue: currentRole,
                        decoration: const InputDecoration(labelText: 'Role'),
                        items: const [
                          DropdownMenuItem(value: 'student', child: Text('Student')),
                          DropdownMenuItem(value: 'startup', child: Text('Startup')),
                        ],
                        onChanged: (value) {
                          if (value != null) role.value = value;
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          labelText: currentRole == 'startup'
                              ? 'Company name'
                              : 'Full name',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: emailController,
                        decoration: const InputDecoration(labelText: 'Email'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: descriptionController,
                        minLines: 3,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: currentRole == 'startup'
                              ? 'Description'
                              : 'Bio',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: auxController,
                        decoration: InputDecoration(
                          labelText: currentRole == 'startup'
                              ? 'Industry'
                              : 'Education',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: skillsController,
                        decoration: InputDecoration(
                          labelText: currentRole == 'startup'
                              ? 'Required skills (comma separated)'
                              : 'Skills (comma separated)',
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextField(
                        controller: linkController,
                        decoration: InputDecoration(
                          labelText: currentRole == 'startup'
                              ? 'Website'
                              : 'Portfolio URL',
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final currentRole = role.value;
                final data = <String, dynamic>{
                  'id': startup?.id ?? student?.id ?? _pseudoUuid(),
                  'role': currentRole,
                  'email': emailController.text.trim(),
                  'created_at': (startup?.createdAt ?? student?.createdAt ?? DateTime.now())
                      .toIso8601String(),
                };
                final skills = skillsController.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();
                if (currentRole == 'startup') {
                  data.addAll({
                    'company_name': nameController.text.trim(),
                    'name': nameController.text.trim(),
                    'description': descriptionController.text.trim(),
                    'bio': descriptionController.text.trim(),
                    'industry': auxController.text.trim(),
                    'required_skills': skills,
                    'website_url': linkController.text.trim(),
                  });
                } else {
                  data.addAll({
                    'name': nameController.text.trim(),
                    'bio': descriptionController.text.trim(),
                    'education': auxController.text.trim(),
                    'skills': skills,
                    'portfolio_url': linkController.text.trim(),
                  });
                }
                await SupabaseService.upsertProfileRow(data);
                if (!context.mounted) return;
                Navigator.pop(context);
                await _refresh();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showMissionEditor({Mission? mission}) async {
    final appState = AppStateScope.of(context);
    final startupId = ValueNotifier<String?>(
      mission?.startupId ?? appState.startups.firstOrNull?.id,
    );
    final titleController = TextEditingController(text: mission?.title ?? '');
    final descriptionController = TextEditingController(
      text: mission?.description ?? '',
    );
    final commitmentController = TextEditingController(
      text: mission?.commitment ?? '',
    );
    final skillsController = TextEditingController(
      text: mission?.requiredSkills.join(', ') ?? '',
    );
    final outcomeController = TextEditingController(
      text: mission?.learningOutcome ?? '',
    );
    final statusController = ValueNotifier<String>(mission?.status ?? 'open');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(mission == null ? 'Add mission' : 'Edit mission'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: startupId,
                    builder: (context, currentStartup, child) {
                      return DropdownButtonFormField<String>(
                        initialValue: currentStartup,
                        decoration: const InputDecoration(labelText: 'Startup'),
                        items: appState.startups
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(item.companyName),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => startupId.value = value,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Title'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: descriptionController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: commitmentController,
                    decoration: const InputDecoration(labelText: 'Commitment'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: skillsController,
                    decoration: const InputDecoration(
                      labelText: 'Required skills (comma separated)',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: outcomeController,
                    decoration: const InputDecoration(labelText: 'Learning outcome'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ValueListenableBuilder<String>(
                    valueListenable: statusController,
                    builder: (context, currentStatus, child) {
                      return DropdownButtonFormField<String>(
                        initialValue: currentStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: const [
                          DropdownMenuItem(value: 'open', child: Text('Open')),
                          DropdownMenuItem(value: 'closed', child: Text('Closed')),
                        ],
                        onChanged: (value) {
                          if (value != null) statusController.value = value;
                        },
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final skills = skillsController.text
                    .split(',')
                    .map((value) => value.trim())
                    .where((value) => value.isNotEmpty)
                    .toList();
                await SupabaseService.upsertMissionRow({
                  'id': mission?.id ?? _pseudoUuid(),
                  'startup_id': startupId.value,
                  'title': titleController.text.trim(),
                  'description': descriptionController.text.trim(),
                  'commitment': commitmentController.text.trim(),
                  'required_skills': skills,
                  'learning_outcome': outcomeController.text.trim(),
                  'status': statusController.value,
                  'created_at':
                      (mission?.createdAt ?? DateTime.now()).toIso8601String(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                await _refresh();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showApplicationEditor({Application? application}) async {
    final appState = AppStateScope.of(context);
    final missionId = ValueNotifier<String?>(
      application?.missionId ?? appState.missions.firstOrNull?.id,
    );
    final studentId = ValueNotifier<String?>(
      application?.studentId ?? appState.students.firstOrNull?.id,
    );
    final status = ValueNotifier<String>(application?.status.name ?? 'pending');
    final noteController = TextEditingController(text: application?.message ?? '');

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(application == null ? 'Add application' : 'Edit application'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ValueListenableBuilder<String?>(
                    valueListenable: studentId,
                    builder: (context, currentStudent, child) {
                      return DropdownButtonFormField<String>(
                        initialValue: currentStudent,
                        decoration: const InputDecoration(labelText: 'Student'),
                        items: appState.students
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => studentId.value = value,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ValueListenableBuilder<String?>(
                    valueListenable: missionId,
                    builder: (context, currentMission, child) {
                      return DropdownButtonFormField<String>(
                        initialValue: currentMission,
                        decoration: const InputDecoration(labelText: 'Mission'),
                        items: appState.missions
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.id,
                                child: Text('${item.startupName} • ${item.title}'),
                              ),
                            )
                            .toList(),
                        onChanged: (value) => missionId.value = value,
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ValueListenableBuilder<String>(
                    valueListenable: status,
                    builder: (context, currentStatus, child) {
                      return DropdownButtonFormField<String>(
                        initialValue: currentStatus,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ApplicationStatus.values
                            .map(
                              (item) => DropdownMenuItem<String>(
                                value: item.name,
                                child: Text(item.name),
                              ),
                            )
                            .toList(),
                        onChanged: (value) {
                          if (value != null) status.value = value;
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: noteController,
                    minLines: 3,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Intro note'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final selectedMission = appState.getMissionById(missionId.value ?? '');
                final selectedStudent = appState.getStudentById(studentId.value ?? '');
                if (selectedMission == null || selectedStudent == null) {
                  return;
                }
                await SupabaseService.upsertApplicationRow({
                  'id': application?.id ?? _pseudoUuid(),
                  'mission_id': selectedMission.id,
                  'student_id': selectedStudent.id,
                  'startup_id': selectedMission.startupId,
                  'student_name': selectedStudent.name,
                  'startup_name': selectedMission.startupName,
                  'role_title': selectedMission.title,
                  'status': status.value,
                  'message': noteController.text.trim(),
                  'applied_at':
                      (application?.appliedAt ?? DateTime.now()).toIso8601String(),
                });
                if (!context.mounted) return;
                Navigator.pop(context);
                await _refresh();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    if (!appState.isAdmin) {
      return const XPPageScaffold(
        title: 'Admin',
        subtitle: 'Restricted',
        showBack: true,
        compact: true,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.page),
            child: XPEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Admin access required',
              message: 'This console is only available to admins.',
            ),
          ),
        ),
      );
    }

    final profileTiles = [
      ...appState.students.map<Widget>(
        (student) => _AdminTile(
          title: student.name,
          subtitle: 'Student • ${student.email}',
          onEdit: () => _showProfileEditor(student: student),
          onDelete: () async {
            await SupabaseService.deleteProfile(student.id);
            if (!mounted) return;
            await _refresh();
          },
        ),
      ),
      ...appState.startups.map<Widget>(
        (startup) => _AdminTile(
          title: startup.companyName,
          subtitle: 'Startup • ${startup.email}',
          onEdit: () => _showProfileEditor(startup: startup),
          onDelete: () async {
            await SupabaseService.deleteProfile(startup.id);
            if (!mounted) return;
            await _refresh();
          },
        ),
      ),
    ];

    final missionTiles = appState.missions
        .map(
          (mission) => _AdminTile(
            title: mission.title,
            subtitle: '${mission.startupName} • ${mission.status}',
            onEdit: () => _showMissionEditor(mission: mission),
            onDelete: () async {
              await SupabaseService.deleteMission(mission.id);
              if (!mounted) return;
              await _refresh();
            },
          ),
        )
        .toList();

    final applicationTiles = appState.applications
        .map(
          (application) => _AdminTile(
            title: application.studentName,
            subtitle:
                '${application.roleTitle ?? 'Application'} • ${application.status.name}',
            onEdit: () => _showApplicationEditor(application: application),
            onDelete: () async {
              await SupabaseService.deleteApplication(application.id);
              if (!mounted) return;
              await _refresh();
            },
          ),
        )
        .toList();

    return XPPageScaffold(
      title: 'Admin console',
      subtitle: 'Profiles, missions, and application records.',
      showBack: true,
      compact: true,
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.page,
            AppSpacing.md,
            AppSpacing.page,
            AppSpacing.page,
          ),
          children: [
            XPSection(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment<int>(value: 0, label: Text('Profiles')),
                      ButtonSegment<int>(value: 1, label: Text('Missions')),
                      ButtonSegment<int>(value: 2, label: Text('Applications')),
                    ],
                    selected: {_tabIndex},
                    onSelectionChanged: (selection) {
                      setState(() => _tabIndex = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  XPButton(
                    label: _tabIndex == 0
                        ? 'Add profile'
                        : _tabIndex == 1
                            ? 'Add mission'
                            : 'Add application',
                    icon: Icons.add_rounded,
                    onPressed: () {
                      if (_tabIndex == 0) {
                        _showProfileEditor();
                      } else if (_tabIndex == 1) {
                        _showMissionEditor();
                      } else {
                        _showApplicationEditor();
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_tabIndex == 0)
              _AdminList(children: profileTiles)
            else if (_tabIndex == 1)
              _AdminList(children: missionTiles)
            else
              _AdminList(children: applicationTiles),
          ],
        ),
      ),
    );
  }
}

class _AdminList extends StatelessWidget {
  const _AdminList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) {
      return const XPEmptyState(
        icon: Icons.inbox_outlined,
        title: 'No records yet',
        message: 'Use the add action above to create one.',
      );
    }

    return Column(children: children);
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final Future<void> Function() onDelete;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: XPCard(
        elevated: true,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            XPOutlinedButton(
              label: 'Edit',
              expand: false,
              size: XPButtonSize.small,
              onPressed: onEdit,
            ),
            const SizedBox(width: AppSpacing.sm),
            XPOutlinedButton(
              label: 'Delete',
              expand: false,
              size: XPButtonSize.small,
              onPressed: () async => onDelete(),
            ),
          ],
        ),
      ),
    );
  }
}
