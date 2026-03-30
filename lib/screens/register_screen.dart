import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../widgets/gradient_background.dart';
import '../widgets/lms_logo.dart';
import 'login_screen.dart';

/// RegisterScreen -- account creation with password strength indicator.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _usernameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _loading = false;
  bool _acceptTerms = false;
  String? _errorMessage;

  // Password strength flags
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_evaluatePasswordStrength);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------------------
  // Password strength
  // ---------------------------------------------------------------------------

  void _evaluatePasswordStrength() {
    final pw = _passwordController.text;
    setState(() {
      _hasMinLength = pw.length >= 8;
      _hasUppercase = pw.contains(RegExp(r'[A-Z]'));
      _hasLowercase = pw.contains(RegExp(r'[a-z]'));
      _hasDigit = pw.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  double get _strengthValue {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigit) score++;
    if (_hasSpecialChar) score++;
    return score / 5.0;
  }

  Color get _strengthColor {
    final s = _strengthValue;
    if (s <= 0.2) return AppTheme.errorRed;
    if (s <= 0.4) return Colors.deepOrange;
    if (s <= 0.6) return AppTheme.warningAmber;
    if (s <= 0.8) return Colors.lightGreen;
    return AppTheme.successGreen;
  }

  String get _strengthLabel {
    final s = _strengthValue;
    if (s <= 0.2) return 'Molto debole';
    if (s <= 0.4) return 'Debole';
    if (s <= 0.6) return 'Media';
    if (s <= 0.8) return 'Forte';
    return 'Molto forte';
  }

  // ---------------------------------------------------------------------------
  // Registration
  // ---------------------------------------------------------------------------

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }

    if (!_acceptTerms) {
      setState(() => _errorMessage = 'Devi accettare i termini e condizioni');
      HapticFeedback.heavyImpact();
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      // Check username uniqueness
      final usernameExists =
          await _checkUsernameExists(_usernameController.text.trim());
      if (usernameExists) {
        setState(() {
          _errorMessage = 'Username gia in uso';
          _loading = false;
        });
        return;
      }

      // Create account
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save display name
      await credential.user!
          .updateDisplayName(_usernameController.text.trim());

      // Create Firestore user document
      await _createUserDocument(credential.user!);

      if (!mounted) return;
      HapticFeedback.lightImpact();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Registrazione completata con successo!'),
          backgroundColor: AppTheme.successGreen,
        ),
      );

      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _localizedError(e.code));
    } catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = 'Errore durante la registrazione: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<bool> _checkUsernameExists(String username) async {
    try {
      final query = await FirebaseFirestore.instance
          .collection('users')
          .where('username', isEqualTo: username.toLowerCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<void> _createUserDocument(User user) async {
    final data = {
      'username': _usernameController.text.trim().toLowerCase(),
      'displayName': _usernameController.text.trim(),
      'email': user.email,
      'goldTickets': 0,
      'teamsUsed': <String>[],
      'isActive': true,
      'currentStreak': 0,
      'totalSurvivals': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(data);
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  String _localizedError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'Email gia registrata';
      case 'invalid-email':
        return 'Email non valida';
      case 'weak-password':
        return 'Password troppo debole';
      case 'operation-not-allowed':
        return 'Registrazione non consentita';
      case 'network-request-failed':
        return 'Errore di connessione';
      default:
        return 'Errore durante la registrazione';
    }
  }

  // ---------------------------------------------------------------------------
  // Validators
  // ---------------------------------------------------------------------------

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) return 'Username richiesto';
    if (value.length < 3) return 'Almeno 3 caratteri';
    if (value.length > 20) return 'Massimo 20 caratteri';
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Solo lettere, numeri e underscore';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Email richiesta';
    final regex = RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$');
    if (!regex.hasMatch(value)) return 'Email non valida';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password richiesta';
    if (value.length < 8) return 'Almeno 8 caratteri';
    if (_strengthValue < 0.6) return 'Password troppo debole';
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) return 'Conferma la password';
    if (value != _passwordController.text) return 'Le password non coincidono';
    return null;
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
                  const LmsLogo(size: 90),

                  const SizedBox(height: 28),

                  // --- Title ---
                  Text(
                    'Crea Account',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Unisciti alla competizione',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.6),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // --- Username ---
                  TextFormField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    textInputAction: TextInputAction.next,
                    validator: _validateUsername,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  ),

                  const SizedBox(height: 18),

                  // --- Email ---
                  TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                    onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  ),

                  const SizedBox(height: 18),

                  // --- Password ---
                  TextFormField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.next,
                    validator: _validatePassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outline),
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
                    onFieldSubmitted: (_) =>
                        _confirmPasswordFocus.requestFocus(),
                  ),

                  // --- Password strength indicator ---
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    _buildStrengthIndicator(theme),
                  ],

                  const SizedBox(height: 18),

                  // --- Confirm Password ---
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    validator: _validateConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Conferma Password',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                        ),
                        onPressed: () => setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        ),
                      ),
                    ),
                    onFieldSubmitted: (_) => _register(),
                  ),

                  const SizedBox(height: 20),

                  // --- Terms checkbox ---
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    onTap: () =>
                        setState(() => _acceptTerms = !_acceptTerms),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptTerms,
                              onChanged: (v) =>
                                  setState(() => _acceptTerms = v ?? false),
                              activeColor: AppTheme.primaryRed,
                              checkColor: Colors.white,
                              side: BorderSide(
                                color: Colors.white.withValues(alpha: 0.4),
                                width: 1.5,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  height: 1.4,
                                ),
                                children: const [
                                  TextSpan(text: 'Accetto i '),
                                  TextSpan(
                                    text: 'Termini e Condizioni',
                                    style: TextStyle(
                                      color: AppTheme.accentGold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  TextSpan(text: ' e la '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: TextStyle(
                                      color: AppTheme.accentGold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // --- Error banner ---
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 16),
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

                  // --- Register button ---
                  SizedBox(
                    width: double.infinity,
                    height: AppSizes.buttonHeight,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text('Registrati'),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // --- Login link ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Hai gia un account?',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.6),
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginScreen(),
                          ),
                        ),
                        child: const Text('Accedi'),
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

  // ---------------------------------------------------------------------------
  // Password strength widget
  // ---------------------------------------------------------------------------

  Widget _buildStrengthIndicator(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label + strength text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sicurezza password',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                _strengthLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: _strengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: _strengthValue,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(_strengthColor),
            ),
          ),

          const SizedBox(height: 12),

          // Criteria chips
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _criterionChip('8+ caratteri', _hasMinLength),
              _criterionChip('Maiuscola', _hasUppercase),
              _criterionChip('Minuscola', _hasLowercase),
              _criterionChip('Numero', _hasDigit),
              _criterionChip('Speciale', _hasSpecialChar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _criterionChip(String label, bool met) {
    final color = met ? AppTheme.successGreen : AppTheme.errorRed;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check_circle_outline : Icons.cancel_outlined,
            size: 14,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
