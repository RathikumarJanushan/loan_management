import 'dart:convert';
import 'package:crypto/crypto.dart'; // For password hashing
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:loan_management/user/appbar.dart'; // Assuming this exists based on your previous code

class CreateUserPage extends StatefulWidget {
  const CreateUserPage({super.key});

  @override
  State<CreateUserPage> createState() => _CreateUserPageState();
}

class _CreateUserPageState extends State<CreateUserPage> {
  String? _selectedDocId;
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscureText = true;

  // Custom Input Decoration to match your theme
  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
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

  // Helper to hash password (SHA-256)
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<void> _updatePassword() async {
    if (_selectedDocId == null || _passwordController.text.trim().isEmpty)
      return;

    setState(() => _isLoading = true);

    try {
      final hashedPassword = _hashPassword(_passwordController.text.trim());

      await FirebaseFirestore.instance
          .collection('userloneregister')
          .doc(_selectedDocId)
          .update({
        'password': hashedPassword,
        'accountCreatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User account created successfully!'),
            backgroundColor: Color(0xFF7FD0D0),
          ),
        );
        // Reset form
        setState(() {
          _selectedDocId = null;
          _passwordController.clear();
        });
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
      appBar: const CustomAppBar(), // Using your existing AppBar
      body: StreamBuilder<QuerySnapshot>(
        // Listen to the collection in real-time
        stream: FirebaseFirestore.instance
            .collection('userloneregister')
            .orderBy('name')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
                child: Text('Error loading data',
                    style: TextStyle(color: Colors.white)));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final allDocs = snapshot.data!.docs;

          // Split data into two lists based on whether 'password' exists
          final unregisteredUsers = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['password'] == null ||
                (data['password'] as String).isEmpty;
          }).toList();

          final registeredUsers = allDocs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['password'] != null &&
                (data['password'] as String).isNotEmpty;
          }).toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------- SECTION 1: CREATE USER FORM ----------------
                Text('Create User Account',
                    style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        foreground: Paint()
                          ..shader = const LinearGradient(colors: [
                            Color(0xFF7FD0D0),
                            Color(0xFFB794F4)
                          ]).createShader(const Rect.fromLTWH(0, 0, 260, 40)))),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFF120834),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white12),
                  ),
                  child: Column(
                    children: [
                      // DROPDOWN
                      DropdownButtonFormField<String>(
                        value: _selectedDocId,
                        dropdownColor: const Color(0xFF1A113B),
                        style: const TextStyle(color: Colors.white),
                        decoration: _dec('Select IC No / Debtor'),
                        items: unregisteredUsers.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final name = data['name'] ?? 'Unknown';
                          final ic = data['icNo'] ?? 'No IC';
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(
                              '$ic - $name',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) {
                          setState(() {
                            _selectedDocId = val;
                          });
                        },
                      ),

                      // PASSWORD INPUT (Only shows if user is selected)
                      if (_selectedDocId != null) ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscureText,
                          style: const TextStyle(color: Colors.white),
                          decoration: _dec('Password'),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _updatePassword,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF7FD0D0),
                              foregroundColor: const Color(0xFF0B0220),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: _isLoading
                                ? const CircularProgressIndicator()
                                : const Text('Create Account',
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ] else ...[
                        const SizedBox(height: 20),
                        const Text(
                          'Select an IC Number above to set a password.',
                          style: TextStyle(
                              color: Colors.white38,
                              fontStyle: FontStyle.italic),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // ---------------- SECTION 2: REGISTERED USERS LIST ----------------
                const Text('Registered Users',
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white)),
                const SizedBox(height: 12),

                if (registeredUsers.isEmpty)
                  const Text('No registered users yet.',
                      style: TextStyle(color: Colors.white54))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: registeredUsers.length,
                    separatorBuilder: (c, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final data =
                          registeredUsers[index].data() as Map<String, dynamic>;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.verified_user,
                                color: Color(0xFF7FD0D0)),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['name'] ?? 'Unknown Name',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'IC: ${data['icNo'] ?? '-'}',
                                    style:
                                        const TextStyle(color: Colors.white70),
                                  ),
                                ],
                              ),
                            ),
                            const Text(
                              'Active',
                              style: TextStyle(
                                  color: Colors.greenAccent, fontSize: 12),
                            )
                          ],
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 50),
              ],
            ),
          );
        },
      ),
    );
  }
}
