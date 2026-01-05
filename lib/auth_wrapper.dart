import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_managementapp/admin/admin_app_bar.dart'; // Make sure this path is correct for AdminLayout
import 'package:loan_managementapp/user/home.dart'; // Make sure this path is correct for HomePage

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    _redirectUser();
  }

  Future<void> _redirectUser() async {
    // A short delay helps prevent screen flicker during the check.
    await Future.delayed(const Duration(milliseconds: 50));

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return;

    if (user == null) {
      // No user is logged in, go to the public home page.
      Navigator.pushReplacementNamed(context, '/home');
      return;
    }

    // A user is logged in, so we check their role.
    try {
      final doc = await FirebaseFirestore.instance
          .collection("user")
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final role = doc.data()?['role'];
        final username = doc.data()?['user_name'] ?? 'Admin';

        if (role == 'admin') {
          // The user is an admin, navigate to the AdminLayout.
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminLayout(username: username, role: role),
            ),
          );
        } else {
          // The user is a staff or other role, go to the standard home page.
          Navigator.pushReplacementNamed(context, '/home');
        }
      } else {
        // The user exists in Auth, but not in our database. Log them out and go home.
        await FirebaseAuth.instance.signOut();
        Navigator.pushReplacementNamed(context, '/home');
      }
    } catch (e) {
      // If there's an error, default to the home page.
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show a loading screen while we check the authentication state.
    return const Scaffold(
      backgroundColor: Color(0xFF1E3A8A), // Matches your admin theme
      body: Center(child: CircularProgressIndicator(color: Colors.white)),
    );
  }
}
