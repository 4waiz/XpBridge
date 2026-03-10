import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class XPButton extends StatefulWidget {
  const XPButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.tonal = false,
    this.expand = true,
    this.size = XPButtonSize.medium,
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

enum XPButtonSize { small, medium, large }

class _XPButtonState extends State<XPButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;

    final height = switch (widget.size) {
      XPButtonSize.small => 44.0,
      XPButtonSize.medium => 52.0,
      XPButtonSize.large => 58.0,
    };

    final fontSize = switch (widget.size) {
      XPButtonSize.small => 14.0,
      XPButtonSize.medium => 15.0,
      XPButtonSize.large => 16.0,
    };

    final iconSize = switch (widget.size) {
      XPButtonSize.small => 18.0,
      XPButtonSize.medium => 20.0,
      XPButtonSize.large => 22.0,
    };

    final backgroundColor = widget.tonal
        ? AppTheme.primary.withValues(alpha: 0.12)
        : AppTheme.primary;

    final foregroundColor = widget.tonal ? AppTheme.primary : Colors.white;

    final button = Container(
      height: height,
      decoration: BoxDecoration(
        gradient: widget.tonal || isDisabled
            ? null
            : LinearGradient(
                colors: [AppTheme.primary, AppTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
        color: widget.tonal
            ? backgroundColor
            : isDisabled
            ? AppTheme.cardBackground
            : null,
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        boxShadow: isDisabled || widget.tonal
            ? null
            : [
                BoxShadow(
                  color: AppTheme.primary.withValues(alpha: 0.3),
                  offset: const Offset(0, 4),
                  blurRadius: 12,
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onPressed,
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(
                      widget.icon,
                      size: iconSize,
                      color: isDisabled ? AppTheme.textMuted : foregroundColor,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    widget.label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: fontSize,
                      color: isDisabled ? AppTheme.textMuted : foregroundColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    return AnimatedScale(
      scale: _pressed ? 0.97 : 1,
      duration: const Duration(milliseconds: 100),
      curve: Curves.easeOut,
      child: Listener(
        onPointerDown: (_) => setState(() => _pressed = true),
        onPointerUp: (_) => setState(() => _pressed = false),
        onPointerCancel: (_) => setState(() => _pressed = false),
        child: widget.expand
            ? SizedBox(width: double.infinity, child: button)
            : button,
      ),
    );
  }
}

// Secondary button variant
class XPOutlinedButton extends StatelessWidget {
  const XPOutlinedButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;

    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.cornerRadius),
        border: Border.all(
          color: isDisabled ? AppTheme.cardBackground : AppTheme.primary,
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppTheme.cornerRadius - 2),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.center,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 20,
                      color: isDisabled ? AppTheme.textMuted : AppTheme.primary,
                    ),
                    const SizedBox(width: 10),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: isDisabled ? AppTheme.textMuted : AppTheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
