import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../widgets/gradient_background.dart';
import '../widgets/lms_logo.dart';
import '../widgets/social_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  
  bool _obscurePassword = true;
  bool _loading = false;
  String? _errorMessage;
  bool _rememberMe = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

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
      
      // Feedback tattile per successo
      HapticFeedback.lightImpact();
      
      // Torna alla root
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _getLocalizedErrorMessage(e.code));
    } catch (e) {
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
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _loading = false);
        return; // L'utente ha annullato
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
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
      setState(() => _errorMessage = _getLocalizedErrorMessage(e.code));
    } catch (e) {
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
      final LoginResult result = await FacebookAuth.instance.login();
      
      if (result.status != LoginStatus.success) {
        setState(() => _loading = false);
        return;
      }

      final OAuthCredential credential = FacebookAuthProvider.credential(
        result.accessToken!.tokenString,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      if (!mounted) return;
      
      HapticFeedback.lightImpact();
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _getLocalizedErrorMessage(e.code));
    } catch (e) {
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

      final oauthCredential = OAuthProvider("apple.com").credential(
        idToken: appleCredential.identityToken,
        accessToken: appleCredential.authorizationCode,
      );

      await FirebaseAuth.instance.signInWithCredential(oauthCredential);

      if (!mounted) return;
      
      HapticFeedback.lightImpact();
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _getLocalizedErrorMessage(e.code));
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Errore nell\'accesso con Apple');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Inserisci la tua email per il reset della password');
      return;
    }

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email di reset inviata. Controlla la tua casella di posta.'),
          backgroundColor: Colors.green,
        ),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _getLocalizedErrorMessage(e.code));
    }
  }

  String _getLocalizedErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'user-not-found':
        return 'Nessun utente trovato con questa email';
      case 'wrong-password':
        return 'Password non corretta';
      case 'invalid-email':
        return 'Email non valida';
      case 'user-disabled':
        return 'Account disabilitato';
      case 'too-many-requests':
        return 'Troppi tentativi. Riprova più tardi';
      case 'invalid-credential':
        return 'Credenziali non valide';
      case 'network-request-failed':
        return 'Errore di connessione';
      default:
        return 'Errore durante l\'accesso';
    }
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email richiesta';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Email non valida';
    }
    
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password richiesta';
    }
    
    if (value.length < 6) {
      return 'Password deve essere almeno 6 caratteri';
    }
    
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      extendBodyBehindAppBar: true,
      body: GradientBackground(
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const LmsLogo(size: 100),
                  const SizedBox(height: 40),
                  
                  Text(
                    'Bentornato',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    'Accedi al tuo account',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Campo Email
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.email_outlined, color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Campo Password
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: _validatePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white38),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white, width: 2),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red, width: 2),
                      ),
                      filled: true,
                      fillColor: Colors.white.withOpacity(0.1),
                    ),
                    onFieldSubmitted: (_) => _signInWithEmail(),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Remember me e Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            onChanged: (value) => setState(() => _rememberMe = value ?? false),
                            fillColor: WidgetStateProperty.all(Colors.white),
                            checkColor: const Color(0xFFE64A19),
                          ),
                          const Text(
                            'Ricordami',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: _resetPassword,
                        child: const Text(
                          'Password dimenticata?',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  
                  // Pulsante Login
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _signInWithEmail,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE64A19),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Accedi',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Divider
                  Row(
                    children: [
                      const Expanded(child: Divider(color: Colors.white38)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'oppure continua con',
                          style: TextStyle(color: Colors.white.withOpacity(0.7)),
                        ),
                      ),
                      const Expanded(child: Divider(color: Colors.white38)),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Social Login Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      SocialButton(
                        asset: 'assets/icons/google-logo.png',
                        onTap: _loading ? () {} : _signInWithGoogle,
                      ),
                      SocialButton(
                        asset: 'assets/icons/facebook.avif',
                        onTap: _loading ? () {} : _signInWithFacebook,
                      ),
                      if (Theme.of(context).platform == TargetPlatform.iOS)
                        SocialButton(
                          asset: 'assets/icons/apple.png',
                          onTap: _loading ? () {} : _signInWithApple,
                        ),
                    ],
                  ),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}