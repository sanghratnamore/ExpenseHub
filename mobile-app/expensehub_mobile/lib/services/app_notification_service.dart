import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/app_notification.dart';

class AppNotificationService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/notifications';

  Future<Map<String, String>> _headers(String jwtToken) async {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $jwtToken',
    };
  }

  Future<List<AppNotification>> getNotifications({
    required String jwtToken,
  }) async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(jwtToken),
    );

    if (response.statusCode == 200) {
      final List data = jsonDecode(response.body);

      return data.map((item) => AppNotification.fromJson(item)).toList();
    }

    throw Exception(
      'Failed to load notifications. '
      'Status: ${response.statusCode}',
    );
  }

  Future<int> getUnreadCount({required String jwtToken}) async {
    final response = await http.get(
      Uri.parse('$baseUrl/unread-count'),
      headers: await _headers(jwtToken),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['count'] ?? 0;
    }

    return 0;
  }

  Future<void> markAllRead({required String jwtToken}) async {
    final response = await http.put(
      Uri.parse('$baseUrl/mark-all-read'),
      headers: await _headers(jwtToken),
    );

    if (response.statusCode >= 400) {
      throw Exception(
        'Failed to mark notifications as read. '
        'Status: ${response.statusCode}',
      );
    }
  }

  Future<void> markOneRead({
    required String jwtToken,
    required String notificationId,
  }) async {
    await http.put(
      Uri.parse('$baseUrl/$notificationId/read'),
      headers: await _headers(jwtToken),
    );
  }

  Future<void> deleteNotification({
    required String jwtToken,
    required String notificationId,
  }) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$notificationId'),
      headers: await _headers(jwtToken),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to delete notification');
    }
  }

  Future<void> clearAll({required String jwtToken}) async {
    final response = await http.delete(
      Uri.parse(baseUrl),
      headers: await _headers(jwtToken),
    );

    if (response.statusCode >= 400) {
      throw Exception('Failed to clear notifications');
    }
  }

  Future<void> markNotificationRead({
    required String jwtToken,
    required String notificationId,
  }) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/notifications/$notificationId/read'),
      headers: {
        'Authorization': 'Bearer $jwtToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Failed to mark notification as read');
    }
  }
}
