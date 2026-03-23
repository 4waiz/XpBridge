import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
      title: 'The Experience Gap',
      highlightedText: null,
      description:
          'Breaking into the professional world is tough. You need experience to get a job, but need a job to get experience.',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pc.png',
      title: 'Your Bridge to the',
      highlightedText: 'Real World',
      description:
          'Stop waiting for graduation. Start building your CV today with micro-projects designed for learning.',
    ),
    _OnboardingPage(
      imagePath: 'assets/illustrations/pa.png',
      title: 'Unlock Your',
      highlightedText: 'Potential',
      description:
          'Turn micro-projects into a verified portfolio. Gain the skills startups want and prove you\'re ready for the real world.',
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
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLastPage = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isCompactWidth = constraints.maxWidth < 360;
                final isCompactHeight = constraints.maxHeight < 700;
                final isTinyHeight = constraints.maxHeight < 580;
                final isUltraTinyHeight = constraints.maxHeight < 350; // New threshold for extreme resize
                final horizontalPadding = isCompactWidth ? 16.0 : 20.0;
                final bottomPadding = isCompactWidth ? 16.0 : 24.0;
                final pageIndicatorSpacing = isTinyHeight ? 12.0 : (isCompactHeight ? 16.0 : 24.0);

                // Use scrollable layout for extreme constraints to avoid vertical overflow
                if (isUltraTinyHeight) {
                  return SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        const SizedBox(height: 16),
                        // Fixed height for PageView in scroll mode
                        SizedBox(
                          height: 240, 
                          child: PageView.builder(
                            controller: _pageController,
                            onPageChanged: (index) {
                              setState(() => _currentPage = index);
                            },
                            itemCount: _pages.length,
                            itemBuilder: (context, index) {
                              final page = _pages[index];
                              return _buildPage(page);
                            },
                          ),
                        ),
                        _buildBottomSection(
                          isTinyHeight: true,
                          isCompactWidth: isCompactWidth,
                          bottomPadding: bottomPadding,
                          pageIndicatorSpacing: pageIndicatorSpacing,
                        ),
                      ],
                    ),
                  );
                }

                return Column(
                  children: [
                    if (!isTinyHeight)
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: horizontalPadding,
                          vertical: isCompactHeight ? 4 : 12,
                        ),
                        child: SizedBox(
                          width: constraints.maxWidth - (horizontalPadding * 2),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.center,
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.cardBackground,
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    '${_currentPage + 1} / ${_pages.length}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppTheme.textSecondary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: isCompactWidth ? 100 : 160),
                                const SizedBox(width: 60),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      const SizedBox(height: 8),
                    Expanded(
                      child: PageView.builder(
                        controller: _pageController,
                        onPageChanged: (index) {
                          setState(() => _currentPage = index);
                        },
                        itemCount: _pages.length,
                        itemBuilder: (context, index) {
                          final page = _pages[index];
                          return _buildPage(page);
                        },
                      ),
                    ),
                    _buildBottomSection(
                      isTinyHeight: isTinyHeight,
                      isCompactWidth: isCompactWidth,
                      bottomPadding: bottomPadding,
                      pageIndicatorSpacing: pageIndicatorSpacing,
                    ),
                  ],
                );
              },
            ),
            Positioned(
              top: 8,
              right: 8,
              child: PopupMenuButton<UserRole>(
                onSelected: (role) async {
                  final appState = AppStateScope.of(context);
                  final prefs = await SharedPreferences.getInstance();
                  
                  await prefs.setBool('is_logged_in', true);
                  await prefs.setString('user_role', role == UserRole.student ? 'student' : 'startup');
                  
                  if (role == UserRole.student) {
                    if (prefs.getString('profile_name') == null) {
                      await prefs.setString('profile_name', 'Demo Student');
                      await prefs.setString('user_email', 'student@demo.com');
                      await prefs.setStringList('profile_skills', ['Flutter', 'Dart', 'Design']);
                    }
                  } else {
                    if (prefs.getString('startup_name') == null) {
                      await prefs.setString('startup_name', 'Demo Startup');
                      await prefs.setString('user_email', 'startup@demo.com');
                    }
                  }

                  await appState.loadUserSession();
                  
                  if (mounted) {
                    if (role == UserRole.student) {
                      context.goNamed('studentDashboard');
                    } else {
                      context.goNamed('startupDashboard');
                    }
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: UserRole.student,
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, color: AppTheme.primary, size: 20),
                        SizedBox(width: 12),
                        Text('Skip as Student'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: UserRole.startup,
                    child: Row(
                      children: [
                        Icon(Icons.business_outlined, color: AppTheme.primary, size: 20),
                        SizedBox(width: 12),
                        Text('Skip as Startup'),
                      ],
                    ),
                  ),
                ],
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Skip',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.primary, size: 18),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSection({
    required bool isTinyHeight,
    required bool isCompactWidth,
    required double bottomPadding,
    required double pageIndicatorSpacing,
  }) {
    final isLastPage = _currentPage == _pages.length - 1;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        bottomPadding,
        isTinyHeight ? 12 : bottomPadding,
        bottomPadding,
        isTinyHeight ? 16 : bottomPadding,
      ),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(isCompactWidth ? 24 : 32),
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.text.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: pageIndicatorSpacing),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 28 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      gradient: _currentPage == index
                          ? LinearGradient(
                              colors: [
                                AppTheme.primary,
                                AppTheme.primaryDark,
                              ],
                            )
                          : null,
                      color: _currentPage == index ? null : AppTheme.cardBackground,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
            ),
          ),
          XPButton(
            label: isLastPage ? 'Start Your Journey' : 'Next',
            icon: Icons.arrow_forward_rounded,
            onPressed: isLastPage ? _completeOnboarding : _nextPage,
            size: isCompactWidth || isTinyHeight ? XPButtonSize.small : XPButtonSize.medium,
          ),
          if (isLastPage && !isTinyHeight) ...[
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                Text(
                  'Already have an account?',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.textSecondary),
                ),
                GestureDetector(
                  onTap: _completeOnboarding,
                  child: const Text(
                    'Log In',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompactWidth = constraints.maxWidth < 360;
        final isCompactHeight = constraints.maxHeight < 560;
        final titleFontSize = isCompactWidth ? 26.0 : 32.0;
        final descriptionFontSize = isCompactWidth ? 15.0 : 16.0;
        final topSpacing = isCompactHeight ? 12.0 : 20.0;
        final sectionSpacing = isCompactHeight ? 20.0 : 32.0;
        final textSpacing = isCompactHeight ? 12.0 : 16.0;
        final horizontalPadding = isCompactWidth ? 16.0 : 24.0;
        final imageHeight =
            (constraints.maxHeight * (isCompactHeight ? 0.32 : 0.42))
                .clamp(140.0, 300.0)
                .toDouble();

        final titleStyle = TextStyle(
          fontSize: titleFontSize,
          fontWeight: FontWeight.w800,
          color: AppTheme.text,
          height: 1.2,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.zero,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                topSpacing,
                horizontalPadding,
                16,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(
                    height: imageHeight,
                    child: Center(
                      child: Image.asset(page.imagePath, fit: BoxFit.contain),
                    ),
                  ),
                  SizedBox(height: sectionSpacing),
                  Align(
                    alignment: Alignment.center,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 520),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (page.highlightedText != null)
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: RichText(
                                textAlign: TextAlign.center,
                                text: TextSpan(
                                  style: titleStyle,
                                  children: [
                                    TextSpan(text: '${page.title}\n'),
                                    TextSpan(
                                      text: page.highlightedText,
                                      style: const TextStyle(
                                        color: AppTheme.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                page.title,
                                textAlign: TextAlign.center,
                                style: titleStyle,
                              ),
                            ),
                          SizedBox(height: textSpacing),
                          Text(
                            page.description,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: descriptionFontSize,
                              color: AppTheme.textSecondary,
                              height: isCompactHeight ? 1.45 : 1.6,
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
        );
      },
    );
  }
}

class _OnboardingPage {
  const _OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.highlightedText,
    required this.description,
  });

  final String imagePath;
  final String title;
  final String? highlightedText;
  final String description;
}
