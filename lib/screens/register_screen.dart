import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../widgets/gradient_background.dart';
import '../widgets/lms_logo.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
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

  // Indicatori forza password
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_validatePasswordStrength);
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

  void _validatePasswordStrength() {
    final password = _passwordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  double get _passwordStrength {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasLowercase) score++;
    if (_hasDigit) score++;
    if (_hasSpecialChar) score++;
    return score / 5.0;
  }

  Color get _passwordStrengthColor {
    final strength = _passwordStrength;
    if (strength < 0.3) return Colors.red;
    if (strength < 0.6) return Colors.orange;
    if (strength < 0.8) return Colors.yellow;
    return Colors.green;
  }

  String get _passwordStrengthText {
    final strength = _passwordStrength;
    if (strength < 0.3) return 'Debole';
    if (strength < 0.6) return 'Media';
    if (strength < 0.8) return 'Forte';
    return 'Molto forte';
  }

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
      // Verifica se l'username è già in uso
      final usernameExists = await _checkUsernameExists(_usernameController.text.trim());
      if (usernameExists) {
        setState(() => _errorMessage = 'Username già in uso');
        return;
      }

      // Crea l'account
      final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Aggiorna il display name
      await credential.user!.updateDisplayName(_usernameController.text.trim());

      // Crea il documento utente in Firestore
      await _createUserDocument(credential.user!);

      if (!mounted) return;
      
      HapticFeedback.lightImpact();
      
      // Mostra messaggio di successo
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Registrazione completata con successo!'),
          backgroundColor: Colors.green,
        ),
      );

      // Torna alla root
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } on FirebaseAuthException catch (e) {
      HapticFeedback.heavyImpact();
      setState(() => _errorMessage = _getLocalizedErrorMessage(e.code));
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
    } catch (e) {
      return false; // In caso di errore, procedi comunque
    }
  }

  Future<void> _createUserDocument(User user) async {
    final userData = {
      'username': _usernameController.text.trim().toLowerCase(),
      'displayName': _usernameController.text.trim(),
      'email': user.email,
      'jollyLeft': 0,
      'teamsUsed': <String>[],
      'isActive': true,
      'currentStreak': 0,
      'totalWins': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    };

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .set(userData);
  }

  String _getLocalizedErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'email-already-in-use':
        return 'Email già registrata';
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

  String? _validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Username richiesto';
    }
    
    if (value.length < 3) {
      return 'Username deve essere almeno 3 caratteri';
    }
    
    if (value.length > 20) {
      return 'Username non può superare 20 caratteri';
    }
    
    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
      return 'Username può contenere solo lettere, numeri e underscore';
    }
    
    return null;
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
    
    if (value.length < 8) {
      return 'Password deve essere almeno 8 caratteri';
    }
    
    if (_passwordStrength < 0.6) {
      return 'Password troppo debole';
    }
    
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Conferma password richiesta';
    }
    
    if (value != _passwordController.text) {
      return 'Le password non coincidono';
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
                    'Crea Account',
                    style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  Text(
                    'Unisciti alla competizione',
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                      color: Colors.white70,
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Campo Username
                  TextFormField(
                    controller: _usernameController,
                    focusNode: _usernameFocus,
                    textInputAction: TextInputAction.next,
                    validator: _validateUsername,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Username',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.person_outline, color: Colors.white70),
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
                    onFieldSubmitted: (_) => _emailFocus.requestFocus(),
                  ),
                  
                  const SizedBox(height: 20),
                  
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
                    textInputAction: TextInputAction.next,
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
                    onFieldSubmitted: (_) => _confirmPasswordFocus.requestFocus(),
                  ),
                  
                  // Indicatore forza password
                  if (_passwordController.text.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _buildPasswordStrengthIndicator(),
                  ],
                  
                  const SizedBox(height: 20),
                  
                  // Campo Conferma Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    obscureText: _obscureConfirmPassword,
                    textInputAction: TextInputAction.done,
                    validator: _validateConfirmPassword,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      labelText: 'Conferma Password',
                      labelStyle: const TextStyle(color: Colors.white70),
                      prefixIcon: const Icon(Icons.lock_outline, color: Colors.white70),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                          color: Colors.white70,
                        ),
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
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
                    onFieldSubmitted: (_) => _register(),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Checkbox Termini e Condizioni
                  Row(
                    children: [
                      Checkbox(
                        value: _acceptTerms,
                        onChanged: (value) => setState(() => _acceptTerms = value ?? false),
                        fillColor: WidgetStateProperty.all(Colors.white),
                        checkColor: const Color(0xFFE64A19),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _acceptTerms = !_acceptTerms),
                          child: RichText(
                            text: const TextSpan(
                              style: TextStyle(color: Colors.white70),
                              children: [
                                TextSpan(text: 'Accetto i '),
                                TextSpan(
                                  text: 'Termini e Condizioni',
                                  style: TextStyle(
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                                TextSpan(text: ' e la '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    color: Colors.white,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ],
                            ),
                          ),
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
                  
                  // Pulsante Registrazione
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
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
                              'Registrati',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
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

  Widget _buildPasswordStrengthIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Sicurezza password: ',
                style: TextStyle(color: Colors.white.withOpacity(0.8)),
              ),
              Text(
                _passwordStrengthText,
                style: TextStyle(
                  color: _passwordStrengthColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Barra progresso
          LinearProgressIndicator(
            value: _passwordStrength,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
          ),
          
          const SizedBox(height: 12),
          
          // Criteri password
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              _buildPasswordCriterion('8+ caratteri', _hasMinLength),
              _buildPasswordCriterion('Maiuscola', _hasUppercase),
              _buildPasswordCriterion('Minuscola', _hasLowercase),
              _buildPasswordCriterion('Numero', _hasDigit),
              _buildPasswordCriterion('Carattere speciale', _hasSpecialChar),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordCriterion(String text, bool met) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: met ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: met ? Colors.green.withOpacity(0.5) : Colors.red.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            met ? Icons.check : Icons.close,
            size: 16,
            color: met ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              color: met ? Colors.green : Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}