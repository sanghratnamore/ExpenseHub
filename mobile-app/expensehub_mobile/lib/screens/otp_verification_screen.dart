import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/auth_service.dart';
import 'main_shell.dart';
import '../utils/app_route.dart';
import 'app_message.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String email;

  const OtpVerificationScreen({super.key, required this.email});

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final authService = AuthService();

  final List<TextEditingController> otpControllers = List.generate(
    6,
    (_) => TextEditingController(),
  );

  final List<FocusNode> otpFocusNodes = List.generate(6, (_) => FocusNode());

  bool isLoading = false;
  bool isResending = false;
  int resendSeconds = 180;
  String? otpError;

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

    super.dispose();
  }

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

  String get enteredOtp =>
      otpControllers.map((controller) => controller.text).join();

  Future<void> verifyOtp() async {
    final otp = enteredOtp;

    if (otp.length != 6) {
      setState(() {
        otpError = 'Enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      isLoading = true;
      otpError = null;
    });

    try {
      await authService.verifyOtp(email: widget.email, otp: otp);

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        fadeSlideRoute(const MainShell()),
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

  Future<void> resendOtp() async {
    setState(() {
      isResending = true;
      otpError = null;
    });

    try {
      await authService.resendOtp(email: widget.email);

      if (!mounted) return;

      showAppMessage(context, message: 'A new OTP has been sent to your email');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7F9),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
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
                        Icons.mark_email_read_outlined,
                        color: Color(0xFF0F766E),
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Verify your email',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a 6-digit verification code to\n${widget.email}',
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
                                verifyOtp();
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
                        onPressed: isLoading ? null : verifyOtp,
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
                                'Verify and continue',
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
            ],
          ),
        ),
      ),
    );
  }
}
