import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State<LoginDialog> createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool loading = false;

  Future<void> _login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text.trim();

    try {
      setState(() => loading = true);

      // Step 1: get user doc by username (doc ID)
      final doc = await FirebaseFirestore.instance
          .collection("user")
          .doc(username)
          .get();

      if (!doc.exists) {
        throw Exception("Username not found");
      }

      final email = doc["mail"];

      // Step 2: authenticate with Firebase Auth
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (context.mounted) Navigator.pop(context, username); // return username
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Sign In"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: usernameController,
            decoration: const InputDecoration(labelText: "Username"),
          ),
          TextField(
            controller: passwordController,
            decoration: const InputDecoration(labelText: "Password"),
            obscureText: true,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: loading ? null : _login,
          child:
              loading ? const CircularProgressIndicator() : const Text("Login"),
        ),
      ],
    );
  }
}
