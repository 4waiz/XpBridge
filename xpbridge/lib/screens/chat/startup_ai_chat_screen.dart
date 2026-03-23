import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/student_profile.dart';
import '../../services/ai_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_ai.dart';

class StartupAiChatScreen extends StatefulWidget {
  const StartupAiChatScreen({super.key});

  @override
  State<StartupAiChatScreen> createState() => _StartupAiChatScreenState();
}

class _StartupAiChatScreenState extends State<StartupAiChatScreen> {
  static const _welcomeMessage =
      "I'd be happy to help identify talent. Tell me what you're building, the skills you need, and how quickly you want someone to contribute.";
  static const _resetMessage =
      'Chat reset. Describe the capability, stack, or type of student you need.';

  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  final List<_ChatMessage> _messages = [];
  bool _isLoading = false;
  bool _isVoiceMode = false;
  bool _showQuickActions = true;
  List<StudentProfile> _matchedStudents = [];

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

  Future<void> _sendMessage([String? predefined]) async {
    final text = predefined ?? _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    setState(() {
      _messages.add(_ChatMessage(text: text, isUser: true));
      _isLoading = true;
      _isVoiceMode = false;
      _showQuickActions = false;
      _matchedStudents = [];
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await AiService.sendMessageForStartup(text, null);
      setState(() {
        _isLoading = false;
        if (AiService.lastMatchedStudents.isNotEmpty) {
          _matchedStudents = AiService.lastMatchedStudents.take(6).toList();
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
      _isVoiceMode = false;
      _showQuickActions = true;
    });
    AiService.resetStartupChat();
    _addBotMessage(_resetMessage);
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      _showQuickActions = false;
    });
  }

  void _toggleQuickActions() {
    setState(() {
      _showQuickActions = !_showQuickActions;
      _isVoiceMode = false;
    });
  }

  List<XPAiResultCardData> _studentCards() {
    return _matchedStudents.map((student) {
      final subtitle = [
        if (student.education?.isNotEmpty == true) student.education!,
        '${student.availabilityHours.round()}h / wk',
      ].join(' · ');
      return XPAiResultCardData(
        eyebrow: student.skills.take(2).join(' · '),
        title: student.name,
        subtitle: subtitle,
        trailingLabel: '${student.xpPoints} XP',
        onTap: () => context.pushNamed(
          'studentDetail',
          pathParameters: {'id': student.id},
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPAiShell(
        showBackdropMap: _matchedStudents.isNotEmpty,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    XPAiCircleActionButton(
                      icon: Icons.arrow_back_ios_new_rounded,
                      onTap: () => context.pop(),
                    ),
                    const Spacer(),
                    XPAiCircleActionButton(
                      icon: Icons.edit_outlined,
                      onTap: _resetChat,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  child: _isVoiceMode
                      ? const Padding(
                          key: ValueKey('voice'),
                          padding: EdgeInsets.symmetric(
                            horizontal: AppSpacing.pageWide,
                          ),
                          child: XPAiVoiceState(
                            status: 'Recording...',
                            subtitle:
                                'Describe the role, stack, or working style you want to hire for.',
                          ),
                        )
                      : ListView(
                          key: const ValueKey('chat'),
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.pageWide,
                            AppSpacing.md,
                            AppSpacing.pageWide,
                            AppSpacing.md,
                          ),
                          children: [
                            if (_messages.length == 1) ...[
                              Text(
                                'Find the right\nstudent faster',
                                style: Theme.of(context).textTheme.displayMedium
                                    ?.copyWith(
                                      color: AppTheme.surface,
                                      fontSize: 44,
                                      height: 0.96,
                                    ),
                              ),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            if (_showQuickActions) ...[
                              _StartupQuickActions(onTap: _sendMessage),
                              const SizedBox(height: AppSpacing.lg),
                            ],
                            ..._messages.map(
                              (message) => XPAiTextBubble(
                                text: message.text,
                                isUser: message.isUser,
                              ),
                            ),
                            if (_isLoading)
                              const XPAiTextBubble(
                                text: '',
                                isUser: false,
                                isLoading: true,
                              ),
                            if (_matchedStudents.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.sm),
                              XPAiFloatingResultsDeck(
                                cards: _studentCards(),
                                actionLabel: 'View All',
                                onActionTap: () =>
                                    context.pushNamed('startupDashboard'),
                              ),
                            ],
                            const SizedBox(height: AppSpacing.xl),
                          ],
                        ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.page,
                  AppSpacing.sm,
                  AppSpacing.page,
                  AppSpacing.lg,
                ),
                child: SafeArea(
                  top: false,
                  child: XPAiComposer(
                    controller: _messageController,
                    hintText: 'Ask XPBridge AI...',
                    onSend: _sendMessage,
                    onPlusTap: _toggleQuickActions,
                    onMicTap: _toggleVoiceMode,
                    isLoading: _isLoading,
                    isMicActive: _isVoiceMode,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatMessage {
  const _ChatMessage({required this.text, required this.isUser});

  final String text;
  final bool isUser;
}

class _StartupQuickActions extends StatelessWidget {
  const _StartupQuickActions({required this.onTap});

  final Future<void> Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Flutter student for mobile app', Icons.phone_iphone_rounded),
      ('Design-focused product talent', Icons.brush_outlined),
      ('AI / data candidate', Icons.auto_graph_outlined),
      ('Part-time technical generalist', Icons.hub_outlined),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: actions.map((action) {
        return XPAiQuickChip(
          label: action.$1,
          icon: action.$2,
          onTap: () => onTap(action.$1),
        );
      }).toList(),
    );
  }
}
