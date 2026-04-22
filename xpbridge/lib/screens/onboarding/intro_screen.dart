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
      title: 'Close the\nexperience gap',
      eyebrow: 'XPBridge missions',
      supportingLine:
          'Work on real startup missions before anyone asks for experience.',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pc.png',
      title: 'Build proof\nwhile you learn',
      eyebrow: 'Proof over promises',
      supportingLine:
          'Turn small wins into visible work that actually moves your profile forward.',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pa.png',
      title: 'Turn missions\ninto growth',
      eyebrow: 'Earn visible momentum',
      supportingLine:
          'Earn trust, sharpen your skills, and show startups what you can do.',
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
      context.go('/student/dashboard');
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
                      // Step counter pill
                      DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppTheme.surface.withValues(alpha: 0.92),
                          borderRadius:
                              BorderRadius.circular(AppTheme.pillRadius),
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
                                style: Theme.of(context)
                                    .textTheme
                                    .labelLarge
                                    ?.copyWith(color: AppTheme.text),
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
                            borderRadius:
                                BorderRadius.circular(AppTheme.pillRadius),
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
                  // PageView
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
                          padding: EdgeInsets.fromLTRB(
                            AppSpacing.lg,
                            compact ? AppSpacing.lg : AppSpacing.xl,
                            AppSpacing.lg,
                            AppSpacing.md,
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
                              // Background glow
                              Positioned(
                                top: 8,
                                right: 2,
                                child: Container(
                                  width: 132,
                                  height: 132,
                                  decoration: BoxDecoration(
                                    gradient: RadialGradient(
                                      colors: [
                                        AppTheme.primary
                                            .withValues(alpha: 0.16),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Background card
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
                                        AppTheme.primary
                                            .withValues(alpha: 0.12),
                                        AppTheme.surface
                                            .withValues(alpha: 0.98),
                                        const Color(0xFFFFFCF6),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(32),
                                  ),
                                ),
                              ),
                              // Content
                              Column(
                                children: [
                                  // Eyebrow pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary
                                          .withValues(alpha: 0.12),
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
                                            fontWeight: FontWeight.w800,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? AppSpacing.md
                                        : AppSpacing.lg,
                                  ),
                                  // Title — larger for impact
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      page.title,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .headlineLarge
                                          ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF17212B),
                                            height: 1.05,
                                            letterSpacing: -0.5,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? AppSpacing.sm
                                        : AppSpacing.md,
                                  ),
                                  // Supporting line
                                  Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: compact
                                          ? AppSpacing.md
                                          : AppSpacing.xl,
                                    ),
                                    child: Text(
                                      page.supportingLine,
                                      maxLines: 3,
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: const Color(0xFF394B5D),
                                            height: 1.45,
                                          ),
                                    ),
                                  ),
                                  SizedBox(
                                    height: compact
                                        ? AppSpacing.md
                                        : AppSpacing.lg,
                                  ),
                                  // Illustration
                                  Expanded(
                                    child: Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        Positioned.fill(
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: RadialGradient(
                                                center:
                                                    const Alignment(0, 0.42),
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
                                            cacheWidth: 1080,
                                            filterQuality: FilterQuality.low,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Indicators + CTA
                                  Padding(
                                    padding: EdgeInsets.fromLTRB(
                                      compact ? AppSpacing.sm : AppSpacing.md,
                                      AppSpacing.md,
                                      compact ? AppSpacing.sm : AppSpacing.md,
                                      compact ? AppSpacing.md : AppSpacing.lg,
                                    ),
                                    child: Column(
                                      children: [
                                        // Progress bar indicators
                                        Row(
                                          children: List.generate(
                                            _pages.length,
                                            (i) => Expanded(
                                              child: AnimatedContainer(
                                                duration: const Duration(
                                                  milliseconds: 220,
                                                ),
                                                margin: EdgeInsets.only(
                                                  right:
                                                      i == _pages.length - 1
                                                          ? 0
                                                          : AppSpacing.sm,
                                                ),
                                                height: 6,
                                                decoration: BoxDecoration(
                                                  color: _currentPage == i
                                                      ? AppTheme.primary
                                                      : const Color(
                                                          0xFFBFD8D3),
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                    AppTheme.pillRadius,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                            height: AppSpacing.lg),
                                        // CTA — more prominent on last page
                                        XPButton(
                                          label: isLastPage
                                              ? 'Get started'
                                              : 'Continue',
                                          icon: isLastPage
                                              ? Icons.rocket_launch_rounded
                                              : Icons.arrow_forward_rounded,
                                          onPressed: _nextPage,
                                          size: isLastPage
                                              ? XPButtonSize.large
                                              : XPButtonSize.medium,
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
