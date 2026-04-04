import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/ai_chat_message.dart';
import '../../services/ai_service.dart';
import '../../services/job_matcher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/xp_ai.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  bool get _aiEnabled => AppStateScope.of(context).aiFeaturesEnabled;

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  List<MatchedRole> _matchedRoles = [];
  bool _isLoading = false;
  bool _showMatchedRoles = false;
  bool _isInitialized = false;
  bool _showQuickActions = true;
  bool _isVoiceMode = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeChat();
    });
  }

  void _initializeChat() {
    final appState = AppStateScope.of(context);
    final profile = appState.studentProfile;

    setState(() {
      _messages.add(
        AiChatMessage(
          id: 'welcome',
          content:
              "Hi${profile != null ? ' ${profile.name.split(' ').first}' : ''}! I'd be happy to help identify opportunities. Tell me the role, location style, or kind of company you're aiming for.",
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      );
      _isInitialized = true;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

  Future<void> _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final appState = AppStateScope.of(context);
    final profile = appState.studentProfile;

    if (_showQuickActions) {
      setState(() => _showQuickActions = false);
    }

    setState(() {
      _isVoiceMode = false;
      _showMatchedRoles = false;
      _matchedRoles = [];
      _messages.add(
        AiChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          content: text,
          sender: MessageSender.user,
          timestamp: DateTime.now(),
        ),
      );
      _isLoading = true;
    });

    _controller.clear();
    _scrollToBottom();

    final loadingId = 'loading_${DateTime.now().millisecondsSinceEpoch}';
    setState(() {
      _messages.add(
        AiChatMessage(
          id: loadingId,
          content: '',
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
          isLoading: true,
        ),
      );
    });
    _scrollToBottom();

    try {
      final response = await AiService.sendMessageWithContext(text, profile);

      setState(() {
        _messages.removeWhere((message) => message.id == loadingId);
        _messages.add(
          AiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: response,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });

      final recommendedRoles = AiService.extractRecommendedRoles(response);
      if (recommendedRoles.isNotEmpty) {
        final matches = JobMatcherService.findMatchingRoles(
          recommendedRoles,
          userSkills: profile?.skills,
        );

        if (matches.isNotEmpty) {
          setState(() {
            _matchedRoles = matches.take(6).toList();
            _showMatchedRoles = true;
          });
        }
      }
    } catch (error) {
      final errorText = error.toString().toLowerCase();
      final friendlyMessage = errorText.contains('not configured') ||
              errorText.contains('503')
          ? 'AI is being set up and will be available soon. In the meantime, browse missions from the dashboard!'
          : errorText.contains('timeout') || errorText.contains('timed out')
              ? 'The AI took too long to respond. Please try again.'
              : errorText.contains('unauthorized') ||
                      errorText.contains('session')
                  ? 'Your session expired. Please log in again.'
                  : 'Something went wrong. Please try again in a moment.';
      setState(() {
        _messages.removeWhere((message) => message.id == loadingId);
        _messages.add(
          AiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: friendlyMessage,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }

    _scrollToBottom();
  }

  void _resetChat() {
    AiService.resetChat();
    setState(() {
      _messages.clear();
      _matchedRoles.clear();
      _showMatchedRoles = false;
      _isInitialized = false;
      _showQuickActions = true;
      _isVoiceMode = false;
    });
    _initializeChat();
  }

  void _toggleQuickActions() {
    setState(() {
      _showQuickActions = !_showQuickActions;
      _isVoiceMode = false;
    });
  }

  void _toggleVoiceMode() {
    setState(() {
      _isVoiceMode = !_isVoiceMode;
      _showQuickActions = false;
    });
  }

  List<XPAiResultCardData> _resultCards(List<MatchedRole> matches) {
    return matches.map((match) {
      final subtitleParts = <String>[
        match.startup.companyName,
        if (match.role.commitment?.isNotEmpty == true) match.role.commitment!,
      ];
      return XPAiResultCardData(
        eyebrow: match.startup.industry,
        title: match.role.title,
        subtitle: subtitleParts.join(' - '),
        trailingLabel: '${(match.matchScore * 100).round()}% fit',
        onTap: () => context.pushNamed(
          'startupDetail',
          pathParameters: {'id': match.startup.id},
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (!_aiEnabled) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: XPAiShell(
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.pageWide),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.auto_awesome_rounded,
                      size: 64,
                      color: AppTheme.surface.withValues(alpha: 0.7),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'AI Chat — Coming Soon',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: AppTheme.surface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'We\'re setting up a secure AI assistant to help you discover roles and get career advice. Stay tuned!',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.surface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPAiShell(
        showBackdropMap: _showMatchedRoles,
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
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.goNamed('studentDashboard');
                        }
                      },
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
                child: _isInitialized
                    ? AnimatedSwitcher(
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
                                      'Describe the role, location style, or salary range you want.',
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
                                      'Ready for\nyour next role?',
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayMedium
                                          ?.copyWith(
                                            color: AppTheme.surface,
                                            fontSize: 46,
                                            height: 0.95,
                                          ),
                                    ),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                  if (_showQuickActions) ...[
                                    _QuickActions(onTap: _sendMessage),
                                    const SizedBox(height: AppSpacing.lg),
                                  ],
                                  ..._messages.map(
                                    (message) => ChatBubble(message: message),
                                  ),
                                  if (_showMatchedRoles &&
                                      _matchedRoles.isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.sm),
                                    XPAiFloatingResultsDeck(
                                      cards: _resultCards(_matchedRoles),
                                      actionLabel: 'View All',
                                      onActionTap: () =>
                                          context.pushNamed('studentDashboard'),
                                    ),
                                  ],
                                  const SizedBox(height: AppSpacing.xl),
                                ],
                              ),
                      )
                    : const Center(child: CircularProgressIndicator()),
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
                    controller: _controller,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTap});

  final Future<void> Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Remote Flutter roles', Icons.work_outline_rounded),
      ('High-fit AI startups', Icons.auto_awesome_rounded),
      ('Roles near me', Icons.pin_drop_outlined),
      ('What should I apply to?', Icons.explore_outlined),
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
