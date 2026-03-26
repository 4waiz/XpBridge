import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

enum XPButtonSize { small, medium, large }

class XPButton extends StatefulWidget {
  const XPButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tonal = false,
    this.expand = true,
    this.size = XPButtonSize.large,
    this.loading = false,
    this.backgroundColor,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool tonal;
  final bool expand;
  final XPButtonSize size;
  final bool loading;
  final Color? backgroundColor;

  @override
  State<XPButton> createState() => _XPButtonState();
}

class _XPButtonState extends State<XPButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final style = _styleForSize(widget.size);
    final foreground = widget.tonal ? AppTheme.primaryDeep : AppTheme.surface;

    final button = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Container(
        height: style.height,
        decoration: BoxDecoration(
          gradient: isDisabled
              ? null
              : widget.tonal
              ? AppTheme.whiteGlowGradient
              : widget.backgroundColor != null
                  ? null
                  : AppTheme.primaryGlowGradient,
          color: isDisabled
              ? AppTheme.primarySoft
              : widget.backgroundColor ?? (widget.tonal
              ? null
              : AppTheme.primary),
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          border: Border.all(
            color: widget.tonal
                ? AppTheme.primary.withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          boxShadow: isDisabled
              ? null
              : widget.tonal
              ? AppTheme.softShadow
              : AppTheme.softGlowShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.loading ? null : widget.onPressed,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: style.horizontalPadding,
              ),
              child: widget.loading
                  ? Center(
                      child: SizedBox(
                        width: style.iconSize,
                        height: style.iconSize,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: foreground,
                        ),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize:
                          widget.expand ? MainAxisSize.max : MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(
                            widget.icon,
                            size: style.iconSize,
                            color: isDisabled ? AppTheme.textMuted : foreground,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                        ],
                        Flexible(
                          child: Text(
                            widget.label,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge
                                ?.copyWith(
                                  fontSize: style.fontSize,
                                  color: isDisabled
                                      ? AppTheme.textMuted
                                      : foreground,
                                ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    );

    return Listener(
      onPointerDown: (_) => setState(() => _pressed = true),
      onPointerUp: (_) => setState(() => _pressed = false),
      onPointerCancel: (_) => setState(() => _pressed = false),
      child: widget.expand
          ? SizedBox(width: double.infinity, child: button)
          : button,
    );
  }
}

class XPOutlinedButton extends StatelessWidget {
  const XPOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.size = XPButtonSize.large,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;
  final XPButtonSize size;

  @override
  Widget build(BuildContext context) {
    final style = _styleForSize(size);
    final isDisabled = onPressed == null;

    final child = Container(
      height: style.height,
      decoration: BoxDecoration(
        color: AppTheme.glassStrong,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(
          color: isDisabled
              ? AppTheme.primary.withValues(alpha: 0.05)
              : AppTheme.primary.withValues(alpha: 0.12),
        ),
        boxShadow: AppTheme.glassShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: style.horizontalPadding),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  Icon(
                    icon,
                    size: style.iconSize,
                    color: isDisabled ? AppTheme.textMuted : AppTheme.text,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Flexible(
                  child: Text(
                    label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: style.fontSize,
                      color: isDisabled ? AppTheme.textMuted : AppTheme.text,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    return expand ? SizedBox(width: double.infinity, child: child) : child;
  }
}

class _ButtonStyleSpec {
  const _ButtonStyleSpec({
    required this.height,
    required this.fontSize,
    required this.iconSize,
    required this.horizontalPadding,
  });

  final double height;
  final double fontSize;
  final double iconSize;
  final double horizontalPadding;
}

_ButtonStyleSpec _styleForSize(XPButtonSize size) {
  switch (size) {
    case XPButtonSize.small:
      return const _ButtonStyleSpec(
        height: 48,
        fontSize: 14,
        iconSize: 18,
        horizontalPadding: 18,
      );
    case XPButtonSize.medium:
      return const _ButtonStyleSpec(
        height: 54,
        fontSize: 15,
        iconSize: 19,
        horizontalPadding: 22,
      );
    case XPButtonSize.large:
      return const _ButtonStyleSpec(
        height: 60,
        fontSize: 16,
        iconSize: 20,
        horizontalPadding: 24,
      );
  }
}

class XPGoogleButton extends StatelessWidget {
  const XPGoogleButton({
    super.key,
    required this.onPressed,
    this.label = 'Continue with Google',
    this.expand = true,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return XPButton(
      label: label,
      onPressed: onPressed,
      loading: loading,
      expand: expand,
      backgroundColor: Colors.white,
      tonal: true, // Use tonal style for a lighter look
    );
  }
}
