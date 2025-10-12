import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loan_management/admin/AllDebtorsPage.dart';
import 'package:loan_management/admin/Debtor.dart';
import 'package:loan_management/admin/admin_home.dart';
import 'package:loan_management/admin/add_staff.dart';
import 'package:loan_management/user/Debtor.dart';

class AdminLayout extends StatefulWidget {
  final String username;
  final String role;
  const AdminLayout({super.key, required this.username, required this.role});

  @override
  State<AdminLayout> createState() => _AdminLayoutState();
}

class _AdminLayoutState extends State<AdminLayout> {
  Widget _currentPage = const AdminHomePage(); // default

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    if (mounted) {
      // Assuming '/home' is your login or initial screen
      Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
    }
  }

  void _selectPage(Widget page) {
    setState(() {
      _currentPage = page;
    });
    Navigator.pop(context); // Close the drawer
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E3A8A), // navy blue
        elevation: 2,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        title: const Text(
          "Admin Dashboard",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == "logout") _logout();
            },
            color: Colors.white,
            itemBuilder: (context) => [
              PopupMenuItem<String>(
                value: "role",
                enabled: false,
                child: Text("Role: ${widget.role}"),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem<String>(
                value: "logout",
                child: Text("Logout"),
              ),
            ],
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.teal,
                  child: Text(
                    widget.username.isNotEmpty
                        ? widget.username[0].toUpperCase()
                        : "U",
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  widget.username,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                ),
                const Icon(Icons.arrow_drop_down, color: Colors.white),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFF1E293B), // dark slate
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(color: Color(0xFF1E3A8A)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.admin_panel_settings,
                      color: Colors.white, size: 40),
                  const SizedBox(height: 10),
                  Text(
                    widget.username,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  Text(
                    "Role: ${widget.role}",
                    style: const TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home, color: Colors.white),
              title: const Text("Home", style: TextStyle(color: Colors.white)),
              onTap: () => _selectPage(const AdminHomePage()),
            ),
            ListTile(
              leading: const Icon(Icons.person_add, color: Colors.white),
              title: const Text("Add Staff",
                  style: TextStyle(color: Colors.white)),
              onTap: () => _selectPage(const AddStaffPage()),
            ),

            // ### NEW ITEMS ADDED HERE ###
            const Divider(color: Colors.white24),

            ListTile(
              leading: const Icon(Icons.people, color: Colors.white),
              title: const Text("All Debtor Data",
                  style: TextStyle(color: Colors.white)),
              onTap: () => _selectPage(const AllDebtorsPage()),
            ),
            ExpansionTile(
              leading: const Icon(Icons.edit_document, color: Colors.white),
              title: const Text("Debtor Update",
                  style: TextStyle(color: Colors.white)),
              iconColor: Colors.white,
              collapsedIconColor: Colors.white,
              children: [
                ListTile(
                  // Indent the sub-item for better UI
                  contentPadding: const EdgeInsets.only(left: 30.0),
                  leading:
                      const Icon(Icons.person_search, color: Colors.white70),
                  title: const Text("Update Details",
                      style: TextStyle(color: Colors.white70)),
                  onTap: () => _selectPage(const adminDebtorPage()),
                ),
              ],
            ),
            // ### END OF NEW ITEMS ###
          ],
        ),
      ),
      body: Container(
        padding: const EdgeInsets.all(16),
        child: _currentPage,
      ),
    );
  }
}
