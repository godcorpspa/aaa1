import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class GradientBackground extends StatelessWidget {
  final Widget child;
  const GradientBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(gradient: AppTheme.gradient),
        width: double.infinity,
        height: double.infinity,
        child: SafeArea(child: child),
      );
}
