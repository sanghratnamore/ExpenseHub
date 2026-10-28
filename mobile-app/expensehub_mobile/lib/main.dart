import 'package:flutter/material.dart';
import 'screens/auth_gate.dart';
import 'screens/login_screen.dart';
void main() {
  runApp(const ExpenseHubApp());
}

class ExpenseHubApp extends StatelessWidget {
  const ExpenseHubApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ExpenseHub',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: const AuthGate(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ExpenseHub')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
          child: const Text('Go to Login'),
        ),
      ),
    );
  }
}
