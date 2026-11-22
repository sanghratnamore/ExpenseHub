import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../screens/login_screen.dart';
import '../utils/app_navigator.dart';

class SessionManager {
  static const _storage = FlutterSecureStorage();
  static bool _redirecting = false;

  static Future<void> handleExpiredSession() async {
    if (_redirecting) return;
    _redirecting = true;

    await _storage.deleteAll();

    final navigator = appNavigatorKey.currentState;

    if (navigator != null) {
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }

    _redirecting = false;
  }
}