import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      description:
          'Breaking into the professional world is hard when experience is required before you even begin.',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pc.png',
      title: 'Build real-world proof while you learn',
      description:
          'Discover startup micro-projects that turn learning into portfolio-ready work and momentum.',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pa.png',
      title: 'Turn missions into growth',
      description:
          'Create a verified track record, unlock XP, and show startups what you can already do.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_complete', true);
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
        child: Padding(
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
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                      boxShadow: AppTheme.cardShadow,
                    ),
                    child: Text(
                      '${_currentPage + 1}/${_pages.length}',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            color: AppTheme.textSecondary,
                          ),
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
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) => setState(() => _currentPage = index),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      children: [
                        Expanded(
                          flex: 6,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppTheme.cornerRadiusLarge,
                              ),
                              boxShadow: AppTheme.elevatedShadow,
                            ),
                            child: Stack(
                              children: [
                                Positioned(
                                  top: 8,
                                  right: 8,
                                  child: Container(
                                    width: 94,
                                    height: 94,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primary.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(32),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: -10,
                                  bottom: 36,
                                  child: Container(
                                    width: 76,
                                    height: 76,
                                    decoration: BoxDecoration(
                                      color: AppTheme.text.withValues(alpha: 0.04),
                                      borderRadius: BorderRadius.circular(28),
                                    ),
                                  ),
                                ),
                                Center(
                                  child: Image.asset(
                                    page.imagePath,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Expanded(
                          flex: 4,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.fromLTRB(
                              AppSpacing.xl,
                              AppSpacing.xxl,
                              AppSpacing.xl,
                              AppSpacing.xl,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(
                                AppTheme.cornerRadiusLarge,
                              ),
                              boxShadow: AppTheme.cardShadow,
                            ),
                            child: Column(
                              children: [
                                Text(
                                  page.title,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  page.description,
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.textSecondary,
                                      ),
                                ),
                                const Spacer(),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(
                                    _pages.length,
                                    (index) => AnimatedContainer(
                                      duration: const Duration(milliseconds: 220),
                                      margin: const EdgeInsets.symmetric(horizontal: 4),
                                      width: _currentPage == index ? 28 : 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        color: _currentPage == index
                                            ? AppTheme.primary
                                            : AppTheme.cardBackground,
                                        borderRadius: BorderRadius.circular(
                                          AppTheme.pillRadius,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.lg),
                                XPButton(
                                  label: isLastPage ? 'Get Started' : 'Continue',
                                  icon: Icons.arrow_forward_rounded,
                                  onPressed: _nextPage,
                                ),
                                if (isLastPage) ...[
                                  const SizedBox(height: AppSpacing.md),
                                  TextButton(
                                    onPressed: _completeOnboarding,
                                    child: const Text('I already have an account'),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String description;
}
