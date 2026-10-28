import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/settlement_suggestion.dart';
import '../models/group.dart';
import '../models/group_expense.dart';
import 'auth_service.dart';
import '../models/group_balance.dart';
import '../models/settlement_record.dart';
import '../models/group_expense_detail.dart';

class GroupService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/groups';
  static const String friendsBaseUrl = 'http://10.0.2.2:8080/friends';

  final AuthService authService = AuthService();

  String _errorMessage(http.Response response) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map && data['message'] != null) {
        return data['message'].toString();
      }
    } catch (_) {}

    return 'Something went wrong. Please try again.';
  }

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

  Future<void> addMembers({
    required String groupId,
    required List<String> memberIds,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$baseUrl/$groupId/members'),
      headers: headers,
      body: jsonEncode({'memberIds': memberIds}),
    );

    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<Map<String, dynamic>> searchUserByEmail(String email) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$friendsBaseUrl/search?email=$email'),
      headers: headers,
    );

    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Group> getGroupById(String groupId) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/$groupId'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      return Group.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception('Failed to load group: ${response.statusCode}');
  }

  Future<void> removeGroupMember({
    required String groupId,
    required String memberId,
  }) async {
    final headers = await _headers();

    final response = await http.delete(
      Uri.parse('$baseUrl/$groupId/members/$memberId'),
      headers: headers,
    );

    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<List<Map<String, dynamic>>> getFriends() async {
    final response = await http.get(
      Uri.parse(friendsBaseUrl),
      headers: await _headers(),
    );

    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }

    final data = jsonDecode(response.body) as List;

    return data.map((friend) => friend as Map<String, dynamic>).toList();
  }

  Future<Group> createGroup({
    required String name,
    required String createdBy,
    required List<String> memberIds,
    String? description,
  }) async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Please log in again');
    }

    final response = await http.post(
      Uri.parse(baseUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'name': name,
        'createdBy': createdBy,
        'memberIds': memberIds,
        'description': description,
      }),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Group.fromJson(jsonDecode(response.body));
    }

    throw Exception(
      'Failed to create group: ${response.statusCode} ${response.body}',
    );
  }

  Future<String> joinGroup({required String inviteCode}) async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Please log in again');
    }

    final response = await http.post(
      Uri.parse('$baseUrl/join'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'inviteCode': inviteCode}),
    );

    final body = response.body.trim();

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (body.startsWith('{') || body.startsWith('[')) {
        try {
          final decoded = jsonDecode(body);

          if (decoded is Map<String, dynamic>) {
            return decoded['message'] ?? 'Joined group successfully';
          }

          if (decoded is String) {
            return decoded;
          }
        } catch (_) {}
      }

      return body.isNotEmpty ? body : 'Joined group successfully';
    }

    String message = 'Failed to join group';

    if (body.startsWith('{')) {
      try {
        final error = jsonDecode(body);

        if (error is Map<String, dynamic> && error['message'] != null) {
          message = error['message'];
        }
      } catch (_) {}
    } else if (body.isNotEmpty) {
      message = body;
    }

    throw Exception(message);
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

  Future<List<GroupBalance>> getGroupBalances(String groupId) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/$groupId/balances'),
      headers: headers,
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((balance) => GroupBalance.fromJson(balance)).toList();
    }

    throw Exception('Failed to load balances: ${response.statusCode}');
  }

  Future<List<SettlementSuggestion>> getSettlementSuggestions(
    String groupId,
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
      'Failed to load settlement suggestions: ${response.statusCode}',
    );
  }

  Future<void> leaveGroup(String groupId) async {
    final headers = await _headers();

    final response = await http.delete(
      Uri.parse('$baseUrl/$groupId/leave'),
      headers: headers,
    );

    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<void> deleteGroup(String groupId) async {
    final headers = await _headers();

    final response = await http.delete(
      Uri.parse('$baseUrl/$groupId'),
      headers: headers,
    );

    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$friendsBaseUrl/request'),
      headers: headers,
      body: jsonEncode({'receiverId': userId}),
    );

    if (response.statusCode >= 400) {
      throw Exception(_errorMessage(response));
    }
  }

  Future<GroupExpenseDetail> getGroupExpenseDetail({
    required String groupId,
    required String expenseId,
  }) async {
    final headers = await _headers();

    final response = await http.get(
      Uri.parse('$baseUrl/$groupId/expenses/$expenseId'),
      headers: headers,
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

  Future<void> recordSettlement({
    required String groupId,
    required String paidBy,
    required String paidTo,
    required double amount,
    required String settlementDate,
    bool addToPersonalFinance = false,
  }) async {
    final headers = await _headers();

    final response = await http.post(
      Uri.parse('$baseUrl/$groupId/settlements'),
      headers: headers,
      body: jsonEncode({
        'paidBy': paidBy,
        'paidTo': paidTo,
        'amount': amount,
        'settlementDate': settlementDate,
        'addToPersonalFinance': addToPersonalFinance,
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
    required String groupId,
    required String description,
    required double amount,
    required String expenseDate,
    required String paidBy,
    required String categoryId,
    required List<String> memberIds,
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

  Future<void> updateGroupExpense({
    required String groupId,
    required String expenseId,
    required String description,
    required double amount,
    required String expenseDate,
    required String paidBy,
    required String categoryId,
    required List<String> memberIds,
  }) async {
    final headers = await _headers();

    final response = await http.put(
      Uri.parse('$baseUrl/$groupId/expenses/$expenseId'),
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
        'Failed to update expense: '
        '${response.statusCode} ${response.body}',
      );
    }
  }

  Future<List<SettlementRecord>> getSettlementHistory(String groupId) async {
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
      'Failed to load settlement history: ${response.statusCode}',
    );
  }

  Future<void> deleteGroupExpense({
    required String groupId,
    required String expenseId,
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

  Future<List<GroupExpense>> getGroupExpenses(String groupId) async {
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

    throw Exception('Failed to load expenses: ${response.statusCode}');
  }
}
