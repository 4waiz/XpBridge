import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Stack(
        children: [
          const Positioned.fill(child: _SplashBackdrop()),
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.page),
                child: Column(
                  children: [
                    const Spacer(),
                    FadeTransition(
                      opacity: animation,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.08),
                          end: Offset.zero,
                        ).animate(animation),
                        child: Column(
                          children: [
                            Container(
                              width: 112,
                              height: 112,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.cornerRadiusLarge,
                                ),
                                boxShadow: AppTheme.elevatedShadow,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.cornerRadiusLarge,
                                ),
                                child: Image.asset(
                                  'assets/image.png',
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            Text(
                              'XPBridge',
                              style: Theme.of(context).textTheme.displayMedium
                                  ?.copyWith(fontWeight: FontWeight.w800),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.lg,
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
                                'Learn. Build. Grow.',
                                style: Theme.of(context).textTheme.labelLarge
                                    ?.copyWith(color: AppTheme.textSecondary),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.4, 1, curve: Curves.easeIn),
                      ),
                      child: const SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(strokeWidth: 3),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SplashBackdrop extends StatelessWidget {
  const _SplashBackdrop();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _SplashBackdropPainter());
  }
}

class _SplashBackdropPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final tealPaint = Paint()
      ..color = AppTheme.primary.withValues(alpha: 0.08)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    final neutralPaint = Paint()
      ..color = AppTheme.text.withValues(alpha: 0.04)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 90);

    canvas.drawCircle(
      Offset(size.width * 0.25, size.height * 0.22),
      120,
      tealPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.78, size.height * 0.3),
      100,
      neutralPaint,
    );
    canvas.drawCircle(
      Offset(size.width * 0.55, size.height * 0.78),
      140,
      tealPaint,
    );

    final dotPaint = Paint()..color = AppTheme.border;
    for (double x = 24; x < size.width; x += 34) {
      for (double y = 24; y < size.height; y += 34) {
        canvas.drawCircle(Offset(x, y), 1.2, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
