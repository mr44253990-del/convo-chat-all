import 'package:flutter/material.dart';

import '../../core/app_config.dart';
import '../../state/auth_controller.dart';
import '../theme.dart';

/// Port of ui/AuthScreen.kt (email/password track). Google sign-in and phone
/// OTP are documented desktop limitations — see docs/desktop-feature-parity.md.
class AuthScreen extends StatefulWidget {
  final AuthController auth;
  const AuthScreen({super.key, required this.auth});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool registerMode = false;

  @override
  Widget build(BuildContext context) {
    final auth = widget.auth;
    final error = auth.error;
    return Scaffold(
      backgroundColor: Aurora.ink950,
      body: Center(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Card(
              color: Aurora.ink900,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(color: Aurora.violet.withOpacity(.2)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(36),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Image.asset("assets/convo_icon.png",
                            height: 96, width: 96, fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        AppConfig.appName,
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                      ),
                      Center(
                        child: Text(
                          registerMode ? "Create your account" : "Welcome back",
                          style: TextStyle(color: Aurora.mist700),
                        ),
                      ),
                      const SizedBox(height: 24),
                      if (registerMode) ...[
                        TextFormField(
                          controller: _name,
                          decoration: const InputDecoration(
                              hintText: "Full name", labelText: "Full name"),
                          validator: (v) => (v == null || v.trim().isEmpty)
                              ? "Enter your name"
                              : null,
                        ),
                        const SizedBox(height: 14),
                      ],
                      TextFormField(
                        controller: _email,
                        decoration: const InputDecoration(
                            hintText: "Email", labelText: "Email"),
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) =>
                            (v == null || !v.contains("@")) ? "Enter a valid email" : null,
                      ),
                      const SizedBox(height: 14),
                      TextFormField(
                        controller: _pass,
                        obscureText: true,
                        decoration: const InputDecoration(
                            hintText: "Password", labelText: "Password"),
                        validator: (v) =>
                            (v == null || v.length < 6) ? "At least 6 characters" : null,
                      ),
                      if (error != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(error,
                              style: const TextStyle(
                                  color: Color(0xFFFF5C5C), fontSize: 13)),
                        ),
                      const SizedBox(height: 18),
                      ElevatedButton(
                        onPressed: auth.busy ? null : _submit,
                        child: Text(
                            auth.busy ? "Please wait…" : registerMode ? "Sign up" : "Sign in"),
                      ),
                      const SizedBox(height: 4),
                      TextButton(
                        onPressed: () => setState(() => registerMode = !registerMode),
                        child: Text(registerMode
                            ? "I already have an account"
                            : "Create a new account"),
                      ),
                      TextButton(
                        onPressed: _forgot,
                        child: const Text("Forgot password?"),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final auth = widget.auth;
    final ok = registerMode
        ? await auth.signUp(_email.text, _pass.text, _name.text)
        : await auth.signIn(_email.text, _pass.text);
    if (ok) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Sign-in failed")));
  }

  Future<void> _forgot() async {
    if (_email.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Enter your email first")));
      return;
    }
    try {
      await widget.auth.sendPasswordReset(_email.text);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Password reset email sent")));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("$e")));
      }
    }
  }
}
