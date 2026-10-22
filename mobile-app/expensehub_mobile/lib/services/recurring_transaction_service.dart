import 'dart:convert';


import 'package:http/http.dart' as http;


import '../models/recurring_transaction.dart';
import 'auth_service.dart';


class RecurringTransactionService {
  final AuthService authService = AuthService();


  static const String baseUrl =
      'http://10.0.2.2:8080/api/recurring-transactions';


  Future<Map<String, String>> _getHeaders() async {
    final token = await authService.getToken();


    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }


  Future<List<RecurringTransaction>>
      getRecurringTransactions() async {
    final headers = await _getHeaders();


    final response = await http.get(
      Uri.parse(baseUrl),
      headers: headers,
    );


    if (response.statusCode != 200) {
      throw Exception(
        'Failed to load recurring transactions',
      );
    }


    final List<dynamic> data =
        jsonDecode(response.body);


    return data
        .map((item) =>
            RecurringTransaction.fromJson(item))
        .toList();
  }


  Future<RecurringTransaction>
      createRecurringTransaction(
          RecurringTransaction transaction) async {
    final headers = await _getHeaders();


    final response = await http.post(
      Uri.parse(baseUrl),
      headers: headers,
      body: jsonEncode(transaction.toJson()),
    );


    if (response.statusCode != 200 &&
        response.statusCode != 201) {
      throw Exception(
        'Failed to create recurring transaction',
      );
    }


    return RecurringTransaction.fromJson(
      jsonDecode(response.body),
    );
  }


  Future<void> deleteRecurringTransaction(
      int id) async {
    final headers = await _getHeaders();


    final response = await http.delete(
      Uri.parse('$baseUrl/$id'),
      headers: headers,
    );


    if (response.statusCode != 200 &&
        response.statusCode != 204) {
      throw Exception(
        'Failed to delete recurring transaction',
      );
    }
  }
}