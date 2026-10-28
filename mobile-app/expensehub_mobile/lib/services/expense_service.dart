import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/expense.dart';
import 'auth_service.dart';

class ExpenseService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/transactions';
  final AuthService authService = AuthService();

  Future<List<Expense>> getExpenses() async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Expense.fromJson(item)).toList();
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Failed to load expenses: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> updateExpense({
    required String id,
    required String userId,
    required String type,
    required double amount,
    required String description,
    required String date,
    required String categoryId,
  }) async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.put(
      Uri.parse('$baseUrl/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'userId': userId,
        'type': type,
        'amount': amount,
        'description': description,
        'date': date,
        'categoryId': categoryId,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception(
        'Failed to update transaction: ${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> deleteExpense(String id) async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Not logged in');
    }

    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete transaction: ${response.statusCode} ${response.body}',
      );
    }
  }
}
