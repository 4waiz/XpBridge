import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class XPAiShell extends StatelessWidget {
  const XPAiShell({
    super.key,
    required this.child,
    this.showBackdropMap = false,
  });

  final Widget child;
  final bool showBackdropMap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppTheme.background),
      child: Stack(
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: const BoxDecoration(
                gradient: AppTheme.aiShellGradient,
              ),
            ),
          ),
          Positioned(
            top: -120,
            left: -80,
            right: -40,
            height: 420,
            child: _BlurOrb(
              width: 480,
              height: 380,
              color: AppTheme.primary.withValues(alpha: 0.22),
            ),
          ),
          Positioned(
            top: 220,
            right: -30,
            width: 220,
            height: 220,
            child: _BlurOrb(
              width: 220,
              height: 220,
              color: AppTheme.surface.withValues(alpha: 0.26),
            ),
          ),
          Positioned(
            bottom: -70,
            left: -40,
            width: 240,
            height: 220,
            child: _BlurOrb(
              width: 240,
              height: 220,
              color: AppTheme.primaryLight.withValues(alpha: 0.42),
            ),
          ),
          if (showBackdropMap)
            Positioned.fill(
              child: IgnorePointer(
                child: Opacity(
                  opacity: 0.32,
                  child: CustomPaint(painter: _AiMapPainter()),
                ),
              ),
            ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: const [0, 0.32, 0.78, 1],
                  colors: [
                    Colors.transparent,
                    Colors.transparent,
                    AppTheme.background.withValues(alpha: 0.38),
                    AppTheme.background.withValues(alpha: 0.92),
                  ],
                ),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _BlurOrb extends StatelessWidget {
  const _BlurOrb({
    required this.width,
    required this.height,
    required this.color,
  });

  final double width;
  final double height;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: 42, sigmaY: 42),
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class XPAiCircleActionButton extends StatelessWidget {
  const XPAiCircleActionButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 50,
    this.foregroundColor,
    this.backgroundColor,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? foregroundColor;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color:
                  backgroundColor ?? AppTheme.surface.withValues(alpha: 0.08),
              border: Border.all(
                color: AppTheme.surface.withValues(alpha: 0.26),
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 21,
              color: foregroundColor ?? AppTheme.surface,
            ),
          ),
        ),
      ),
    );
  }
}

