import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/lms_logo.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';

/// ---------------------------------------------------------------------------
///  WelcomeScreen – schermata iniziale con logo, testo di benvenuto e due
///  pulsanti che rimandano alle schermate di Login e Registrazione.
/// ---------------------------------------------------------------------------
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppTheme.gradient),
        width: double.infinity,
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const LmsLogo(),
                  const SizedBox(height: 60),

                  // ─── Benvenuto ───
                  Text(
                    'Benvenuto',
                    style: theme.textTheme.displayLarge!
                        .copyWith(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  Text(
                     'Indovina la vincente, sopravvivi. \nSbaglia... e sei fuori!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyLarge!.copyWith(color: Colors.white),
                  ),

                  const SizedBox(height: 80),

                  // ─── Pulsante REGISTRATI ───
                  SizedBox(
                    width: 260,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE64A19),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const RegisterScreen()),
                      ),
                      child: const Text('Registrati', style: TextStyle(fontSize: 18)),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // ─── Pulsante ACCEDI ───
                  SizedBox(
                    width: 260,
                    height: 56,
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white, width: 2),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      ),
                      child: const Text('Accedi', style: TextStyle(fontSize: 18)),
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
