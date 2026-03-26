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
      eyebrow: 'Launch stronger',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pc.png',
      title: 'Build proof while you learn',
      eyebrow: 'Move faster',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pa.png',
      title: 'Turn missions into growth',
      eyebrow: 'Show momentum',
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
            return Padding(
              padding: const EdgeInsets.all(AppSpacing.page),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: AppSpacing.sm,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surface,
                          borderRadius: BorderRadius.circular(
                            AppTheme.pillRadius,
                          ),
                          boxShadow: AppTheme.cardShadow,
                        ),
                        child: Text(
                          '${_currentPage + 1}/${_pages.length}',
                          style: Theme.of(context).textTheme.labelLarge
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                      ),
                      const Spacer(),
                      if (!isLastPage)
                        TextButton(
                          onPressed: _completeOnboarding,
                          child: const Text('Skip'),
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
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFFFFFF),
                                Color(0xFFF5FFFC),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(
                              AppTheme.cornerRadiusLarge,
                            ),
                            boxShadow: AppTheme.elevatedShadow,
                          ),
                          child: Column(
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
                              const SizedBox(height: AppSpacing.md),
                              Text(
                                page.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Expanded(
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Positioned(
                                      top: 8,
                                      right: 4,
                                      child: Container(
                                        width: 104,
                                        height: 104,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(36),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      left: 0,
                                      bottom: 28,
                                      child: Container(
                                        width: 84,
                                        height: 84,
                                        decoration: BoxDecoration(
                                          color:
                                              AppTheme.text.withValues(alpha: 0.04),
                                          borderRadius:
                                              BorderRadius.circular(30),
                                        ),
                                      ),
                                    ),
                                    Positioned.fill(
                                      child: DecoratedBox(
                                        decoration: BoxDecoration(
                                          gradient: RadialGradient(
                                            center: const Alignment(0, 0.2),
                                            radius: 0.85,
                                            colors: [
                                              AppTheme.primary.withValues(
                                                alpha: 0.14,
                                              ),
                                              Colors.transparent,
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: constraints.maxWidth < 360
                                            ? AppSpacing.sm
                                            : AppSpacing.lg,
                                      ),
                                      child: Image.asset(
                                        page.imagePath,
                                        fit: BoxFit.contain,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              XPButton(
                                label:
                                    isLastPage ? 'Start now' : 'Continue',
                                icon: Icons.arrow_forward_rounded,
                                onPressed: _nextPage,
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
  });

  final String imagePath;
  final String title;
  final String eyebrow;
}