class XPAiQuickChip extends StatelessWidget {
  const XPAiQuickChip({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              color: AppTheme.surface.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppTheme.pillRadius),
              border: Border.all(
                color: AppTheme.surface.withValues(alpha: 0.18),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 16, color: AppTheme.surface),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppTheme.surface.withValues(alpha: 0.92),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class XPAiVoiceState extends StatefulWidget {
  const XPAiVoiceState({
    super.key,
    this.status = 'Recording...',
    this.subtitle,
  });

  final String status;
  final String? subtitle;

  @override
  State<XPAiVoiceState> createState() => _XPAiVoiceStateState();
}

class _XPAiVoiceStateState extends State<XPAiVoiceState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final value = Curves.easeInOut.transform(_controller.value);
        final scale = 0.96 + (value * 0.08);
        final tilt = (value - 0.5) * 0.24;

        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Transform.rotate(
              angle: tilt,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: 160,
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _OrbLayer(
                        size: 150,
                        blur: 34,
                        color: AppTheme.primary.withValues(alpha: 0.28),
                      ),
                      Transform.translate(
                        offset: Offset(-8 * value, -12 + (value * 10)),
                        child: _OrbLayer(
                          size: 118,
                          blur: 18,
                          gradient: AppTheme.aiOrbGradient,
                        ),
                      ),
                      Transform.translate(
                        offset: Offset(18 - (value * 12), 12 * value),
                        child: _OrbLayer(
                          size: 72,
                          blur: 24,
                          color: AppTheme.surface.withValues(alpha: 0.28),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              widget.status,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: AppTheme.text,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (widget.subtitle != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                widget.subtitle!,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _OrbLayer extends StatelessWidget {
  const _OrbLayer({
    required this.size,
    required this.blur,
    this.color,
    this.gradient,
  });

  final double size;
  final double blur;
  final Color? color;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    return ImageFiltered(
      imageFilter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          gradient: gradient,
          boxShadow: gradient != null ? AppTheme.aiOrbShadow : null,
        ),
      ),
    );
  }
}

class XPAiComposer extends StatelessWidget {
  const XPAiComposer({
    super.key,
    required this.controller,
    required this.hintText,
    required this.onSend,
    required this.onPlusTap,
    required this.onMicTap,
    this.isLoading = false,
    this.isMicActive = false,
  });

  final TextEditingController controller;
  final String hintText;
  final VoidCallback onSend;
  final VoidCallback onPlusTap;
  final VoidCallback onMicTap;
  final bool isLoading;
  final bool isMicActive;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 22, sigmaY: 22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 116),
          padding: const EdgeInsets.fromLTRB(18, 16, 16, 14),
          decoration: BoxDecoration(
            color: AppTheme.aiComposerFill,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppTheme.aiComposerBorder),
            boxShadow: AppTheme.aiComposerShadow,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                textInputAction: TextInputAction.send,
                minLines: 1,
                maxLines: 4,
                onSubmitted: (_) => onSend(),
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.text,
                  height: 1.45,
                ),
                decoration: InputDecoration(
                  hintText: hintText,
                  filled: false,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isDense: true,
                  contentPadding: EdgeInsets.zero,
                  hintStyle: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppTheme.textSecondary.withValues(alpha: 0.82),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  _ComposerCircleButton(
                    icon: Icons.add_rounded,
                    onTap: onPlusTap,
                    size: 42,
                    backgroundColor: AppTheme.surface.withValues(alpha: 0.84),
                    foregroundColor: AppTheme.text,
                  ),
                  const Spacer(),
                  _ComposerCircleButton(
                    icon: Icons.mic_none_rounded,
                    onTap: onMicTap,
                    size: 42,
                    backgroundColor: isMicActive
                        ? AppTheme.primarySoft
                        : AppTheme.surface.withValues(alpha: 0.84),
                    foregroundColor: isMicActive
                        ? AppTheme.primaryDeep
                        : AppTheme.textSecondary,
                    shadow: isMicActive ? AppTheme.softGlowShadow : null,
                  ),
                  const SizedBox(width: 10),
                  _ComposerCircleButton(
                    icon: Icons.near_me_outlined,
                    onTap: isLoading ? () {} : onSend,
                    size: 44,
                    backgroundColor: null,
                    foregroundColor: AppTheme.surface,
                    gradient: AppTheme.primaryGlowGradient,
                    shadow: AppTheme.softGlowShadow,
                    child: isLoading
                        ? const Padding(
                            padding: EdgeInsets.all(11),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.surface,
                              ),
                            ),
                          )
                        : null,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ComposerCircleButton extends StatelessWidget {
  const _ComposerCircleButton({
    required this.icon,
    required this.onTap,
    required this.size,
    this.backgroundColor,
    this.foregroundColor,
    this.gradient,
    this.shadow,
    this.child,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Gradient? gradient;
  final List<BoxShadow>? shadow;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: backgroundColor,
          gradient: gradient,
          shape: BoxShape.circle,
          border: Border.all(
            color: backgroundColor == null
                ? Colors.transparent
                : AppTheme.primary.withValues(alpha: 0.08),
          ),
          boxShadow: shadow,
        ),
        child:
            child ??
            Icon(icon, size: 20, color: foregroundColor ?? AppTheme.text),
      ),
    );
  }
}

class XPAiTextBubble extends StatelessWidget {
  const XPAiTextBubble({
    super.key,
    required this.text,
    required this.isUser,
    this.isLoading = false,
  });

