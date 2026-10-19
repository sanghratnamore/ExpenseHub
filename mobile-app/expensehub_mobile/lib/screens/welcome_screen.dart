import 'package:flutter/material.dart';

import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color.fromARGB(255, 198, 235, 33), Color.fromARGB(255, 74, 104, 111), Color(0xFF334155)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(50),
            child: Column(
              children: [
                Image.asset(
                  'assets/images/Shell_logo.png',
                  height:350,
                  fit: BoxFit.contain,
                ),

                const SizedBox(height: 36),

                Text(
                  'Track expenses, manage income,\nand understand where your money goes.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 44),

                Row(
                  children: [
                    _FeatureCard(icon: Icons.pie_chart_outline, title: 'Track'),
                    const SizedBox(width: 12),
                    _FeatureCard(icon: Icons.savings_outlined, title: 'Save'),
                    const SizedBox(width: 12),
                    _FeatureCard(
                      icon: Icons.insights_outlined,
                      title: 'Analyze',
                    ),
                  ],
                ),

                const Spacer(),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      );
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'Create Account',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 14),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.35),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      'I already have an account',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;

  const _FeatureCard({required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 26),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
