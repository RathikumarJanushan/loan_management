import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loan_management/user/appbar.dart'; // <-- add this
import 'registration.dart';
import '../login_dialog.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _goToRegistration(BuildContext context) async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser == null) {
      await showDialog<String>(
        context: context,
        builder: (_) => const LoginDialog(),
      );
    }
    if (auth.currentUser != null && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RegistrationPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final isNarrow = w < 900;

    return Scaffold(
      appBar: const CustomAppBar(), // <-- show CustomAppBar here
      backgroundColor: const Color(0xFF0B0220),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: isNarrow
              ? Column(
                  children: [
                    _HeroLeft(onTapCTA: () => _goToRegistration(context)),
                    const SizedBox(height: 20),
                    const _HeroRight(),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child:
                          _HeroLeft(onTapCTA: () => _goToRegistration(context)),
                    ),
                    const SizedBox(width: 20),
                    const Expanded(child: _HeroRight()),
                  ],
                ),
        ),
      ),
    );
  }
}

class _HeroLeft extends StatelessWidget {
  final VoidCallback onTapCTA;
  const _HeroLeft({required this.onTapCTA});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFF7FD0D0), Color(0xFFB794F4)]),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            "#flexiblesolutions",
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          "Flexible Solutions\nfor Your Business",
          style: TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w800,
              height: 1.1),
        ),
        const SizedBox(height: 12),
        const Text(
          "Get your loan here with the lowest interest and simple approval.",
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: const [
            _Pill(icon: Icons.percent, label: "Low interest"),
            _Pill(icon: Icons.flash_on, label: "Quick approval"),
            _Pill(icon: Icons.lock, label: "Secure"),
          ],
        ),
        const SizedBox(height: 24),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          ),
          onPressed: onTapCTA,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Text("Check your eligibility today"),
              SizedBox(width: 10),
              Icon(Icons.arrow_forward, size: 18),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroRight extends StatelessWidget {
  const _HeroRight();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset("assets/bankloan.webp", fit: BoxFit.cover),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.transparent, Colors.black.withOpacity(0.35)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _Pill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white10,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white70, size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }
}
