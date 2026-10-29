import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key, this.firebaseAvailable = true});

  final bool firebaseAvailable;

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isRegistering = false;
  bool _isBusy = false;
  String? _error;

  Future<void> _submit() async {
    if (!widget.firebaseAvailable) {
      setState(() => _error = 'Firebase is not configured for this build.');
      return;
    }

    setState(() {
      _isBusy = true;
      _error = null;
    });
    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      if (email.isEmpty || password.length < 6) {
        throw FirebaseAuthException(
          code: 'invalid-input',
          message: 'Enter an email and a password with 6+ characters.',
        );
      }
      if (_isRegistering) {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
    } on FirebaseAuthException catch (exception) {
      setState(() => _error = exception.message ?? 'Authentication failed.');
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = _isRegistering ? 'Join the bench.' : 'Build your setup.';
    return Scaffold(
      backgroundColor: const Color(0xFF070B18),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(28, 36, 28, 28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _BrandMark(),
                const SizedBox(height: 72),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 42,
                    fontWeight: FontWeight.w800,
                    height: .98,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _isRegistering
                      ? 'A better place for the parts you are still hunting for.'
                      : 'The trusted swap spot for your next upgrade.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .68),
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 40),
                _Input(
                  controller: _emailController,
                  label: 'EMAIL',
                  icon: Icons.alternate_email_rounded,
                ),
                const SizedBox(height: 14),
                _Input(
                  controller: _passwordController,
                  label: 'PASSWORD',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFFF9B8D)),
                    ),
                  ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: FilledButton(
                    onPressed: _isBusy ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF00D9FF),
                      foregroundColor: const Color(0xFF070B18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isBusy
                        ? const SizedBox.square(
                            dimension: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            _isRegistering ? 'CREATE ACCOUNT' : 'SIGN IN',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              letterSpacing: .7,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 22),
                Center(
                  child: TextButton(
                    onPressed: () => setState(() {
                      _isRegistering = !_isRegistering;
                      _error = null;
                    }),
                    child: Text(
                      _isRegistering
                          ? 'Already have an account? Sign in'
                          : 'New here? Create an account',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();
  @override
  Widget build(BuildContext context) => Image.asset(
    'asset/logo1.png',
    width: 260,
    height: 170,
    fit: BoxFit.contain,
    alignment: Alignment.centerLeft,
  );
}

class _Input extends StatelessWidget {
  const _Input({
    required this.controller,
    required this.label,
    required this.icon,
    this.obscureText = false,
  });
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final bool obscureText;
  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    obscureText: obscureText,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: Colors.white.withValues(alpha: .55),
        fontSize: 11,
        letterSpacing: 1.1,
      ),
      prefixIcon: Icon(icon, color: const Color(0xFF00D9FF)),
      filled: true,
      fillColor: Colors.white.withValues(alpha: .08),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withValues(alpha: .12)),
      ),
      focusedBorder: const OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(12)),
        borderSide: BorderSide(color: Color(0xFF00D9FF)),
      ),
    ),
  );
}
