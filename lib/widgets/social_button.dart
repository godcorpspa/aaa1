import 'package:flutter/material.dart';

class SocialButton extends StatelessWidget {
  final String asset;
  final VoidCallback onTap;
  const SocialButton({required this.asset, required this.onTap, super.key});

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 90,
          height: 90,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F6E8),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Image.asset(asset),
        ),
      );
}
