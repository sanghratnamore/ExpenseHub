import 'package:flutter/material.dart';
import '../services/friend_service.dart';

const Color kPrimary = Color(0xFF0F766E);
const Color kInk = Color(0xFF0F172A);
const Color kMuted = Color(0xFF64748B);
const Color kSurface = Color(0xFFF6F7F9);
const Color kBorder = Color(0xFFE2E8F0);
const Color kDanger = Color(0xFFE11D48);

class AddFriendScreen extends StatefulWidget {
  const AddFriendScreen({super.key});

  @override
  State<AddFriendScreen> createState() => _AddFriendScreenState();
}

class _AddFriendScreenState extends State<AddFriendScreen> {
  final FriendService _friendService = FriendService();
  final TextEditingController emailController = TextEditingController();

  bool isSending = false;

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  Future<void> _sendRequest() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      _showMessage('Enter an email address', isError: true);
      return;
    }

    setState(() => isSending = true);

    try {
      await _friendService.sendRequest(email);

      if (!mounted) return;

      emailController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: kPrimary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Text('Friend request sent to $email'),
        ),
      );

      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;

      setState(() => isSending = false);
      _showMessage(error.toString(), isError: true);
    }
  }

  void _showMessage(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? kDanger : kPrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kSurface,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add friend',
          style: TextStyle(
            color: kInk,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: kBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: const Icon(
                  Icons.person_add_alt_1_rounded,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Find your friend',
                style: TextStyle(
                  color: kInk,
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Enter the email address they used to register on ExpenseHub.',
                style: TextStyle(
                  color: kMuted,
                  fontSize: 12.5,
                  height: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                style: const TextStyle(
                  color: kInk,
                  fontWeight: FontWeight.w700,
                ),
                decoration: InputDecoration(
                  hintText: 'friend@email.com',
                  hintStyle: const TextStyle(
                    color: kMuted,
                    fontWeight: FontWeight.w600,
                  ),
                  prefixIcon: const Icon(
                    Icons.alternate_email_rounded,
                    color: kMuted,
                    size: 20,
                  ),
                  filled: true,
                  fillColor: kSurface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: isSending ? null : _sendRequest,
                  style: FilledButton.styleFrom(
                    backgroundColor: kPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: isSending
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Send request',
                          style: TextStyle(fontWeight: FontWeight.w900),
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