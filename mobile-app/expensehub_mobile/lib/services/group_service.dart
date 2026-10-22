import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/settlement_suggestion.dart';
import '../models/group.dart';
import '../models/group_expense.dart';
import 'auth_service.dart';
import '../models/group_balance.dart';
import '../models/settlement_record.dart';

import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/group_expense_detail.dart';

class GroupService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/groups';

  final AuthService authService = AuthService();

  Future<Map<String, String>> _headers() async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Not logged in');
    }

    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<List<Group>> getGroups() async {
    final headers = await _headers();

    final response = await http.get(Uri.parse(baseUrl), headers: headers);

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((item) => Group.fromJson(item)).toList();
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception('Failed to load groups: ${response.statusCode}');
  }

  Future<List<GroupBalance>> getGroupBalances(int groupId) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/$groupId/balances'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((balance) => GroupBalance.fromJson(balance)).toList();
    }

    throw Exception(
      'Failed to load balances: '
      '${response.statusCode}',
    );
  }

  Future<List<SettlementSuggestion>> getSettlementSuggestions(
    int groupId,
  ) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/$groupId/settlements/simplified'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((item) => SettlementSuggestion.fromJson(item)).toList();
    }

    throw Exception(
      'Failed to load settlement suggestions: '
      '${response.statusCode}',
    );
  }

  Future<GroupExpenseDetail> getGroupExpenseDetail({
    required int groupId,
    required int expenseId,
  }) async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Please log in again');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/$groupId/expenses/$expenseId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return GroupExpenseDetail.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Failed to load expense details: '
      '${response.statusCode} ${response.body}',
    );
  }

  Future<Group> createGroup({
    required String name,
    required String description,
    required int createdBy,
    required List<int> memberIds,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode({
        'name': name,
        'description': description,
        'createdBy': createdBy,
        'memberIds': memberIds,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Group.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to create group: '
      '${response.statusCode} ${response.body}',
    );
  }

  Future<void> recordSettlement({
    required int groupId,
    required int paidBy,
    required int paidTo,
    required double amount,
    required String settlementDate,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$baseUrl/$groupId/settlements'),
      headers: headers,
      body: jsonEncode({
        'groupId': groupId,
        'paidBy': paidBy,
        'paidTo': paidTo,
        'amount': amount,
        'settlementDate': settlementDate,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to record settlement: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<void> addGroupExpense({
    required int groupId,
    required String description,
    required double amount,
    required String expenseDate,
    required int paidBy,
    required int categoryId,
    required List<int> memberIds,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$baseUrl/$groupId/expenses'),
      headers: headers,
      body: jsonEncode({
        'description': description,
        'amount': amount,
        'expenseDate': expenseDate,
        'paidBy': paidBy,
        'categoryId': categoryId,
        'memberIds': memberIds,
      }),
    );

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(
        'Failed to add expense: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<SettlementRecord>> getSettlementHistory(int groupId) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/$groupId/settlements'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((item) => SettlementRecord.fromJson(item)).toList();
    }

    throw Exception(
      'Failed to load settlement history: '
      '${response.statusCode}',
    );
  }

  Future<void> deleteGroupExpense({
    required int groupId,
    required int expenseId,
  }) async {
    final headers = await _headers();

    final response = await http.delete(
      Uri.parse('$baseUrl/$groupId/expenses/$expenseId'),
      headers: headers,
    );

    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception(
        'Failed to delete expense: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<GroupExpense>> getGroupExpenses(int groupId) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/$groupId/expenses'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((expense) => GroupExpense.fromJson(expense)).toList();
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Failed to load expenses: '
      '${response.statusCode}',
    );
  }
}
