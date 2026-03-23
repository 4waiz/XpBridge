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
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool tonal;
  final bool expand;
  final XPButtonSize size;

  @override
  State<XPButton> createState() => _XPButtonState();
}

class _XPButtonState extends State<XPButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final style = _styleForSize(widget.size);

    final button = AnimatedScale(
      scale: _pressed ? 0.985 : 1,
      duration: const Duration(milliseconds: 140),
      curve: Curves.easeOut,
      child: Container(
        height: style.height,
        decoration: BoxDecoration(
          color: isDisabled
              ? AppTheme.cardBackground
              : widget.tonal
              ? AppTheme.primaryLight
              : AppTheme.primary,
          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
          boxShadow: isDisabled || widget.tonal
              ? null
              : AppTheme.floatingShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: style.horizontalPadding,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: widget.expand
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: style.iconSize,
                      color: isDisabled ? AppTheme.textMuted : AppTheme.text,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                  Flexible(
                    child: Text(
                      widget.label,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontSize: style.fontSize,
                        fontWeight: FontWeight.w800,
                        color: isDisabled ? AppTheme.textMuted : AppTheme.text,
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
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        border: Border.all(
          color: isDisabled ? AppTheme.cardBackground : AppTheme.border,
        ),
        boxShadow: AppTheme.cardShadow,
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
                      fontWeight: FontWeight.w700,
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
