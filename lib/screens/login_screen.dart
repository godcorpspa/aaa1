import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/lms_logo.dart';
import '../widgets/social_button.dart';
import 'register_screen.dart';

/// LoginScreen -- email/password sign-in with social login options.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Auth methods
  // ---------------------------------------------------------------------------

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _localizedError(e.code));
    } catch (_) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Errore di connessione. Riprova.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _localizedError(e.code));
    } catch (_) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Errore nell\'accesso con Google');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithFacebook() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final result = await FacebookAuth.instance.login();
      if (result.status != LoginStatus.success) {
        setState(() => _loading = false);
        return;
      }

      final credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _localizedError(e.code));
    } catch (_) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Errore nell\'accesso con Facebook');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final oauthCredential = OAuthProvider('apple.com').credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      if (!mounted) return;
      HapticFeedback.lightImpact();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _localizedError(e.code));
    } catch (_) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Errore nell\'accesso con Apple');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(
        () => _errorMessage = 'Inserisci la tua email per il reset della password',
      );
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Email di reset inviata. Controlla la tua casella di posta.',
          ),
          backgroundColor: AppTheme.successGreen,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _localizedError(e.code));
    }
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _localizedError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'Nessun utente trovato con questa email';
      case 'wrong-password':
        return 'Password non corretta';
      case 'invalid-email':
        return 'Email non valida';
      case 'user-disabled':
        return 'Account disabilitato';
      case 'too-many-requests':
        return 'Troppi tentativi. Riprova piu tardi';
      case 'invalid-credential':
        return 'Credenziali non valide';
      case 'network-request-failed':
        return 'Errore di connessione';
      default:
        return 'Errore durante l\'accesso';
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email richiesta';
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Email non valida';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password richiesta';
    if (value.length < 6) return 'La password deve avere almeno 6 caratteri';
    return null;
  }

  // ---------------------------------------------------------------------------
  // Reusable input decoration
  // ---------------------------------------------------------------------------

  InputDecoration _inputDecoration({
    required String label,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(prefixIcon),
      suffixIcon: suffixIcon,
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: GradientBackground(
        useSafeArea: false,
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 16),

                  // --- Logo ---
                  const LmsLogo(size: 100),

                  const SizedBox(height: 32),

                  // --- Title ---
                  Text(
                    'Bentornato',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Accedi al tuo account',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // --- Email ---
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Email',
                      prefixIcon: Icons.email_outlined,
                    ),
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),

                  const SizedBox(height: 20),

                  // --- Password ---
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDecoration(
                      label: 'Password',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    onFieldSubmitted: (_) => _signInWithEmail(),
                  ),

                  const SizedBox(height: 12),

                  // --- Forgot password ---
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _resetPassword,
                      child: const Text('Password dimenticata?'),
                    ),
                  ),

                  // --- Error banner ---
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppTheme.errorRed.withValues(alpha: 0.12),
                        border: Border.all(
                          color: AppTheme.errorRed.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: AppTheme.errorRed,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: AppTheme.errorRed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 28),

                  // --- Login button ---
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signInWithEmail,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Accedi'),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Divider ---
                  Row(
                    children: [
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'oppure continua con',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Divider(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // --- Social buttons ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialButton.google(
                        onPressed: _signInWithGoogle,
                        isLoading: _loading,
                      ),
                      const SizedBox(width: 16),
                      SocialButton.facebook(
                        onPressed: _signInWithFacebook,
                        isLoading: _loading,
                      ),
                      if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                        const SizedBox(width: 16),
                        SocialButton.apple(
                          onPressed: _signInWithApple,
                          isLoading: _loading,
                        ),
                      ],
                    ],
                  ),

                  const SizedBox(height: 36),

                  // --- Register link ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Non hai un account?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        ),
                        child: const Text('Registrati'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
