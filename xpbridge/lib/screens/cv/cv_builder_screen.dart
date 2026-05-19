import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/ai_chat_message.dart';
import '../../models/cv_data.dart';
import '../../services/cv_ai_service.dart';
import '../../services/cv_pdf_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/chat_bubble.dart';
import '../../widgets/cv_preview.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_empty_state.dart';
import '../../widgets/xp_page_scaffold.dart';

/// English-text → CV maker. The chat pane collects the user's background in
/// plain language; a dedicated AI pipeline ([CvAiService]) rebuilds a
/// structured CV after every message, which is rendered natively in the
/// preview pane and exportable as a PDF. On mobile the two panes are toggled
/// rather than shown side-by-side.
enum _CvMode { chat, preview }

class CvBuilderScreen extends StatefulWidget {
  const CvBuilderScreen({super.key});

  @override
  State<CvBuilderScreen> createState() => _CvBuilderScreenState();
}

class _CvBuilderScreenState extends State<CvBuilderScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<AiChatMessage> _messages = [];

  CvData _cv = CvData.empty;
  _CvMode _mode = _CvMode.chat;
  bool _isLoading = false;
  bool _isExporting = false;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    CvAiService.reset();
    WidgetsBinding.instance.addPostFrameCallback((_) => _seedWelcome());
  }

  void _seedWelcome() {
    final profile = AppStateScope.of(context).studentProfile;
    final firstName =
        profile != null ? ' ${profile.name.split(' ').first}' : '';
    setState(() {
      _messages.add(
        AiChatMessage(
          id: 'welcome',
          content:
              "Hi$firstName! I'll build your CV from plain English — no formatting needed. "
              "Tell me about yourself: your education, any experience or projects, "
              "skills, and what roles you're targeting. I'll turn it into a polished CV on the right.",
          sender: MessageSender.ai,
          timestamp: DateTime.now(),
        ),
      );
      _initialized = true;
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

  Future<void> _send([String? predefined]) async {
    final text = predefined ?? _controller.text.trim();
    if (text.isEmpty || _isLoading) return;

    final appState = AppStateScope.of(context);
    if (!appState.requireAuthOr(context)) return;
    final profile = appState.studentProfile;

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

    const loadingId = 'loading';
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
      final turn = await CvAiService.send(text, profile);
      if (!mounted) return;
      setState(() {
        _messages.removeWhere((m) => m.id == loadingId);
        _messages.add(
          AiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: turn.reply,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
        _cv = turn.cv;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      final lower = error.toString().toLowerCase();
      final friendly = lower.contains('not configured') ||
              lower.contains('503')
          ? 'The CV AI is being set up and will be available soon.'
          : lower.contains('timeout') || lower.contains('timed out')
              ? 'That took too long. Please try again.'
              : lower.contains('unauthorized') || lower.contains('session')
                  ? 'Your session expired. Please log in again.'
                  : 'Something went wrong: ${error.toString()}';
      setState(() {
        _messages.removeWhere((m) => m.id == loadingId);
        _messages.add(
          AiChatMessage(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            content: friendly,
            sender: MessageSender.ai,
            timestamp: DateTime.now(),
          ),
        );
        _isLoading = false;
      });
    }
    _scrollToBottom();
  }

  void _reset() {
    CvAiService.reset();
    setState(() {
      _messages.clear();
      _cv = CvData.empty;
      _mode = _CvMode.chat;
      _initialized = false;
    });
    _seedWelcome();
  }

  Future<void> _export() async {
    if (_cv.isEmpty || _isExporting) return;
    setState(() => _isExporting = true);
    try {
      await CvPdfService.exportAndShare(_cv);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not export the PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);

    if (appState.isGuestPreview) {
      return _Gate(
        icon: Icons.lock_outline_rounded,
        title: 'Sign up to build your CV',
        message:
            'Create an account to turn plain English into a polished, exportable CV.',
        actionLabel: 'Sign up',
        onAction: () => context.go('/login'),
      );
    }

    if (!appState.aiFeaturesEnabled) {
      return const _Gate(
        icon: Icons.auto_awesome_rounded,
        title: 'CV Builder — Coming Soon',
        message:
            "We're setting up the AI that turns your story into a professional CV. Stay tuned!",
      );
    }

    return XPPageScaffold(
      title: 'CV Builder',
      subtitle: 'Describe yourself — AI writes the CV.',
      compact: true,
      trailing: XPHeaderButton(icon: Icons.refresh_rounded, onTap: _reset),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.page,
          AppSpacing.sm,
          AppSpacing.page,
          AppSpacing.md,
        ),
        child: Column(
          children: [
            _ModeToggle(
              mode: _mode,
              onChanged: (m) => setState(() => _mode = m),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                child: _mode == _CvMode.chat
                    ? _chatPane()
                    : _previewPane(),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (_mode == _CvMode.chat)
              _Composer(
                controller: _controller,
                isLoading: _isLoading,
                onSend: _send,
              )
            else
              XPButton(
                label: _cv.isEmpty ? 'Nothing to export yet' : 'Export as PDF',
                icon: Icons.download_rounded,
                loading: _isExporting,
                onPressed:
                    _cv.isEmpty || _isExporting ? null : _export,
              ),
          ],
        ),
      ),
    );
  }

  Widget _chatPane() {
    if (!_initialized) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      key: const ValueKey('cv-chat'),
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      children: [
        ..._messages.map((m) => ChatBubble(message: m)),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  Widget _previewPane() {
    return SizedBox.expand(
      key: const ValueKey('cv-preview'),
      child: CvPreview(cv: _cv),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.mode, required this.onChanged});

  final _CvMode mode;
  final ValueChanged<_CvMode> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.glassStrong,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          _segment('Chat', Icons.chat_bubble_outline_rounded, _CvMode.chat),
          _segment('Preview', Icons.description_outlined, _CvMode.preview),
        ],
      ),
    );
  }

  Widget _segment(String label, IconData icon, _CvMode value) {
    final selected = mode == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppTheme.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : AppTheme.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.isLoading,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool isLoading;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 6, 6, 6),
      decoration: BoxDecoration(
        color: AppTheme.glassStrong,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(color: AppTheme.primary.withValues(alpha: 0.12)),
        boxShadow: AppTheme.glassShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'e.g. I studied CS at NUST, built a Flutter app...',
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          GestureDetector(
            onTap: isLoading ? null : onSend,
            child: Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: isLoading ? AppTheme.primarySoft : AppTheme.primary,
                shape: BoxShape.circle,
              ),
              child: isLoading
                  ? const Padding(
                      padding: EdgeInsets.all(13),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.primary,
                      ),
                    )
                  : const Icon(Icons.arrow_upward_rounded,
                      color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _Gate extends StatelessWidget {
  const _Gate({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return XPPageScaffold(
      title: 'CV Builder',
      subtitle: 'English text to CV maker',
      compact: true,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.page),
          child: XPEmptyState(
            icon: icon,
            title: title,
            message: message,
            actionLabel: actionLabel,
            onAction: onAction,
          ),
        ),
      ),
    );
  }
}
