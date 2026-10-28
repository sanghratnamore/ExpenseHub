import 'package:flutter/material.dart';

import 'app_message.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';


class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});


  @override
  State<ChangePasswordScreen> createState() =>
      _ChangePasswordScreenState();
}


class _ChangePasswordScreenState
    extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();


  final currentPasswordController =
      TextEditingController();
  final newPasswordController = TextEditingController();
  final confirmPasswordController =
      TextEditingController();


  final authService = AuthService();


  bool isLoading = false;
  bool hideCurrentPassword = true;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;


  @override
  void dispose() {
    currentPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }


  Future<void> changePassword() async {
    if (!_formKey.currentState!.validate()) return;


    setState(() {
      isLoading = true;
    });


    try {
      await authService.changePassword(
        currentPassword:
            currentPasswordController.text,
        newPassword: newPasswordController.text,
        confirmPassword:
            confirmPasswordController.text,
      );


      if (!mounted) return;


      showAppMessage(
        context,
        message: 'Password changed successfully',
      );


      await authService.logout();


      if (!mounted) return;


      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;


      showAppMessage(
        context,
        message: error
            .toString()
            .replaceAll('Exception: ', ''),
        isError: true,
      );
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
        title: const Text(
          'Change Password',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          24,
          16,
          24,
          32,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              const Text(
                'Update your password',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Enter your current password, then choose a new password.',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 32),
              _PasswordField(
                controller:
                    currentPasswordController,
                hintText: 'Current password',
                obscureText: hideCurrentPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hideCurrentPassword =
                          !hideCurrentPassword;
                    });
                  },
                  icon: Icon(
                    hideCurrentPassword
                        ? Icons
                            .visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Enter your current password';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _PasswordField(
                controller: newPasswordController,
                hintText: 'New password',
                obscureText: hideNewPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hideNewPassword =
                          !hideNewPassword;
                    });
                  },
                  icon: Icon(
                    hideNewPassword
                        ? Icons
                            .visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Enter a new password';
                  }
                  if (value.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 18),
              _PasswordField(
                controller:
                    confirmPasswordController,
                hintText: 'Confirm new password',
                obscureText: hideConfirmPassword,
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      hideConfirmPassword =
                          !hideConfirmPassword;
                    });
                  },
                  icon: Icon(
                    hideConfirmPassword
                        ? Icons
                            .visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
                validator: (value) {
                  if (value == null ||
                      value.isEmpty) {
                    return 'Confirm your new password';
                  }
                  if (value !=
                      newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading
                      ? null
                      : changePassword,
                  style: FilledButton.styleFrom(
                    backgroundColor:
                        const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets
                        .symmetric(
                      vertical: 18,
                    ),
                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(
                              18),
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Change Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight:
                                FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _PasswordField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final bool obscureText;
  final Widget? suffixIcon;
  final String? Function(String?) validator;


  const _PasswordField({
    required this.controller,
    required this.hintText,
    required this.obscureText,
    required this.validator,
    this.suffixIcon,
  });


  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator: validator,
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon:
            const Icon(Icons.lock_outline),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 18,
          vertical: 18,
        ),
        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(18),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}