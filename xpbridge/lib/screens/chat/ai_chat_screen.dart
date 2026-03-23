import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/ai_chat_message.dart';
import '../../services/ai_service.dart';
import '../../services/job_matcher_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_chip.dart';
import '../../widgets/xp_section_title.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];
  List<MatchedRole> _matchedRoles = [];
  bool _isLoading = false;
  bool _showMatchedRoles = false;
  bool _isInitialized = false;
  bool _showQuickActions = true;

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
              "Hi${profile != null ? ' ${profile.name.split(' ').first}' : ''}! I'm your career advisor. Tell me about yourself, your skills, or the kind of work you want, and I'll help you find the best fit.",
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
            _matchedRoles = matches.take(5).toList();
            _showMatchedRoles = true;
          });
        }
      }
    } catch (error) {
      setState(() {
        _messages.removeWhere((message) => message.id == loadingId);
        _messages.add(
          AiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: 'Error: $error',
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
    });
    _initializeChat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: XPAppBar(
        title: 'Career Advisor',
        subtitle: 'AI-powered guidance',
        trailing: XPHeaderButton(
          icon: Icons.refresh_rounded,
          onTap: _resetChat,
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isInitialized
                ? ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.page,
                      AppSpacing.md,
                      AppSpacing.page,
                      AppSpacing.md,
                    ),
                    itemCount:
                        _messages.length +
                        (_showQuickActions && _messages.length == 1 ? 1 : 0) +
                        (_showMatchedRoles ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (_showQuickActions &&
                          _messages.length == 1 &&
                          index == 1) {
                        return _QuickActions(onTap: _sendMessage);
                      }

                      final adjustedIndex =
                          _showQuickActions &&
                              _messages.length == 1 &&
                              index > 0
                          ? index - 1
                          : index;

                      if (_showMatchedRoles &&
                          adjustedIndex == _messages.length) {
                        return _MatchedRolesSection(matches: _matchedRoles);
                      }

                      return ChatBubble(message: _messages[adjustedIndex]);
                    },
                  )
                : const Center(child: CircularProgressIndicator()),
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
                      controller: _controller,
                      decoration: const InputDecoration(
                        hintText: 'Ask about missions, skills, or next steps',
                        prefixIcon: Icon(Icons.chat_bubble_outline_rounded),
                      ),
                      textInputAction: TextInputAction.send,
                      minLines: 1,
                      maxLines: 4,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: XPButton(
                      label: '',
                      icon: Icons.send_rounded,
                      expand: false,
                      onPressed: _isLoading ? null : _sendMessage,
                      size: XPButtonSize.medium,
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onTap});

  final Future<void> Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final actions = [
      ('Find a mission for me', Icons.rocket_launch_rounded),
      ('Improve my profile', Icons.auto_awesome_rounded),
      ('What skills should I learn next?', Icons.psychology_alt_outlined),
      ('Help me complete a mission', Icons.flag_outlined),
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: XPSection(
        title: 'Quick actions',
        child: Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: actions.map((action) {
            return XPFilterChip(
              label: action.$1,
              icon: action.$2,
              isSelected: false,
              onTap: () => onTap(action.$1),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _MatchedRolesSection extends StatelessWidget {
  const _MatchedRolesSection({required this.matches});

  final List<MatchedRole> matches;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          XPSectionTitle(
            title: 'Matching opportunities',
            subtitle: 'Best in-app matches based on the conversation.',
          ),
          const SizedBox(height: AppSpacing.md),
          ...matches.map((match) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.md),
              child: XPCard(
                elevated: true,
                radius: AppTheme.cornerRadiusLarge,
                onTap: () => context.pushNamed(
                  'startupDetail',
                  pathParameters: {'id': match.startup.id},
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        XPAvatar(initial: match.startup.companyName[0]),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                match.role.title,
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.xxs),
                              Text(
                                '${match.startup.companyName} • ${(match.matchScore * 100).round()}% fit',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    XPContainer(
                      color: AppTheme.primaryLight,
                      child: Text(match.matchReason),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
