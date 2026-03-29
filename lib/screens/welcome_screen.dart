import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/lms_logo.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// WelcomeScreen -- landing page with logo, title, tagline and auth buttons.
class WelcomeScreen extends ConsumerWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Scaffold(
      body: GradientBackground(
        useSafeArea: true,
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 48),

                // --- Logo ---
                const LmsLogo(size: 140),

                const SizedBox(height: 40),

                // --- App title ---
                Text(
                  'LAST MAN STANDING',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),

                const SizedBox(height: 8),

                // --- Subtitle ---
                Text(
                  'Serie A Edition',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 24),

                // --- Tagline ---
                Text(
                  'Scegli la vincente, sopravvivi.\nSbaglia... e sei fuori!',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 64),

                // --- Register button ---
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const RegisterScreen(),
                      ),
                    ),
                    child: const Text('Registrati'),
                  ),
                ),

                const SizedBox(height: 16),

                // --- Login button ---
                SizedBox(
                  width: double.infinity,
                  height: AppSizes.buttonHeight,
                  child: OutlinedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                    child: const Text('Accedi'),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
