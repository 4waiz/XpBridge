import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/student_profile.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_section_title.dart';

class StartupAiChatScreen extends StatefulWidget {
  const StartupAiChatScreen({super.key});

  @override
  State<StartupAiChatScreen> createState() => _StartupAiChatScreenState();
}

class _StartupAiChatScreenState extends State<StartupAiChatScreen> {
  static const _welcomeMessage =
      "I'm your AI talent finder. Tell me what you're building or which skills you need, and I'll help you surface the best student matches.";
  static const _resetMessage =
      'Chat reset. Tell me what kind of student or capability you need.';

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  List<StudentProfile> _matchedStudents = [];
  List<String> _searchedSkills = [];

  @override
  void initState() {
    super.initState();
    AiService.resetStartupChat();
    _addBotMessage(_welcomeMessage);
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _addBotMessage(String text) {
    setState(() => _messages.add(_ChatMessage(text: text, isUser: false)));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await AiService.sendMessageForStartup(text, null);
      setState(() {
        _isLoading = false;
        if (AiService.lastMatchedStudents.isNotEmpty) {
          _matchedStudents = AiService.lastMatchedStudents;
          _searchedSkills = [];
        }
      });
      _addBotMessage(response);
    } catch (error) {
      setState(() => _isLoading = false);
      _addBotMessage('Error: $error');
    }
  }

  void _resetChat() {
    setState(() {
      _messages.clear();
      _matchedStudents.clear();
    });
    AiService.resetStartupChat();
    _addBotMessage(_resetMessage);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: XPAppBar(
        title: 'AI Talent Finder',
        subtitle: 'Describe the capability you need',
        trailing: XPHeaderButton(
          icon: Icons.refresh_rounded,
          onTap: _resetChat,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.page,
                AppSpacing.md,
                AppSpacing.page,
                AppSpacing.md,
              ),
              itemCount:
                  _messages.length +
                  (_matchedStudents.isNotEmpty ? 1 : 0) +
                  (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _messages.length) {
                  return _MessageBubble(message: _messages[index]);
                }
                if (_isLoading && index == _messages.length) {
                  return const _TypingIndicator();
                }
                return _StudentResults(
                  students: _matchedStudents,
                  searchedSkills: _searchedSkills,
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.page,
              AppSpacing.md,
              AppSpacing.page,
              AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: AppTheme.surface,
              boxShadow: AppTheme.elevatedShadow,
            ),
            child: SafeArea(
              top: false,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Describe the talent you need',
                        prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                      ),
                      textInputAction: TextInputAction.send,
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _sendMessage,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      child: Ink(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: _isLoading
                              ? AppTheme.cardBackground
                              : AppTheme.primary,
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                        ),
                        child: _isLoading
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.send_rounded,
                                color: AppTheme.text,
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
        ),
        decoration: BoxDecoration(
          color: isUser ? AppTheme.primary : AppTheme.surface,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(AppTheme.cornerRadius),
            topRight: const Radius.circular(AppTheme.cornerRadius),
            bottomLeft: Radius.circular(isUser ? AppTheme.cornerRadius : 8),
            bottomRight: Radius.circular(isUser ? 8 : AppTheme.cornerRadius),
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Text(
          message.text,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: AppTheme.text),
        ),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppTheme.cornerRadius),
            topRight: Radius.circular(AppTheme.cornerRadius),
            bottomLeft: Radius.circular(8),
            bottomRight: Radius.circular(AppTheme.cornerRadius),
          ),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            _AnimatedDot(delay: 0),
            SizedBox(width: 4),
            _AnimatedDot(delay: 200),
            SizedBox(width: 4),
            _AnimatedDot(delay: 400),
          ],
        ),
      ),
    );
  }
}

class _AnimatedDot extends StatelessWidget {
  const _AnimatedDot({required this.delay});

  final int delay;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 600 + delay),
      builder: (context, value, child) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.3 + (value * 0.5)),
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _StudentResults extends StatelessWidget {
  const _StudentResults({required this.students, required this.searchedSkills});

  final List<StudentProfile> students;
  final List<String> searchedSkills;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        XPSectionTitle(
          title: 'Matching students',
          subtitle: 'Tap a card to review their full profile.',
        ),
        const SizedBox(height: AppSpacing.md),
        ...students.map(
          (student) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: _StudentCard(
              student: student,
              searchedSkills: searchedSkills,
            ),
          ),
        ),
      ],
    );
  }
}

class _StudentCard extends StatelessWidget {
  const _StudentCard({required this.student, required this.searchedSkills});

  final StudentProfile student;
  final List<String> searchedSkills;

  @override
  Widget build(BuildContext context) {
    final matchedSkills = student.skills
        .where(
          (skill) => searchedSkills.any(
            (searched) => skill.toLowerCase().contains(searched.toLowerCase()),
          ),
        )
        .toList();

    final displaySkills = searchedSkills.isNotEmpty
        ? [
            ...matchedSkills,
            ...student.skills.where((skill) => !matchedSkills.contains(skill)),
          ]
        : student.skills;

    return XPCard(
      elevated: true,
      radius: AppTheme.cornerRadiusLarge,
      onTap: () => context.pushNamed(
        'studentDetail',
        pathParameters: {'id': student.id},
      ),
      child: Row(
        children: [
          XPAvatar(initial: student.name[0]),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    XPBadge(
                      label: '${student.availabilityHours}h/wk',
                      icon: Icons.schedule_rounded,
                      color: AppTheme.cardBackground,
                    ),
                    XPBadge(
                      label: '${student.xpPoints} XP',
                      icon: Icons.auto_awesome_rounded,
                      color: AppTheme.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: displaySkills
                      .take(4)
                      .map(
                        (skill) => XPSkillTag(
                          label: skill,
                          isMatched: matchedSkills.contains(skill),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
