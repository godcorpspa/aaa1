import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SocialButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? iconColor;
  final VoidCallback onPressed;
  final bool isLoading;

  const SocialButton({
    super.key,
    required this.label,
    required this.icon,
    this.iconColor,
    required this.onPressed,
    this.isLoading = false,
  });

  factory SocialButton.google({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialButton(
      label: 'Google',
      icon: Icons.g_mobiledata,
      iconColor: const Color(0xFFDB4437),
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  factory SocialButton.apple({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialButton(
      label: 'Apple',
      icon: Icons.apple,
      iconColor: Colors.white,
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  factory SocialButton.facebook({
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return SocialButton(
      label: 'Facebook',
      icon: Icons.facebook,
      iconColor: const Color(0xFF1877F2),
      onPressed: onPressed,
      isLoading: isLoading,
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.15)),
          backgroundColor: AppTheme.surfaceCard,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, color: iconColor, size: 28),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
