import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'debtor_dashboard.dart'; // Import the new dashboard

class DebtorSignInPage extends StatefulWidget {
  const DebtorSignInPage({super.key});

  @override
  State<DebtorSignInPage> createState() => _DebtorSignInPageState();
}

class _DebtorSignInPageState extends State<DebtorSignInPage> {
  final _icController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  InputDecoration _dec(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        prefixIcon: Icon(icon, color: Colors.white54),
        filled: true,
        fillColor: Colors.white.withOpacity(0.1),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Colors.white24),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF7FD0D0), width: 2),
        ),
        suffixIcon: label == 'Password'
            ? IconButton(
                icon: Icon(
                  _obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.white54,
                ),
                onPressed: () => setState(() => _obscureText = !_obscureText),
              )
            : null,
      );

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _login() async {
    final ic = _icController.text.trim();
    final password = _passwordController.text.trim();

    if (ic.isEmpty || password.isEmpty) return;

    setState(() => _isLoading = true);

    try {
      // 1. Get ALL documents for this IC (Removed limit(1))
      final qs = await FirebaseFirestore.instance
          .collection('userloneregister')
          .where('icNo', isEqualTo: ic)
          .get();

      if (qs.docs.isEmpty) throw 'User not found.';

      // 2. Verify Password
      // We check if the password matches ANY of the loan documents for this IC.
      // This allows access if the user has set a password on at least one application.
      bool isAuthorized = false;
      final inputHash = _hashPassword(password);

      for (var doc in qs.docs) {
        final storedHash = doc.data()['password'];
        if (storedHash != null && storedHash == inputHash) {
          isAuthorized = true;
          break;
        }
      }

      if (isAuthorized) {
        if (mounted) {
          // Navigate to the Dashboard, passing the IC to fetch all loans
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DebtorDashboard(icNo: ic),
            ),
          );
        }
      } else {
        throw 'Invalid password.';
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B0220),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFF120834),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.person_pin,
                    size: 60, color: Color(0xFF7FD0D0)),
                const SizedBox(height: 20),
                Text(
                  'Debtor Portal',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    foreground: Paint()
                      ..shader = const LinearGradient(
                              colors: [Color(0xFF7FD0D0), Color(0xFFB794F4)])
                          .createShader(const Rect.fromLTWH(0, 0, 200, 30)),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign in to manage your loans.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white54, fontSize: 13),
                ),
                const SizedBox(height: 30),
                TextField(
                  controller: _icController,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('IC Number', Icons.credit_card),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _passwordController,
                  obscureText: _obscureText,
                  style: const TextStyle(color: Colors.white),
                  decoration: _dec('Password', Icons.lock_outline),
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7FD0D0),
                      foregroundColor: const Color(0xFF0B0220),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Access Account',
                            style: TextStyle(fontWeight: FontWeight.bold)),
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
