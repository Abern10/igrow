import 'package:flutter/material.dart';
import 'login_page.dart'; // We'll create a matching style login page next.

class OnboardingPage extends StatelessWidget {
  const OnboardingPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use a Scaffold without an AppBar for that full-screen look.
    return Scaffold(
      body: Container(
        width: double.infinity,
        // A subtle top-to-bottom gradient from very light greenish-white to a slightly greener hue
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color(0xFFF8FAF5), // near-white
              Color(0xFFE7F0E3), // gentle green
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              // We’ll space things out for a vertical layout
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Top text area
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 30),
                    // Big heading, with “Take care of your plant...”
                    // and “virtually” in a different color
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          height: 1.3,    // line height
                          color: Color(0xFF1A2B48), // navy-ish
                        ),
                        children: [
                          TextSpan(text: 'Take care of\nyour plant... '),
                          TextSpan(
                            text: 'virtually',
                            style: TextStyle(
                              color: Color(0xFF6E8C43), // green
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Button: “Let’s plant”
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF243046), // dark navy
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 14),
                      ),
                      onPressed: () {
                        // Navigate to your login page
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const LoginPage(),
                          ),
                        );
                      },
                      child: const Text(
                        "Let's plant",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                // Bottom image
                Expanded(
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Image.asset(
                      'assets/images/onboarding_plant.png',
                      // Your 3D plant image
                      height: 300,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}