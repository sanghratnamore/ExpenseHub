import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_message.dart';
import 'login_screen.dart';
import '../services/auth_service.dart';
import '../utils/app_route.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  final newPasswordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final authService = AuthService();

  bool isLoading = false;
  bool isResending = false;
  bool hideNewPassword = true;
  bool hideConfirmPassword = true;

  String? otpError;
  int resendSeconds = 180;

  @override
  void initState() {
    super.initState();
    startResendTimer();
  }

  @override
  void dispose() {
    for (final controller in otpControllers) {
      controller.dispose();
    }

    for (final focusNode in otpFocusNodes) {
      focusNode.dispose();
    }

    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  String get enteredOtp =>
      otpControllers.map((controller) => controller.text).join();

  void startResendTimer() {
    setState(() {
      resendSeconds = 180;
    });

    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return false;

      setState(() {
        resendSeconds--;
      });

      return resendSeconds > 0;
    });
  }

  Future<void> resendOtp() async {
    setState(() {
      isResending = true;
      otpError = null;
    });

    try {
      await authService.forgotPassword(email: widget.email);

      if (!mounted) return;

      showAppMessage(
        context,
        message: 'A new reset code has been sent to your email',
      );

      startResendTimer();
    } catch (error) {
      if (!mounted) return;

      showAppMessage(
        context,
        message: error.toString().replaceAll('Exception: ', ''),
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isResending = false;
        });
      }
    }
  }

  Future<void> resetPassword() async {
    final otp = enteredOtp;

    if (otp.length != 6) {
      setState(() {
        otpError = 'Enter the complete 6-digit code';
      });
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isLoading = true;
      otpError = null;
    });

    try {
      await authService.resetPassword(
        email: widget.email,
        otp: otp,
        newPassword: newPasswordController.text,
      );

      if (!mounted) return;

      showAppMessage(
        context,
        message: 'Password reset successfully. Please log in.',
      );

      Navigator.pushAndRemoveUntil(
        context,
        fadeSlideRoute(const LoginScreen()),
        (route) => false,
      );
    } catch (error) {
      if (!mounted) return;

      final message = error.toString().toLowerCase();

      setState(() {
        otpError = message.contains('expired')
            ? 'This code has expired. Please resend a new code.'
            : 'OTP doesn’t match';
      });
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
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Reset password',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.10),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_reset_rounded,
                        color: Color(0xFF0F766E),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Enter reset code',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a 6-digit code to\n${widget.email}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14.5,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Premium OTP input
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(6, (index) {
                        final hasValue = otpControllers[index].text.isNotEmpty;

                        return SizedBox(
                          width: 48,
                          child: TextField(
                            controller: otpControllers[index],
                            focusNode: otpFocusNodes[index],
                            textAlign: TextAlign.center,
                            keyboardType: TextInputType.number,
                            maxLength: 1,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF0F172A),
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: InputDecoration(
                              counterText: '',
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: otpError != null
                                      ? Colors.red
                                      : Colors.grey.shade300,
                                ),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: otpError != null
                                      ? Colors.red
                                      : hasValue
                                      ? const Color(0xFF0F766E)
                                      : Colors.grey.shade300,
                                  width: hasValue ? 1.6 : 1,
                                ),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: Color(0xFF0F766E),
                                  width: 1.8,
                                ),
                              ),
                            ),
                            onChanged: (value) {
                              setState(() {
                                otpError = null;
                              });

                              if (value.length == 1 && index < 5) {
                                otpFocusNodes[index + 1].requestFocus();
                              }

                              if (value.isEmpty && index > 0) {
                                otpFocusNodes[index - 1].requestFocus();
                              }

                              if (enteredOtp.length == 6) {
                                resetPassword();
                              }
                            },
                          ),
                        );
                      }),
                    ),

                    if (otpError != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red,
                            size: 18,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              otpError!,
                              style: const TextStyle(
                                color: Colors.red,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: isLoading ? null : resetPassword,
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 17),
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
                                'Verify code',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 18),

                    Center(
                      child: resendSeconds > 0
                          ? Text(
                              'Resend code in '
                              '${resendSeconds ~/ 60}:'
                              '${(resendSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            )
                          : TextButton(
                              onPressed: isResending ? null : resendOtp,
                              child: const Text(
                                'Resend code',
                                style: TextStyle(
                                  color: Color(0xFF0F766E),
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // New password
              TextFormField(
                controller: newPasswordController,
                obscureText: hideNewPassword,
                decoration: InputDecoration(
                  hintText: 'New password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hideNewPassword = !hideNewPassword;
                      });
                    },
                    icon: Icon(
                      hideNewPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
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
                validator: (value) {
                  if (value == null || value.length < 6) {
                    return 'Use at least 6 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 18),

              // Confirm password
              TextFormField(
                controller: confirmPasswordController,
                obscureText: hideConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: () {
                      setState(() {
                        hideConfirmPassword = !hideConfirmPassword;
                      });
                    },
                    icon: Icon(
                      hideConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
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
                validator: (value) {
                  if (value != newPasswordController.text) {
                    return 'Passwords do not match';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 28),

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isLoading ? null : resetPassword,
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
                          'Reset Password',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
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
