import 'package:flutter/material.dart';

import 'app_message.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool hidePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
    });

    try {
      final authService = AuthService();

      await authService.register(
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        password: passwordController.text,
      );

      if (!mounted) return;

      showAppMessage(context, message: 'Account created successfully');

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    } catch (error) {
      if (!mounted) return;

      String message = 'Something went wrong. Please try again.';

      if (error.toString().contains('email-already-in-use')) {
        message = 'This email is already registered. Please log in instead.';
      } else if (error.toString().contains('weak-password')) {
        message = 'Please use a stronger password with at least 6 characters.';
      } else if (error.toString().contains('invalid-email')) {
        message = 'Please enter a valid email address.';
      } else if (error.toString().contains('network-request-failed')) {
        message = 'No internet connection. Please try again.';
      }

      showAppMessage(context, message: message, isError: true);
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create account',
                style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Text(
                'Start tracking your expenses\nand income today.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 40),

              _RegisterField(
                controller: nameController,
                hintText: 'Full name',
                icon: Icons.person_outline,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your name';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              _RegisterField(
                controller: emailController,
                hintText: 'Email address',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter your email';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              _RegisterField(
                controller: passwordController,
                hintText: 'Password',
                icon: Icons.lock_outline,
                obscureText: hidePassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hidePassword = !hidePassword;
                    });
                  },
                  icon: Icon(
                    hidePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    color: Colors.grey.shade500,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Enter a password';
                  }

                  if (value.length < 6) {
                    return 'Use at least 6 characters';
                  }

                  return null;
                },
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : register,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Create Account',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 28),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Already have an account?',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text(
                      'Log In',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RegisterField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final String? Function(String?) validator;

  const _RegisterField({
    required this.controller,
    required this.hintText,
    required this.icon,
    required this.validator,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
