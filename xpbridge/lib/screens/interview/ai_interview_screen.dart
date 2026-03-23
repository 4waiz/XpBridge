import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../models/ai_interview.dart';
import '../../models/application.dart';
import '../../services/ai_interview_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_app_bar.dart';
import '../../widgets/xp_button.dart';
import '../../widgets/xp_card.dart';
import '../../widgets/xp_input.dart';
import '../../widgets/xp_premium.dart';

class AiInterviewScreen extends StatefulWidget {
  const AiInterviewScreen({super.key, required this.interviewId});

  final String interviewId;

  @override
  State<AiInterviewScreen> createState() => _AiInterviewScreenState();
}

class _AiInterviewScreenState extends State<AiInterviewScreen> {
  final TextEditingController _responseController = TextEditingController();
  final Map<int, AiInterviewResponse> _draftResponses = {};
  int _currentIndex = 0;
  bool _isRecording = false;
  bool _submitted = false;

  @override
  void dispose() {
    _responseController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final appState = AppStateScope.of(context);
    final interview = appState.getInterviewById(widget.interviewId);
    if (interview != null &&
        interview.status == AiInterviewStatus.pending &&
        !_submitted) {
      appState.startAiInterview(widget.interviewId);
    }
    if (interview != null && interview.status == AiInterviewStatus.completed) {
      _submitted = true;
    }
  }

  void _saveDraft(AiInterview interview, {required bool skipped}) {
    _draftResponses[_currentIndex] = AiInterviewResponse(
      question: interview.questions[_currentIndex],
      responseText: skipped ? '' : _responseController.text.trim(),
      usedTextFallback: !_isRecording,
      skipped: skipped,
    );
  }

