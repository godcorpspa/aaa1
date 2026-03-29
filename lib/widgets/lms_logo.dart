import 'package:flutter/material.dart';

class LmsLogo extends StatelessWidget {
  final double size;

  const LmsLogo({super.key, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo.png',
      width: size,
      height: size,
      errorBuilder: (_, __, ___) => Icon(
        Icons.sports_soccer,
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }
}