  final String text;
  final bool isUser;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    if (!isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isLoading)
              Text(
                'Thinking Please Wait ...',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.text.withValues(alpha: 0.78),
                  fontStyle: FontStyle.italic,
                ),
              )
            else
              Text(
                text,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppTheme.text,
                  height: 1.56,
                ),
              ),
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.72,
        ),
        margin: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: AppTheme.aiBubbleUser,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppTheme.surface.withValues(alpha: 0.42),
                ),
              ),
              child: Text(
                text,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.text,
                  height: 1.5,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class XPAiInlineActionChip extends StatelessWidget {
  const XPAiInlineActionChip({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.surface.withValues(alpha: 0.42),
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(color: AppTheme.surface.withValues(alpha: 0.52)),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.text,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class XPAiResultCardData {
  const XPAiResultCardData({
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailingLabel,
    this.onTap,
    this.backgroundColor,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final VoidCallback? onTap;
  final Color? backgroundColor;
}

class XPAiFloatingResultsDeck extends StatelessWidget {
  const XPAiFloatingResultsDeck({
    super.key,
    required this.cards,
    this.actionLabel,
    this.onActionTap,
  });

  final List<XPAiResultCardData> cards;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    if (cards.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 255,
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                color: AppTheme.surface.withValues(alpha: 0.12),
                border: Border.all(
                  color: AppTheme.surface.withValues(alpha: 0.18),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.56,
                        child: CustomPaint(painter: _AiMapPainter()),
                      ),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppTheme.surface.withValues(alpha: 0.08),
                              AppTheme.surface.withValues(alpha: 0.52),
                              AppTheme.surface.withValues(alpha: 0.88),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (actionLabel != null)
            Positioned(
              right: 14,
              top: 12,
              child: XPAiInlineActionChip(
                label: actionLabel!,
                onTap: onActionTap ?? () {},
              ),
            ),
          Positioned(
            left: 10,
            right: 10,
            bottom: 10,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: cards.take(4).map((card) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: _FloatingCard(card: card),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingCard extends StatelessWidget {
  const _FloatingCard({required this.card});

  final XPAiResultCardData card;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: card.onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            width: 168,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
            decoration: BoxDecoration(
              color:
                  card.backgroundColor ??
                  AppTheme.surface.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: AppTheme.surface.withValues(alpha: 0.54),
              ),
              boxShadow: AppTheme.softShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        card.eyebrow,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppTheme.textSecondary.withValues(alpha: 0.84),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppTheme.surface.withValues(alpha: 0.76),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_upward_rounded,
                        size: 16,
                        color: AppTheme.text,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  card.title,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.text,
                    fontSize: 22,
                    height: 1.06,
                  ),
                ),
                if (card.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    card.subtitle!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
                if (card.trailingLabel != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySoft,
                      borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                    ),
                    child: Text(
                      card.trailingLabel!,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppTheme.primaryDeep,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AiMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = AppTheme.aiLine
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    final nodePaint = Paint()
      ..color = AppTheme.surface.withValues(alpha: 0.34)
      ..style = PaintingStyle.fill;

    final paths = <Path>[
      Path()
        ..moveTo(size.width * 0.02, size.height * 0.7)
        ..quadraticBezierTo(
          size.width * 0.2,
          size.height * 0.56,
          size.width * 0.44,
          size.height * 0.62,
        )
        ..quadraticBezierTo(
          size.width * 0.68,
          size.height * 0.7,
          size.width * 0.94,
          size.height * 0.52,
        ),
      Path()
        ..moveTo(size.width * 0.16, size.height * 0.08)
        ..quadraticBezierTo(
          size.width * 0.36,
          size.height * 0.22,
          size.width * 0.34,
          size.height * 0.52,
        )
        ..quadraticBezierTo(
          size.width * 0.32,
          size.height * 0.78,
          size.width * 0.52,
          size.height * 0.94,
        ),
      Path()
        ..moveTo(size.width * 0.7, size.height * 0.08)
        ..quadraticBezierTo(
          size.width * 0.62,
          size.height * 0.34,
          size.width * 0.78,
          size.height * 0.54,
        )
        ..quadraticBezierTo(
          size.width * 0.92,
          size.height * 0.72,
          size.width * 0.82,
          size.height * 0.94,
        ),
    ];

    for (final path in paths) {
      canvas.drawPath(path, linePaint);
    }

    final gridPaint = Paint()
      ..color = AppTheme.surface.withValues(alpha: 0.16)
      ..strokeWidth = 0.8;

    for (var i = 0; i < 6; i++) {
      final dx = size.width * (0.12 + (i * 0.14));
      canvas.drawLine(
        Offset(dx, size.height * 0.08),
        Offset(dx - 14, size.height * 0.92),
        gridPaint,
      );
    }

    for (var i = 0; i < 5; i++) {
      final dy = size.height * (0.18 + (i * 0.15));
      canvas.drawLine(
        Offset(size.width * 0.04, dy),
        Offset(size.width * 0.96, dy - 12),
        gridPaint,
      );
    }

    final nodes = <Offset>[
      Offset(size.width * 0.18, size.height * 0.66),
      Offset(size.width * 0.38, size.height * 0.58),
      Offset(size.width * 0.62, size.height * 0.68),
      Offset(size.width * 0.72, size.height * 0.3),
      Offset(size.width * 0.28, size.height * 0.3),
    ];

    for (final node in nodes) {
      canvas.drawCircle(node, 7, nodePaint);
      canvas.drawCircle(
        node,
        16,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = AppTheme.surface.withValues(alpha: 0.12),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
