import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:loan_managementapp/user/appbar.dart';
import 'registration.dart';
import '../login_dialog.dart';
import 'dart:ui'; // <--- Add this at the top

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
    // Determine screen width for responsive layout
    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 900;

    return Scaffold(
      extendBodyBehindAppBar: true, // Makes the background flow behind app bar
      appBar: const CustomAppBar(),
      backgroundColor: const Color(0xFF0B0220),
      body: Stack(
        children: [
          // 1. Background Ambient Glow
          // 1. Background Ambient Glow
          Positioned(
            top: -100,
            left: -100,
            child: ImageFiltered(
              // This creates the blur effect
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 400,
                height: 400,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7FD0D0).withOpacity(0.3),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            right: -50,
            child: ImageFiltered(
              // This creates the blur effect
              imageFilter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFB794F4).withOpacity(0.3),
                ),
              ),
            ),
          ),

          // 2. Main Scrollable Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: isMobile
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _HeroLeft(onTapCTA: () => _goToRegistration(context)),
                        const SizedBox(height: 40),
                        // FIXED: Wrapped in AspectRatio to prevent layout error
                        const AspectRatio(
                          aspectRatio: 1.1,
                          child: _HeroRight(),
                        ),
                        const SizedBox(height: 20),
                      ],
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _HeroLeft(
                            onTapCTA: () => _goToRegistration(context),
                          ),
                        ),
                        const SizedBox(width: 40),
                        const Expanded(
                          flex: 4,
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _HeroRight(),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  // Helper for blur
  dynamic useBlur(double sigma) {
    // Only applies if your flutter version supports ImageFilter
    // Otherwise returns null
    return null; // Simplified for basic compat, usually implies ImageFilter.blur
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
        // Tag
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF7FD0D0).withOpacity(0.1),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFF7FD0D0).withOpacity(0.3)),
          ),
          child: const Text(
            "🚀  #FlexibleSolutions",
            style: TextStyle(
              color: Color(0xFF7FD0D0),
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Headline
        RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              height: 1.1,
              fontFamily: 'Roboto', // Or your app font
              color: Colors.white,
            ),
            children: [
              TextSpan(text: "Flexible Solutions\nfor Your "),
              TextSpan(
                text: "Business",
                style: TextStyle(
                  color: Colors.transparent,
                  shadows: [Shadow(offset: Offset(0, -5), color: Colors.white)],
                  decoration: TextDecoration.underline,
                  decorationColor: Color(0xFF7FD0D0),
                  decorationThickness: 2,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),
        const Text(
          "Get your loan approved in minutes with low interest rates and secure processing.",
          style: TextStyle(
            color: Colors.white60,
            fontSize: 16,
            height: 1.5,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 32),

        // Stats Row
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: const [
              _GlassPill(icon: Icons.percent_rounded, label: "Low Interest"),
              SizedBox(width: 12),
              _GlassPill(icon: Icons.flash_on_rounded, label: "Fast Approval"),
              SizedBox(width: 12),
              _GlassPill(icon: Icons.security_rounded, label: "Secure"),
            ],
          ),
        ),

        const SizedBox(height: 40),

        // CTA Button
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF7FD0D0).withOpacity(0.4),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: const Color(0xFF0B0220),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 0,
            ),
            onPressed: onTapCTA,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Text(
                  "Check Eligibility",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(width: 8),
                Icon(Icons.arrow_forward_rounded, size: 20),
              ],
            ),
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
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 30,
            offset: const Offset(0, 15),
          ),
        ],
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Image
            Image.asset(
              "assets/bankloan.webp",
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[850],
                  child: const Center(
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.white30,
                      size: 50,
                    ),
                  ),
                );
              },
            ),
            // Gradient Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    const Color(0xFF0B0220).withOpacity(0.2),
                    const Color(0xFF0B0220).withOpacity(0.6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
            // Floating Badge inside image
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFF7FD0D0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.black,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Approved",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          "\RM50,000 Loan",
                          style: TextStyle(color: Colors.white70, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlassPill extends StatelessWidget {
  final IconData icon;
  final String label;
  const _GlassPill({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: const Color(0xFF7FD0D0), size: 18),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}
