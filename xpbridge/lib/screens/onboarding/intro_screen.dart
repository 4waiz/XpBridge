import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app.dart';
import '../../theme/app_theme.dart';
import '../../widgets/xp_button.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      imagePath: 'assets/illustrations/pb.png',
      title: 'Close the experience gap',
      eyebrow: 'XPBridge missions',
      supportingLine: 'Work on real startup missions before anyone asks for experience.',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pc.png',
      title: 'Build proof while you learn',
      eyebrow: 'Proof over promises',
      supportingLine: 'Turn small wins into visible work that actually moves your profile forward.',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pa.png',
      title: 'Turn missions into growth',
      eyebrow: 'Earn visible momentum',
      supportingLine: 'Earn trust, sharpen your skills, and show startups what you can do.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    await AppStateScope.of(context).completeOnboarding();
    if (mounted) {
      context.goNamed('login');
    }
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
      return;
    }
    _completeOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxHeight < 760;
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                children: [
                  Row(
                    children: [
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          border: Border.all(
                            color: AppTheme.primary.withValues(alpha: 0.08),
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.md,
                            vertical: AppSpacing.sm,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppTheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Text(
                                '${_currentPage + 1}/${_pages.length}',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppTheme.pageTitle),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),
                      if (!isLastPage)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppTheme.surface.withValues(alpha: 0.76),
                            borderRadius: BorderRadius.circular(
                              AppTheme.pillRadius,
                            ),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.08),
                            ),
                          ),
                          child: TextButton(
                            onPressed: _completeOnboarding,
                            child: const Text('Skip'),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Expanded(
                    child: PageView.builder(
                      controller: _pageController,
                      onPageChanged: (index) =>
                          setState(() => _currentPage = index),
                      itemCount: _pages.length,
                      itemBuilder: (context, index) {
                        final page = _pages[index];
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.xl,
                            AppSpacing.xl,
                            AppSpacing.xl,
                            AppSpacing.lg,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFF7FEFC),
                                Color(0xFFEEF9F6),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.cornerRadiusLarge,
                            ),
                            border: Border.all(
                              color: AppTheme.primary.withValues(alpha: 0.1),
                            ),
                            boxShadow: AppTheme.elevatedShadow,
                          ),
                          child: Stack(
                            children: [
                              Positioned(
                                top: 8,
                                right: 2,
                                child: Container(
                                  width: 132,
                                  height: 132,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        AppTheme.primary.withValues(alpha: 0.16),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 14,
                                left: 12,
                                right: 12,
                                bottom: 0,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        AppTheme.primary.withValues(alpha: 0.12),
                                        AppTheme.surface.withValues(alpha: 0.98),
                                        const Color(0xFFFFFCF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                              ),
                              Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(
                                        AppTheme.pillRadius,
                                      ),
                                    ),
                                    child: Text(
                                      page.eyebrow,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelMedium
                                          ?.copyWith(
                                            color: AppTheme.primaryDeep,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? AppSpacing.md
                                        : AppSpacing.lg,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                    ),
                                    child: Text(
                                      page.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineMedium
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF17212B),
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? AppSpacing.xs
                                        : AppSpacing.md,
                                  ),
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: compact
                                          ? AppSpacing.lg
                                          : AppSpacing.xl,
                                    ),
                                    child: Text(
                                      page.supportingLine,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF394B5D),
                                            height: 1.4,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? AppSpacing.md
                                        : AppSpacing.lg,
                                  ),
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                center: const Alignment(0, 0.42),
                                                radius: 0.82,
                                                colors: [
                                                  AppTheme.primary.withValues(
                                                    alpha: 0.18,
                                                  ),
                                                  Colors.transparent,
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: EdgeInsets.fromLTRB(
                                            constraints.maxWidth < 360
                                                ? AppSpacing.sm
                                                : AppSpacing.lg,
                                            0,
                                            constraints.maxWidth < 360
                                                ? AppSpacing.sm
                                                : AppSpacing.lg,
                                            compact ? 2 : 8,
                                          ),
                                          child: Image.asset(
                                            page.imagePath,
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      compact ? AppSpacing.sm : AppSpacing.md,
                                      AppSpacing.md,
                                      compact ? AppSpacing.sm : AppSpacing.md,
                                      compact ? AppSpacing.md : AppSpacing.lg,
                                    ),
                                    child: Column(
                                      children: [
                                        Row(
                                          children: List.generate(
                                            _pages.length,
                                            (indicatorIndex) => Expanded(
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                margin: EdgeInsets.only(
                                                  right: indicatorIndex ==
                                                          _pages.length - 1
                                                      ? 0
                                                      : AppSpacing.sm,
                                                ),
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: _currentPage ==
                                                          indicatorIndex
                                                      ? AppTheme.primary
                                                      : const Color(0xFFBFD8D3),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppTheme.pillRadius,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: AppSpacing.lg),
                                        XPButton(
                                          label: isLastPage
                                              ? 'Start now'
                                              : 'Continue',
                                          icon: Icons.arrow_forward_rounded,
                                          onPressed: _nextPage,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.eyebrow,
    required this.supportingLine,
  });

  final String imagePath;
  final String title;
  final String eyebrow;
  final String supportingLine;
}
