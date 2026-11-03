import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/app_notification.dart';
import '../services/app_notification_service.dart';
import '../services/auth_service.dart';
import '../services/group_service.dart';
import '../services/notification_service.dart';
import 'dashboard_screen.dart';
import 'friend_requests_screen.dart';
import 'friends_screen.dart';
import 'group_details_screen.dart';
import 'groups_screen.dart';
import 'transaction_details_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final AppNotificationService appNotificationService =
      AppNotificationService();

  final AuthService authService = AuthService();
  final GroupService groupService = GroupService();

  List<AppNotification> notifications = [];
  bool isLoading = true;
  bool isClearing = false;
  bool isClosing = false;
  String? errorMessage;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    loadNotifications();

    NotificationService.onNotificationReceived = loadNotifications;

    _refreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => loadNotifications(),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> loadNotifications() async {
    try {
      final token = await authService.getToken();

      if (token == null) throw Exception('Not logged in');

      final result = await appNotificationService.getNotifications(
        jwtToken: token,
      );

      if (!mounted) return;

      setState(() {
        notifications = result;
        isLoading = false;
        errorMessage = null;
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        errorMessage = error.toString();
        isLoading = false;
      });
    }
  }

  Future<void> markNotificationRead(AppNotification notification) async {
    final token = await authService.getToken();
    if (token == null) return;

    try {
      await appNotificationService.markOneRead(
        jwtToken: token,
        notificationId: notification.id,
      );

      if (!mounted) return;

      setState(() {
        notification.read = true;
      });
    } catch (error) {
      debugPrint('Failed to mark notification read: $error');
    }
  }

  Future<void> markAllRead() async {
    final token = await authService.getToken();
    if (token == null) return;

    await appNotificationService.markAllRead(jwtToken: token);
  }

  Future<void> closeScreen() async {
    if (isClosing) return;

    isClosing = true;

    await markAllRead();

    if (!mounted) return;

    Navigator.pop(context);
  }

  Future<void> deleteNotification(AppNotification notification) async {
    final token = await authService.getToken();
    if (token == null) return;

    final removedIndex = notifications.indexOf(notification);

    setState(() {
      notifications.remove(notification);
    });

    try {
      await appNotificationService.deleteNotification(
        jwtToken: token,
        notificationId: notification.id,
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        notifications.insert(removedIndex, notification);
      });
    }
  }

  Future<void> clearAll() async {
    if (isClearing || notifications.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('Clear all notifications?'),
        content: const Text(
          'This will permanently remove all your notifications.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFE11D48),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear all'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isClearing = true);

    try {
      final token = await authService.getToken();
      if (token == null) return;

      await appNotificationService.clearAll(jwtToken: token);
      await loadNotifications();
    } finally {
      if (mounted) setState(() => isClearing = false);
    }
  }

  Future<void> openNotification(AppNotification notification) async {
    // Recurring transaction created
    if (notification.type == 'RECURRING_TRANSACTION_CREATED') {
      final transactionId = notification.expenseId;

      if (transactionId == null) {
        await markNotificationRead(notification);
        return;
      }

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              TransactionDetailsScreen(transactionId: transactionId),
        ),
      );

      await markNotificationRead(notification);
      return;
    }

    // Recurring transaction due
    if (notification.type == 'RECURRING_TRANSACTION_DUE') {
      await markNotificationRead(notification);
      return;
    }

    // Friend request received
    if (notification.type == 'FRIEND_REQUEST_RECEIVED') {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FriendRequestsScreen()),
      );

      await markNotificationRead(notification);
      return;
    }

    // Friend request accepted
    if (notification.type == 'FRIEND_REQUEST_ACCEPTED') {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FriendsScreen()),
      );

      await markNotificationRead(notification);
      return;
    }

    // Friend removed
    if (notification.type == 'FRIEND_REMOVED') {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const FriendsScreen()),
      );

      await markNotificationRead(notification);
      return;
    }

    // Group removed
    if (notification.type == 'GROUP_REMOVED') {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const GroupsScreen(showBackButton: true),
        ),
      );

      await markNotificationRead(notification);
      return;
    }

    // Budget notifications
    if (notification.type == 'BUDGET_NEAR_LIMIT' ||
        notification.type == 'BUDGET_EXCEEDED') {
      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const DashboardScreen(showBackButton: true),
        ),
      );

      await markNotificationRead(notification);
      return;
    }

    // Group-related notifications
    if (notification.groupId == null) return;

    try {
      final groups = await groupService.getGroups();

      final group = groups.firstWhere(
        (item) => item.id == notification.groupId,
      );

      if (!mounted) return;

      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupDetailsScreen(group: group)),
      );

      await markNotificationRead(notification);
    } catch (error) {
      debugPrint('Failed to open notification: $error');
    }
  }

  int get unreadCount =>
      notifications.where((notification) => !notification.read).length;

  Map<String, List<AppNotification>> get groupedNotifications {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));

    final groups = <String, List<AppNotification>>{
      'Today': [],
      'This week': [],
      'Earlier': [],
    };

    for (final notification in notifications) {
      final date = DateTime(
        notification.createdAt.year,
        notification.createdAt.month,
        notification.createdAt.day,
      );

      if (date == today) {
        groups['Today']!.add(notification);
      } else if (date.isAfter(weekStart) || date.isAtSameMomentAs(weekStart)) {
        groups['This week']!.add(notification);
      } else {
        groups['Earlier']!.add(notification);
      }
    }

    groups.removeWhere((_, value) => value.isEmpty);

    return groups;
  }

  IconData getIcon(String type) {
    switch (type) {
      case 'EXPENSE_ADDED':
        return Icons.receipt_long_rounded;
      case 'EXPENSE_UPDATED':
        return Icons.edit_note_rounded;
      case 'EXPENSE_DELETED':
        return Icons.delete_outline_rounded;
      case 'SETTLEMENT_CREATED':
        return Icons.currency_exchange_rounded;
      case 'GROUP_ADDED':
        return Icons.group_add_rounded;
      case 'GROUP_REMOVED':
        return Icons.group_remove_rounded;
      case 'GROUP_JOINED':
        return Icons.diversity_3_rounded;
      case 'BUDGET_NEAR_LIMIT':
        return Icons.warning_amber_rounded;
      case 'BUDGET_EXCEEDED':
        return Icons.trending_down_rounded;
      case 'FRIEND_REQUEST_RECEIVED':
        return Icons.person_add_alt_1_rounded;
      case 'FRIEND_REQUEST_ACCEPTED':
        return Icons.handshake_rounded;
      case 'FRIEND_REMOVED':
        return Icons.person_remove_rounded;
      default:
        return Icons.notifications_rounded;
    }
  }

  Color getIconBackground(String type) {
    switch (type) {
      case 'EXPENSE_ADDED':
        return const Color(0xFFFFF1F2);
      case 'EXPENSE_UPDATED':
        return const Color(0xFFEEF2FF);
      case 'EXPENSE_DELETED':
        return const Color(0xFFFFF1F2);
      case 'SETTLEMENT_CREATED':
        return const Color(0xFFECFDF5);
      case 'GROUP_ADDED':
      case 'GROUP_JOINED':
        return const Color(0xFFF0F9FF);
      case 'GROUP_REMOVED':
        return const Color(0xFFFFF7ED);
      case 'BUDGET_NEAR_LIMIT':
        return const Color(0xFFFFF7ED);
      case 'BUDGET_EXCEEDED':
        return const Color(0xFFFEF2F2);
      case 'FRIEND_REQUEST_RECEIVED':
      case 'FRIEND_REQUEST_ACCEPTED':
        return const Color(0xFFEEF2FF);
      case 'FRIEND_REMOVED':
        return const Color(0xFFFFF7ED);
      default:
        return const Color(0xFFF8FAFC);
    }
  }

  Color getIconColor(String type) {
    switch (type) {
      case 'EXPENSE_ADDED':
        return const Color(0xFFE11D48);
      case 'EXPENSE_UPDATED':
        return const Color(0xFF4F46E5);
      case 'EXPENSE_DELETED':
        return const Color(0xFFBE123C);
      case 'SETTLEMENT_CREATED':
        return const Color(0xFF059669);
      case 'GROUP_ADDED':
      case 'GROUP_JOINED':
        return const Color(0xFF0284C7);
      case 'GROUP_REMOVED':
        return const Color(0xFFEA580C);
      case 'BUDGET_NEAR_LIMIT':
        return const Color(0xFFEA580C);
      case 'BUDGET_EXCEEDED':
        return const Color(0xFFE11D48);
      case 'FRIEND_REQUEST_RECEIVED':
      case 'FRIEND_REQUEST_ACCEPTED':
        return const Color(0xFF4F46E5);
      case 'FRIEND_REMOVED':
        return const Color(0xFFEA580C);
      default:
        return const Color(0xFF475569);
    }
  }

  String getTime(AppNotification notification) {
    final difference = DateTime.now().difference(notification.createdAt);

    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inMinutes < 60) return '${difference.inMinutes}m ago';
    if (difference.inHours < 24) return '${difference.inHours}h ago';

    return DateFormat('d MMM').format(notification.createdAt);
  }

  @override
  Widget build(BuildContext context) {
    final groups = groupedNotifications;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        await closeScreen();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFAFAFB),
        appBar: _appBar(),
        body: isLoading
            ? const Center(child: CircularProgressIndicator())
            : errorMessage != null
            ? _errorView()
            : notifications.isEmpty
            ? _emptyView()
            : RefreshIndicator(
                onRefresh: loadNotifications,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(18, 6, 18, 32),
                  children: [
                    for (final entry in groups.entries) ...[
                      _sectionHeader(entry.key, entry.value.length),
                      const SizedBox(height: 12),
                      ...entry.value.map(_notificationTile),
                      const SizedBox(height: 24),
                    ],
                  ],
                ),
              ),
      ),
    );
  }

  PreferredSizeWidget _appBar() {
    return AppBar(
      backgroundColor: const Color(0xFFFAFAFB),
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      automaticallyImplyLeading: false,
      titleSpacing: 12,
      leading: GestureDetector(
        onTap: closeScreen,
        child: const Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 20,
          color: Color(0xFF111827),
        ),
      ),
      title: const Text(
        'Notifications',
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w900,
          color: Color(0xFF111827),
        ),
      ),
      actions: [
        if (notifications.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Center(
              child: GestureDetector(
                onTap: clearAll,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE11D48).withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE11D48).withValues(alpha: 0.18),
                    ),
                  ),
                  child: isClearing
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFE11D48),
                          ),
                        )
                      : const Icon(
                          Icons.delete_sweep_rounded,
                          size: 21,
                          color: Color(0xFFE11D48),
                        ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w900,
            color: Color(0xFF111827),
          ),
        ),
        const SizedBox(width: 7),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: Color(0xFF4B5563),
            ),
          ),
        ),
      ],
    );
  }

  Widget _notificationTile(AppNotification notification) {
    final iconColor = getIconColor(notification.type);
    final iconBackground = getIconBackground(notification.type);

    return Dismissible(
      key: ValueKey(notification.id),
      direction: DismissDirection.startToEnd,
      onDismissed: (_) => deleteNotification(notification),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.only(left: 24),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          color: const Color(0xFFE11D48),
          borderRadius: BorderRadius.circular(22),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: GestureDetector(
        onTap: () => openNotification(notification),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
          decoration: BoxDecoration(
            color: notification.read ? Colors.white : const Color(0xFFF0FBF9),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: notification.read
                  ? Colors.grey.shade200
                  : const Color(0xFF0F766E).withValues(alpha: 0.20),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: iconBackground,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      getIcon(notification.type),
                      color: iconColor,
                      size: 21,
                    ),
                  ),
                  if (!notification.read)
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE11D48),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            notification.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF111827),
                            ),
                          ),
                        ),
                        Text(
                          getTime(notification),
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      notification.message,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: Colors.grey.shade600,
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

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_rounded,
              size: 38,
              color: Color(0xFFE11D48),
            ),
            const SizedBox(height: 16),
            const Text(
              'Something went wrong',
              style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again.',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: loadNotifications,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text('Retry'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF111827),
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_off_rounded,
                size: 36,
                color: Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'No notifications',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Group expense updates and settlements\nwill appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
