import 'package:flutter/material.dart';

import 'xp_app_bar.dart';
import 'xp_premium.dart';

class XPPageScaffold extends StatelessWidget {
  const XPPageScaffold({
    super.key,
    required this.body,
    this.title,
    this.subtitle,
    this.trailing,
    this.bottomBar,
    this.showBack = false,
    this.onBack,
    this.compact = false,
  });

  final Widget body;
  final String? title;
  final String? subtitle;
  final Widget? trailing;
  final Widget? bottomBar;
  final bool showBack;
  final VoidCallback? onBack;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: XPScene(
        compact: compact,
        child: SafeArea(
          child: Column(
            children: [
              if (title != null)
                XPAppBar(
                  title: title!,
                  subtitle: subtitle,
                  trailing: trailing,
                  showBack: showBack,
                  onBack: onBack,
                ),
              Expanded(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1120),
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: bottomBar,
    );
  }
}
