// In login_dialog.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_management/admin/admin_app_bar.dart';
import 'package:loan_management/user/home.dart';

class LoginDialog extends StatefulWidget {
  final String? onLoginSuccessRedirectTo;

  const LoginDialog({super.key, this.onLoginSuccessRedirectTo});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  // CORRECT
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;
  bool showPwd = false;

  InputDecoration _decoration({required String label, required IconData icon}) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white70),
      prefixIcon: Icon(icon, color: Colors.white70),
      filled: true,
      fillColor: const Color(0xFF1A0F3A),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF5FB2B2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7FD0D0), width: 2),
      ),
    );
  }

  Future<void> _login() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    try {
      setState(() => loading = true);

      final credential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      final user = credential.user;
      if (user == null) {
        throw Exception("Authentication failed. Please try again.");
      }

      final doc = await FirebaseFirestore.instance
          .collection("user")
          .doc(user.uid)
          .get();

      if (!doc.exists) throw Exception("User data not found in database.");

      final data = doc.data() as Map<String, dynamic>;
      final role = data['role'] as String?;
      final userName = data['user_name'] as String?;

      if (role == null || userName == null) {
        throw Exception("User role or name is missing.");
      }

      if (mounted) {
        if (widget.onLoginSuccessRedirectTo != null) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            widget.onLoginSuccessRedirectTo!,
            (route) => false,
          );
        } else {
          if (role == 'admin') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => AdminLayout(username: userName, role: role),
              ),
              (route) => false,
            );
          } else if (role == 'staff') {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
              (route) => false,
            );
          } else {
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Login failed: ${e.toString().replaceFirst("Exception: ", "")}")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ### NEW FUNCTION ###
  // Handles the password reset logic
  Future<void> _forgotPassword() async {
    final email = emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a valid email address first.')),
      );
      return;
    }

    try {
      setState(() => loading = true);
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Password reset link sent to $email')),
        );
        Navigator.pop(context); // Close the dialog on success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }
  // ### END OF NEW FUNCTION ###

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const cardColor = Color(0xFF120834);
    const accentA = Color(0xFF7FD0D0);
    const accentB = Color(0xFFB794F4);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440),
        child: Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.5),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  gradient: LinearGradient(colors: [accentA, accentB]),
                ),
                child: Row(
                  children: const [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.black12,
                      child: Icon(Icons.lock_open, color: Colors.black87),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Sign In',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),

              // Form
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: emailController,
                        autofillHints: const [AutofillHints.email],
                        decoration:
                            _decoration(label: 'Email', icon: Icons.email),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Required';
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: passwordController,
                        autofillHints: const [AutofillHints.password],
                        obscureText: !showPwd,
                        onFieldSubmitted: (_) => loading ? null : _login(),
                        decoration: _decoration(
                          label: 'Password',
                          icon: Icons.lock,
                        ).copyWith(
                          suffixIcon: IconButton(
                            onPressed: () => setState(() => showPwd = !showPwd),
                            icon: Icon(
                              showPwd ? Icons.visibility_off : Icons.visibility,
                              color: Colors.white70,
                            ),
                          ),
                        ),
                        style: const TextStyle(color: Colors.white),
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                      const SizedBox(height: 18),

                      // Actions
                      Row(
                        children: [
                          TextButton(
                            onPressed:
                                loading ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const Spacer(),
                          SizedBox(
                            height: 44,
                            child: ElevatedButton.icon(
                              onPressed: loading ? null : _login,
                              icon: loading
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward),
                              label: Text(loading ? 'Signing in...' : 'Login'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0B0220),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 18),
                              ),
                            ),
                          ),
                        ],
                      ),
                      // ### NEW WIDGET ###
                      // Forgot Password Button
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                        child: TextButton(
                          onPressed: loading ? null : _forgotPassword,
                          child: const Text(
                            'Forgot Password?',
                            style: TextStyle(color: accentA),
                          ),
                        ),
                      ),
                      // ### END OF NEW WIDGET ###
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
