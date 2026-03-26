import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/ai_interview.dart';
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
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() => AppStateScope.of(context).refreshSession();

  bool _matches(String value) {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return true;
    return value.toLowerCase().contains(query);
  }

  String _pseudoUuid() {
    final timestamp =
        DateTime.now().microsecondsSinceEpoch.toRadixString(16).padLeft(12, '0');
    return '00000000-0000-0000-0000-${timestamp.substring(0, 12)}';
  }

  Future<void> _showJsonDialog(String title, Map<String, dynamic> data) async {
    const encoder = JsonEncoder.withIndent('  ');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 620,
          child: SingleChildScrollView(
            child: SelectableText(
              encoder.convert(data),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                  ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<bool> _confirmDelete(String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed ?? false;
  }

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
      builder: (context) => AlertDialog(
        title: Text(student != null || startup != null ? 'Edit profile' : 'Add profile'),
        content: SizedBox(
          width: 520,
          child: ValueListenableBuilder<String>(
            valueListenable: role,
            builder: (context, currentRole, child) => SingleChildScrollView(
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
                      labelText:
                          currentRole == 'startup' ? 'Company name' : 'Full name',
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
                      labelText:
                          currentRole == 'startup' ? 'Description' : 'Bio',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextField(
                    controller: auxController,
                    decoration: InputDecoration(
                      labelText:
                          currentRole == 'startup' ? 'Industry' : 'Education',
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
                      labelText:
                          currentRole == 'startup' ? 'Website' : 'Portfolio URL',
                    ),
                  ),
                ],
              ),
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
              final currentRole = role.value;
              final skills = skillsController.text
                  .split(',')
                  .map((value) => value.trim())
                  .where((value) => value.isNotEmpty)
                  .toList();
              final data = <String, dynamic>{
                'id': startup?.id ?? student?.id ?? _pseudoUuid(),
                'role': currentRole,
                'email': emailController.text.trim(),
                'created_at':
                    (startup?.createdAt ?? student?.createdAt ?? DateTime.now())
                        .toIso8601String(),
              };
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
      ),
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
      text: mission?.requiredSkills.join(', '),
    );
    final outcomeController = TextEditingController(
      text: mission?.learningOutcome ?? '',
    );
    final statusController = ValueNotifier<String>(mission?.status ?? 'open');

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
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
                  decoration:
                      const InputDecoration(labelText: 'Learning outcome'),
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
      ),
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
      builder: (context) => AlertDialog(
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
                              child: Text('${item.startupName} - ${item.title}'),
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
      ),
    );
  }

  Future<void> _showInterviewEditor({AiInterview? interview}) async {
    final appState = AppStateScope.of(context);
    final applicationId = ValueNotifier<String?>(
      interview?.applicationId ?? appState.applications.firstOrNull?.id,
    );
    final status = ValueNotifier<String>(interview?.status.name ?? 'pending');
    final summaryController = TextEditingController(text: interview?.summary ?? '');
    final questionsController = TextEditingController(
      text: interview?.questions.join('\n') ?? '',
    );

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(interview == null ? 'Add interview' : 'Edit interview'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ValueListenableBuilder<String?>(
                  valueListenable: applicationId,
                  builder: (context, currentApplication, child) {
                    return DropdownButtonFormField<String>(
                      initialValue: currentApplication,
                      decoration:
                          const InputDecoration(labelText: 'Application'),
                      items: appState.applications
                          .map(
                            (item) => DropdownMenuItem<String>(
                              value: item.id,
                              child: Text(
                                '${item.studentName} - ${item.roleTitle ?? 'Application'}',
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => applicationId.value = value,
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
                      items: AiInterviewStatus.values
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
                  controller: questionsController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Questions (one per line)',
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                TextField(
                  controller: summaryController,
                  minLines: 3,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Summary'),
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
              final application =
                  appState.getApplicationById(applicationId.value ?? '');
              if (application == null) return;
              final questions = questionsController.text
                  .split('\n')
                  .map((item) => item.trim())
                  .where((item) => item.isNotEmpty)
                  .toList();
              await SupabaseService.upsertAiInterviewRow({
                'id': interview?.id ?? _pseudoUuid(),
                'application_id': application.id,
                'mission_id': application.missionId,
                'student_id': application.studentId,
                'startup_id': application.startupId,
                'questions': questions,
                'responses':
                    interview?.responses.map((item) => item.toMap()).toList() ?? [],
                'status': status.value,
                'summary': summaryController.text.trim(),
                'completed_at': status.value == AiInterviewStatus.completed.name
                    ? (interview?.completedAt ?? DateTime.now()).toIso8601String()
                    : null,
              });
              if (!context.mounted) return;
              Navigator.pop(context);
              await _refresh();
            },
            child: const Text('Save'),
          ),
        ],
      ),
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
          child: XPEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Admin access required',
            message: 'This page is only available to admins.',
          ),
        ),
      );
    }

    final profileTiles = [
      ...appState.students.where((s) => _matches('${s.name} ${s.email}')).map(
            (student) => _AdminTile(
              title: student.name,
              subtitle: 'Student - ${student.email}',
              onView: () => _showJsonDialog('Student record', {
                'id': student.id,
                'role': 'student',
                'name': student.name,
                'email': student.email,
                'bio': student.bio,
                'education': student.education,
                'skills': student.skills,
                'portfolio_url': student.portfolioUrl,
                'github_url': student.githubUrl,
                'created_at': student.createdAt.toIso8601String(),
              }),
              onEdit: () => _showProfileEditor(student: student),
              onDelete: () async {
                final confirmed = await _confirmDelete(
                  'Delete student',
                  'Remove ${student.name}?',
                );
                if (!confirmed) return;
                await SupabaseService.deleteProfile(student.id);
                if (!mounted) return;
                await _refresh();
              },
            ),
          ),
      ...appState.startups.where((s) => _matches('${s.companyName} ${s.email}')).map(
            (startup) => _AdminTile(
              title: startup.companyName,
              subtitle: 'Startup - ${startup.email}',
              onView: () => _showJsonDialog('Startup record', {
                'id': startup.id,
                'role': 'startup',
                'company_name': startup.companyName,
                'email': startup.email,
                'description': startup.description,
                'industry': startup.industry,
                'required_skills': startup.requiredSkills,
                'website_url': startup.websiteUrl,
                'created_at': startup.createdAt.toIso8601String(),
              }),
              onEdit: () => _showProfileEditor(startup: startup),
              onDelete: () async {
                final confirmed = await _confirmDelete(
                  'Delete startup',
                  'Remove ${startup.companyName}?',
                );
                if (!confirmed) return;
                await SupabaseService.deleteProfile(startup.id);
                if (!mounted) return;
                await _refresh();
              },
            ),
          ),
    ];

    final missionTiles = appState.missions
        .where((m) => _matches('${m.title} ${m.startupName} ${m.status}'))
        .map(
          (mission) => _AdminTile(
            title: mission.title,
            subtitle: '${mission.startupName} - ${mission.status}',
            onView: () => _showJsonDialog('Mission record', mission.toMap()),
            onEdit: () => _showMissionEditor(mission: mission),
            onDelete: () async {
              final confirmed = await _confirmDelete(
                'Delete mission',
                'Remove ${mission.title}?',
              );
              if (!confirmed) return;
              await SupabaseService.deleteMission(mission.id);
              if (!mounted) return;
              await _refresh();
            },
          ),
        )
        .toList();

    final applicationTiles = appState.applications
        .where((a) => _matches('${a.studentName} ${a.startupName} ${a.status.name}'))
        .map(
          (application) => _AdminTile(
            title: application.studentName,
            subtitle:
                '${application.roleTitle ?? 'Application'} - ${application.status.name}',
            onView: () =>
                _showJsonDialog('Application record', application.toMap()),
            onEdit: () => _showApplicationEditor(application: application),
            onDelete: () async {
              final confirmed = await _confirmDelete(
                'Delete application',
                'Remove this application?',
              );
              if (!confirmed) return;
              await SupabaseService.deleteApplication(application.id);
              if (!mounted) return;
              await _refresh();
            },
          ),
        )
        .toList();

    final interviewTiles = appState.aiInterviews
        .where((i) => _matches('${i.id} ${i.status.name} ${i.summary ?? ''}'))
        .map(
          (interview) => _AdminTile(
            title: interview.id,
            subtitle: 'Interview - ${interview.status.name}',
            onView: () =>
                _showJsonDialog('AI interview record', interview.toMap()),
            onEdit: () => _showInterviewEditor(interview: interview),
            onDelete: () async {
              final confirmed = await _confirmDelete(
                'Delete interview',
                'Remove this AI interview record?',
              );
              if (!confirmed) return;
              await SupabaseService.deleteAiInterview(interview.id);
              if (!mounted) return;
              await _refresh();
            },
          ),
        )
        .toList();

    final sections = [
      profileTiles,
      missionTiles,
      applicationTiles,
      interviewTiles,
    ];
    final addLabels = [
      'Add profile',
      'Add mission',
      'Add application',
      'Add interview',
    ];

    return XPPageScaffold(
      title: 'Admin console',
      subtitle: 'Create, edit, inspect, and remove live records.',
      showBack: true,
      onBack: () => context.goNamed('adminPreview'),
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
                      ButtonSegment<int>(value: 3, label: Text('Interviews')),
                    ],
                    selected: {_tabIndex},
                    onSelectionChanged: (selection) {
                      setState(() => _tabIndex = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Search',
                      hintText: 'Filter current tab',
                      prefixIcon: Icon(Icons.search_rounded),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  XPButton(
                    label: addLabels[_tabIndex],
                    icon: Icons.add_rounded,
                    onPressed: () {
                      if (_tabIndex == 0) {
                        _showProfileEditor();
                      } else if (_tabIndex == 1) {
                        _showMissionEditor();
                      } else if (_tabIndex == 2) {
                        _showApplicationEditor();
                      } else {
                        _showInterviewEditor();
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.md,
                    children: [
                      _CountChip(label: 'Profiles', value: '${profileTiles.length}'),
                      _CountChip(label: 'Missions', value: '${missionTiles.length}'),
                      _CountChip(label: 'Applications', value: '${applicationTiles.length}'),
                      _CountChip(label: 'Interviews', value: '${interviewTiles.length}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (sections[_tabIndex].isEmpty)
              const XPEmptyState(
                icon: Icons.inbox_outlined,
                title: 'No records found',
                message: 'Nothing matches the current filter.',
              )
            else
              Column(children: sections[_tabIndex]),
          ],
        ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: AppTheme.primarySoft,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Text('$label: $value'),
    );
  }
}

class _AdminTile extends StatelessWidget {
  const _AdminTile({
    required this.title,
    required this.subtitle,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
  });

  final String title;
  final String subtitle;
  final VoidCallback onView;
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
              label: 'View',
              expand: false,
              size: XPButtonSize.small,
              onPressed: onView,
            ),
            const SizedBox(width: AppSpacing.sm),
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
