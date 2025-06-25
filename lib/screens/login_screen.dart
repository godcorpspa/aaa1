import 'package:flutter/material.dart';
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
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  bool _obscurePwd = true;
  bool _loading = false;
  String? _error;

  Future<void> _signInEmail() async {
  setState(() => _loading = true);
  try {
    await FirebaseAuth.instance.signInWithEmailAndPassword(
      email: _email.text.trim(),
      password: _pwd.text.trim(),
    );

    // ✅ LOGIN RIUSCITO → torni alla root
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
  } on FirebaseAuthException catch (e) {
    setState(() => _error = e.message);
  } finally {
    if (mounted) setState(() => _loading = false);
  }
}

  Future<void> _signInGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;               // l’utente ha annullato

      final googleAuth = await googleUser.authentication;
      final cred = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      await FirebaseAuth.instance.signInWithCredential(cred);

      // ✅ login Google riuscito → torna alla root (AuthGate mostrerà Home)
      if (!mounted) return;
      Navigator.of(context).popUntil((route) => route.isFirst);
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message);           // mostra l’errore
    }
  }

  Future<void> _signInFacebook() async {
    final result = await FacebookAuth.instance.login();
    if (result.status != LoginStatus.success) return;
    final credential = FacebookAuthProvider.credential(result.accessToken!.tokenString);
    await FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> _signInApple() async {
    final appleCred = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email],
    );
    final oauth = OAuthProvider('apple.com').credential(
      idToken: appleCred.identityToken,
      accessToken: appleCred.authorizationCode,
    );
    await FirebaseAuth.instance.signInWithCredential(oauth);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(                       // ⬅️ aggiunto
    backgroundColor: Colors.transparent, // corpo trasparente
    body: GradientBackground(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const LmsLogo(),
              const SizedBox(height: 40),
              Text('Accedi',
                  style: Theme.of(context)
                      .textTheme
                      .displayMedium!
                      .copyWith(color: Colors.white)),
              const SizedBox(height: 30),
              TextField(
                controller: _email,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Email',
                  hintStyle: TextStyle(color: Colors.white),          // <- placeholder bianco
                  enabledBorder: OutlineInputBorder(                    // <- bordi sottili bianchi
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _pwd,
                obscureText: _obscurePwd,                   // usa il flag
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Password',
                  hintStyle: const TextStyle(color: Colors.white),
                  enabledBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white),
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),

                  // ⬇️ icona occhio / occhio barrato
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePwd ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                    ),
                    onPressed: () => setState(() => _obscurePwd = !_obscurePwd),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    // TODO: implement reset password
                  },
                  child: const Text('Hai dimenticato la password?',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
              if (_error != null)
                Text(_error!, style: const TextStyle(color: Colors.yellow)),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _loading ? null : _signInEmail,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFE64A19),
                  minimumSize: const Size(double.infinity, 54),
                ),
                child: _loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Accedi'),
              ),
              const SizedBox(height: 28),
              Row(
                children: const [
                  Expanded(child: Divider(color: Colors.white70)),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text('o accedi con',
                        style: TextStyle(color: Colors.white70)),
                  ),
                  Expanded(child: Divider(color: Colors.white70)),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SocialButton(
                    asset: 'assets/icons/google-logo.png',
                    onTap: _signInGoogle,
                  ),
                  SocialButton(
                    asset: 'assets/icons/facebook.avif',
                    onTap: _signInFacebook,
                  ),
                  SocialButton(
                    asset: 'assets/icons/apple.png',
                    onTap: _signInApple,
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
      ),
    );
  }
}