  Future<void> _submitInterview(
    AppState appState,
    AiInterview interview,
  ) async {
    _saveDraft(interview, skipped: _responseController.text.trim().isEmpty);
    final orderedResponses = List<AiInterviewResponse>.generate(
      interview.questions.length,
      (index) =>
          _draftResponses[index] ??
          AiInterviewResponse(
            question: interview.questions[index],
            responseText: '',
            usedTextFallback: true,
            skipped: true,
          ),
    );
    await appState.submitAiInterview(widget.interviewId, orderedResponses);
    if (!mounted) return;
    setState(() => _submitted = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Interview submitted'),
        backgroundColor: AppTheme.successDark,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppStateScope.of(context);
    final interview = appState.getInterviewById(widget.interviewId);

    if (interview == null) {
      return Scaffold(
        backgroundColor: Colors.transparent,
        body: XPScene(
          compact: true,
          child: SafeArea(
            child: Column(
              children: const [
                XPAppBar(title: 'AI Interview'),
                Expanded(child: Center(child: Text('Interview not found'))),
              ],
            ),
          ),
        ),
      );
    }

    final application = appState.getApplicationById(interview.applicationId);
    final totalQuestions = interview.questions.length;
    final progress = ((_currentIndex + 1) / totalQuestions)
        .clamp(0.0, 1.0)
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: XPScene(
        compact: true,
        child: SafeArea(
          child: Column(
            children: [
              XPAppBar(
                title: 'AI Interview',
                subtitle: application?.startupName ?? 'Founder review',
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.page,
                    AppSpacing.md,
                    AppSpacing.page,
                    140,
                  ),
                  child: _submitted
                      ? _SubmittedState(application: application, interview: interview)
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            XPGlassPanel(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              backgroundColor: AppTheme.surface.withValues(
                                alpha: 0.72,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      XPBadge(
                                        label: application?.roleTitle ?? 'Mission',
                                        icon: Icons.work_outline_rounded,
                                        color: AppTheme.primarySoft,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      XPBadge(
                                        label: '3-5 min',
                                        icon: Icons.schedule_rounded,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  Text(
                                    application?.startupName ?? 'Startup',
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  XPProgressBar(progress: progress),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    'Question ${_currentIndex + 1} of $totalQuestions',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            XPSection(
                              title: 'Prompt',
                              subtitle:
                                  'Speak naturally, then edit the transcript or use text fallback.',
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    interview.questions[_currentIndex],
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineSmall
                                        ?.copyWith(fontSize: 28),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  XPContainer(
                                    color: AppTheme.primarySoft,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Icon(
                                          Icons.mic_none_rounded,
                                          color: AppTheme.primaryDark,
                                        ),
                                        const SizedBox(width: AppSpacing.sm),
                                        Expanded(
                                          child: Text(
                                            _isRecording
                                                ? 'Recording simulated for MVP. Stop when you are done, then review the transcript below.'
                                                : 'Voice capture is scaffolded for later audio/STT integration. You can type a response or use the simulated record flow now.',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  XPTextField(
                                    controller: _responseController,
                                    labelText: 'Voice transcript or text fallback',
                                    hintText:
                                        'Summarize your answer in a few sentences.',
                                    prefixIcon: Icons.chat_bubble_outline_rounded,
                                    maxLines: 6,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _submitted
          ? XPBottomActionBar(
              child: XPButton(
                label: 'Back to applications',
                icon: Icons.arrow_back_rounded,
                onPressed: () => context.pop(),
              ),
            )
          : XPBottomActionBar(
              child: Row(
                children: [
                  Expanded(
                    child: XPOutlinedButton(
                      label: _isRecording ? 'Stop' : 'Record',
                      icon: _isRecording
                          ? Icons.stop_circle_outlined
                          : Icons.mic_none_rounded,
                      size: XPButtonSize.medium,
                      onPressed: () {
                        setState(() {
                          _isRecording = !_isRecording;
                          if (!_isRecording &&
                              _responseController.text.trim().isEmpty) {
                            _responseController.text =
                                'Simulated voice transcript: I explained my relevant work, how I communicate, and why this mission fits my goals.';
                          }
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: XPOutlinedButton(
                      label: 'Skip',
                      icon: Icons.skip_next_rounded,
                      size: XPButtonSize.medium,
                      onPressed: () {
                        _saveDraft(interview, skipped: true);
                        if (_currentIndex == totalQuestions - 1) {
                          _submitInterview(appState, interview);
                          return;
                        }
                        setState(() {
                          _currentIndex += 1;
                          _isRecording = false;
                          _responseController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: XPButton(
                      label: _currentIndex == totalQuestions - 1
                          ? 'Submit'
                          : 'Next',
                      icon: _currentIndex == totalQuestions - 1
                          ? Icons.check_circle_outline_rounded
                          : Icons.arrow_forward_rounded,
                      size: XPButtonSize.medium,
                      onPressed: () {
                        _saveDraft(
                          interview,
                          skipped: _responseController.text.trim().isEmpty,
                        );
                        if (_currentIndex == totalQuestions - 1) {
                          _submitInterview(appState, interview);
                          return;
                        }
                        setState(() {
                          _currentIndex += 1;
                          _isRecording = false;
                          _responseController.clear();
                        });
                      },
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _SubmittedState extends StatelessWidget {
  const _SubmittedState({
    required this.application,
    required this.interview,
  });

  final Application? application;
  final AiInterview interview;

  @override
  Widget build(BuildContext context) {
    return XPSection(
      child: Column(
        children: [
          Container(
            width: 92,
            height: 92,
            decoration: BoxDecoration(
              gradient: AppTheme.primaryGlowGradient,
              borderRadius: BorderRadius.circular(28),
              boxShadow: AppTheme.softGlowShadow,
            ),
            child: const Icon(
              Icons.verified_rounded,
              size: 36,
              color: AppTheme.surface,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Interview Submitted',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your structured interview is now ready for ${application?.startupName ?? 'the startup'} to review.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (interview.summary?.isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.xl),
            XPContainer(
              color: AppTheme.primarySoft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(interview.summary!),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: [
                      XPBadge(
                        label:
                            'Communication ${interview.communicationScore ?? 0}',
                        color: AppTheme.surface.withValues(alpha: 0.72),
                      ),
                      XPBadge(
                        label: 'Confidence ${interview.confidenceScore ?? 0}',
                        color: AppTheme.surface.withValues(alpha: 0.72),
                      ),
                      XPBadge(
                        label: 'Relevance ${interview.relevanceScore ?? 0}',
                        color: AppTheme.surface.withValues(alpha: 0.72),
                      ),
                      if (interview.recommendation != null)
                        XPBadge(
                          label: AiInterviewService.recommendationLabel(
                            interview.recommendation!,
                          ),
                          color: AppTheme.primaryDeep,
                          textColor: AppTheme.surface,
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
