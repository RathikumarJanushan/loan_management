import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_management/user/Debtor.dart'; // Ensure this path is correct
import '../login_dialog.dart'; // Ensure this path is correct

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  User? user;
  String? username;
  String? role;
  late StreamSubscription<User?> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription =
        FirebaseAuth.instance.authStateChanges().listen((User? authUser) {
      if (mounted) {
        setState(() {
          user = authUser;
        });
        if (authUser != null) {
          _fetchUserData(authUser.uid);
        } else {
          setState(() {
            username = null;
            role = null;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  Future<void> _fetchUserData(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection("user").doc(uid).get();
      if (doc.exists && mounted) {
        setState(() {
          username = doc.data()?['user_name'];
          role = doc.data()?['role'];
        });
      }
    } catch (e) {
      debugPrint("Error fetching user data: $e");
    }
  }

  // ▼▼▼ UPDATED METHOD ▼▼▼
  // Now accepts an optional 'redirectTo' parameter to pass to the LoginDialog.
  Future<void> _openLogin({String? redirectTo}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => LoginDialog(onLoginSuccessRedirectTo: redirectTo),
    );
  }
  // ▲▲▲ UPDATED METHOD ▲▲▲

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0B0220),
      elevation: 0,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: PopupMenuButton<String>(
          tooltip: 'Menu',
          offset: const Offset(0, 48),
          // ▼▼▼ UPDATED NAVIGATION LOGIC ▼▼▼
          onSelected: (value) {
            // Check if user is logged in
            if (user == null) {
              // If not logged in, show login dialog with a redirect path
              if (value == 'register' || value == 'debtor') {
                _openLogin(redirectTo: '/$value'); // Pass '/register' or '/debtor'
              } else if (value == 'home') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (r) => false);
              }
            } else {
              // If logged in, navigate directly
              if (value == 'home') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (r) => false);
              } else if (value == 'register') {
                Navigator.pushNamed(context, '/register');
              } else if (value == 'debtor') {
                // Assuming '/debtor' is a named route in your MaterialApp
                Navigator.pushNamed(context, '/debtor');
              }
            }
          },
          // ▲▲▲ UPDATED NAVIGATION LOGIC ▲▲▲
          itemBuilder: (context) => const [
            PopupMenuItem(
              value: 'home',
              child: ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
              ),
            ),
            PopupMenuItem(
              value: 'register',
              child: ListTile(
                leading: Icon(Icons.app_registration),
                title: Text('Register'),
              ),
            ),
            PopupMenuItem(
              value: 'debtor',
              child: ListTile(
                leading: Icon(Icons.payment),
                title: Text('Pay Debtor'),
              ),
            ),
          ],
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(Icons.menu, color: Colors.white),
          ),
        ),
      ),
      title: ShaderMask(
        shaderCallback: (r) => const LinearGradient(
          colors: [Color(0xFF7FD0D0), Color(0xFFB794F4)],
        ).createShader(r),
        child: const Text(
          "– Inc.",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
      ),
      centerTitle: false,
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text("Solutions", style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("About", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        if (user == null)
          ElevatedButton(
            onPressed: _openLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
            ),
            child: Row(
              children: const [
                Text("Sign In"),
                SizedBox(width: 5),
                Icon(Icons.arrow_forward, size: 16)
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "logout") _logout();
              },
              itemBuilder: (context) => [
                if (role != null)
                  PopupMenuItem<String>(
                    value: "role",
                    enabled: false,
                    child: Text(
                        "Role: ${role![0].toUpperCase()}${role!.substring(1)}"), // Capitalized role
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: "logout",
                  child: Text("Logout"),
                ),
              ],
              child: Row(
                children: [
                  Text(
                    username ?? user!.email ?? "User",
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white),
                ],
              ),
            ),
          ),
      ],
      bottom: const PreferredSize(
        preferredSize: Size.fromHeight(1),
        child: Divider(height: 1, color: Colors.white24),
      ),
    );
  }
}