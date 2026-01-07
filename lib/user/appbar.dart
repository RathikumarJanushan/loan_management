import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../login_dialog.dart'; // Keep this for Staff Login only

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

  // This opens the Pop-up Dialog (For Staff Only)
  Future<void> _openLogin({String? redirectTo}) async {
    await showDialog<void>(
      context: context,
      builder: (context) => LoginDialog(onLoginSuccessRedirectTo: redirectTo),
    );
  }

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
          onSelected: (value) {
            if (user == null) {
              if (value == 'home') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (r) => false);
              } else {
                // If trying to access protected pages, prompt Staff Login dialog
                _openLogin(redirectTo: '/$value');
              }
            } else {
              if (value == 'home') {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/home', (r) => false);
              } else if (value == 'register') {
                Navigator.pushNamed(context, '/register');
              } else if (value == 'view_status') {
                Navigator.pushNamed(context, '/view_status');
              } else if (value == 'debtor') {
                Navigator.pushNamed(context, '/debtor');
              } else if (value == 'create_user') {
                Navigator.pushNamed(context, '/create_user');
              }
            }
          },
          itemBuilder: (context) => const [
            PopupMenuItem(
                value: 'home',
                child:
                    ListTile(leading: Icon(Icons.home), title: Text('Home'))),
            PopupMenuItem(
                value: 'register',
                child: ListTile(
                    leading: Icon(Icons.app_registration),
                    title: Text('Register'))),
            PopupMenuItem(
                value: 'view_status',
                child: ListTile(
                    leading: Icon(Icons.visibility),
                    title: Text('View Status'))),
            PopupMenuItem(
                value: 'debtor',
                child: ListTile(
                    leading: Icon(Icons.payment), title: Text('Pay Debtor'))),
            PopupMenuItem(
                value: 'create_user',
                child: ListTile(
                    leading: Icon(Icons.person_add),
                    title: Text('Create User'))),
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
              fontWeight: FontWeight.w900, fontSize: 20, color: Colors.white),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () {},
            child:
                const Text("Solutions", style: TextStyle(color: Colors.white))),
        TextButton(
            onPressed: () {},
            child: const Text("About", style: TextStyle(color: Colors.white))),
        const SizedBox(width: 12),

        // ▼▼▼ LOGIN LOGIC ▼▼▼
        if (user == null)
          Theme(
            data: Theme.of(context).copyWith(
              popupMenuTheme: const PopupMenuThemeData(color: Colors.white),
            ),
            child: PopupMenuButton<String>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'staff_login') {
                  // Option 1: Staff -> Opens Dialog (Pop-up)
                  _openLogin();
                } else if (value == 'user_login') {
                  // Option 2: User -> Opens Full Page (No Pop-up)
                  Navigator.pushNamed(context, '/debtor_sign_in');
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'staff_login',
                  child: ListTile(
                    leading:
                        Icon(Icons.admin_panel_settings, color: Colors.black87),
                    title: Text(
                      'Sign In (Staff)',
                      style: TextStyle(color: Colors.black), // Added style here
                    ),
                  ),
                ),
                const PopupMenuItem(
                  value: 'user_login',
                  child: ListTile(
                    leading: Icon(Icons.person, color: Colors.black87),
                    title: Text(
                      'User Sign In',
                      style: TextStyle(color: Colors.black), // Added style here
                    ),
                  ),
                ),
              ],
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  children: const [
                    Text("Sign In",
                        style: TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)),
                    SizedBox(width: 5),
                    Icon(Icons.arrow_drop_down, color: Colors.black, size: 20)
                  ],
                ),
              ),
            ),
          )
        else
          // User is already logged in (Staff/Admin)
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
                        "Role: ${role![0].toUpperCase()}${role!.substring(1)}"),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                    value: "logout", child: Text("Logout")),
              ],
              child: Row(
                children: [
                  Text(username ?? user!.email ?? "User",
                      style:
                          const TextStyle(color: Colors.white, fontSize: 16)),
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
