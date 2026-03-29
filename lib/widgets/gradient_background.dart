import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  final bool useSafeArea;
  final EdgeInsetsGeometry? padding;

  const GradientBackground({
    super.key,
    required this.child,
    this.useSafeArea = true,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    if (useSafeArea) {
      content = SafeArea(child: content);
    }

    return Container(
      decoration: const BoxDecoration(gradient: AppTheme.backgroundGradient),
      child: content,
    );
  }
}
