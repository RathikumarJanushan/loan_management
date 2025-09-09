import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_dialog.dart';
import 'admin_app_bar.dart'; // <-- added

class CustomAppBar extends StatefulWidget implements PreferredSizeWidget {
  const CustomAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  State<CustomAppBar> createState() => _CustomAppBarState();
}

class _CustomAppBarState extends State<CustomAppBar> {
  User? user = FirebaseAuth.instance.currentUser;
  String? username;
  String? role;

  Future<void> _openLogin() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => const LoginDialog(),
    );

    if (result != null) {
      setState(() {
        username = result;
        user = FirebaseAuth.instance.currentUser;
      });
      // fetch role after login
      final doc =
          await FirebaseFirestore.instance.collection("user").doc(result).get();
      if (doc.exists) {
        setState(() => role = doc["role"]);

        // redirect if admin
        if (role == "admin" && mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => AdminLayout(username: result, role: role!),
            ),
          );
        }
      }
    }
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    setState(() {
      user = null;
      username = null;
      role = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: const Color(0xFF0B0220),
      elevation: 0,
      title:
          const Text("- Inc.", style: TextStyle(fontWeight: FontWeight.bold)),
      actions: [
        TextButton(
          onPressed: () {},
          child: const Text("Solutions", style: TextStyle(color: Colors.white)),
        ),
        TextButton(
          onPressed: () {},
          child: const Text("About", style: TextStyle(color: Colors.white)),
        ),
        const SizedBox(width: 20),
        if (user == null)
          ElevatedButton(
            onPressed: _openLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: Row(
              children: const [
                Text("Sign In"),
                SizedBox(width: 5),
                Icon(Icons.arrow_forward, size: 16),
              ],
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(right: 20),
            child: PopupMenuButton<String>(
              onSelected: (value) {
                if (value == "logout") {
                  _logout();
                }
              },
              itemBuilder: (context) => [
                if (role != null)
                  PopupMenuItem<String>(
                    value: "role",
                    enabled: false,
                    child: Text("Role: $role"),
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
    );
  }
}
