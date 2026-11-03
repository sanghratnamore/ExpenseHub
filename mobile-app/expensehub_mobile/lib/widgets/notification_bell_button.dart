import 'package:flutter/material.dart';

import '../services/app_notification_service.dart';
import '../services/auth_service.dart';
import '../screens/notifications_screen.dart';

class NotificationBellButton extends StatefulWidget {
  const NotificationBellButton({super.key});

  @override
  State<NotificationBellButton> createState() =>
      _NotificationBellButtonState();
}

class _NotificationBellButtonState
    extends State<NotificationBellButton> {
  final appNotificationService =
      AppNotificationService();

  final authService = AuthService();

  int unreadCount = 0;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadUnreadCount();
  }

  Future<void> loadUnreadCount() async {
    setState(() {
      isLoading = true;
    });

    try {
      final token = await authService.getToken();

      if (token == null) {
        throw Exception('Not logged in');
      }

      final count =
          await appNotificationService.getUnreadCount(
        jwtToken: token,
      );

      if (!mounted) return;

      setState(() {
        unreadCount = count;
        isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        unreadCount = 0;
        isLoading = false;
      });
    }
  }

  Future<void> openNotifications() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            const NotificationsScreen(),
      ),
    );

    if (!mounted) return;

    loadUnreadCount();
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: openNotifications,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(
            Icons.notifications_none_rounded,
            size: 24,
          ),
          if (!isLoading && unreadCount > 0)
            Positioned(
              top: -4,
              right: -6,
              child: Container(
                padding:
                    const EdgeInsets.all(4),
                constraints: const BoxConstraints(
                  minWidth: 18,
                  minHeight: 18,
                ),
                decoration:
                    const BoxDecoration(
                  color: Color(0xFFE11D48),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  unreadCount > 99
                      ? '99+'
                      : unreadCount
                          .toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight:
                        FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}