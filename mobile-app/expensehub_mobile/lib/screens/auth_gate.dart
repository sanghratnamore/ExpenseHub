import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'main_shell.dart';
import 'welcome_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() =>
      _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  bool isLoading = true;
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLogin();
  }

  Future<void> checkLogin() async {
    final authService = AuthService();

    final token = await authService.getToken();
    final userId = await authService.getUserId();

    setState(() {
      isLoggedIn =
          token != null &&
          token.isNotEmpty &&
          userId != null;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (isLoggedIn) {
      return const MainShell();
    }

    return const WelcomeScreen();
  }
}