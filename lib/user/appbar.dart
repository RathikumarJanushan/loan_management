import 'dart:async';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// Ensure these paths are correct in your project
import 'package:loan_managementapp/user/Debtor.dart';
import '../login_dialog.dart';

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
    _authSubscription = FirebaseAuth.instance.authStateChanges().listen((
      User? authUser,
    ) {
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
      final doc = await FirebaseFirestore.instance
          .collection("user")
          .doc(uid)
          .get();
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
    // 1. Detect Screen Size
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isMobile = screenWidth < 800;

    return AppBar(
      backgroundColor: const Color(0xFF0B0220),
      elevation: 0,
      // 2. Responsive Leading Menu
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: PopupMenuButton<String>(
          tooltip: 'Menu',
          offset: const Offset(0, 48),
          onSelected: (value) {
            if (value == 'solutions' || value == 'about') {
              // Handle generic links (placeholder)
              debugPrint("Clicked $value");
              return;
            }

            // Auth Logic for Navigation
            if (user == null) {
              if (value == 'register' || value == 'debtor') {
                _openLogin(redirectTo: '/$value');
              } else if (value == 'home') {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (r) => false,
                );
              }
            } else {
              if (value == 'home') {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  '/home',
                  (r) => false,
                );
              } else if (value == 'register') {
                Navigator.pushNamed(context, '/register');
              } else if (value == 'debtor') {
                Navigator.pushNamed(context, '/debtor');
              }
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'home',
              child: ListTile(leading: Icon(Icons.home), title: Text('Home')),
            ),
            const PopupMenuItem(
              value: 'register',
              child: ListTile(
                leading: Icon(Icons.app_registration),
                title: Text('Register'),
              ),
            ),
            const PopupMenuItem(
              value: 'debtor',
              child: ListTile(
                leading: Icon(Icons.payment),
                title: Text('Pay Debtor'),
              ),
            ),
            // 3. Add these items to the menu ONLY on Mobile
            if (isMobile) ...[
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: 'solutions',
                child: ListTile(
                  leading: Icon(Icons.lightbulb_outline),
                  title: Text('Solutions'),
                ),
              ),
              const PopupMenuItem(
                value: 'about',
                child: ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('About'),
                ),
              ),
            ],
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
        // 4. Show Text Buttons ONLY on Desktop
        if (!isMobile) ...[
          TextButton(
            onPressed: () {},
            child: const Text(
              "Solutions",
              style: TextStyle(color: Colors.white),
            ),
          ),
          TextButton(
            onPressed: () {},
            child: const Text("About", style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 12),
        ],

        // Auth Buttons
        if (user == null)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: ElevatedButton(
              onPressed: _openLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                padding: isMobile
                    ? const EdgeInsets.symmetric(
                        horizontal: 12,
                      ) // Smaller padding on mobile
                    : null,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  Text(
                    isMobile ? "Sign In" : "Sign In",
                  ), // Can change text if needed
                  const SizedBox(width: 5),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
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
                      "Role: ${role![0].toUpperCase()}${role!.substring(1)}",
                    ),
                  ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: "logout",
                  child: Text("Logout"),
                ),
              ],
              child: Row(
                children: [
                  Container(
                    constraints: BoxConstraints(maxWidth: isMobile ? 100 : 200),
                    child: Text(
                      username ?? user!.email ?? "User",
                      overflow:
                          TextOverflow.ellipsis, // Prevent overflow on mobile
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
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
