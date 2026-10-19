import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/auth';
  static const _storage = FlutterSecureStorage();

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    print('LOGIN RESPONSE: ${response.body}');

    final result = _handleResponse(response);

    final token = result['token'];
    final userId = result['id'];
    final userName = result['name'] ?? result['username'] ?? email;

    if (token != null) {
      await _storage.write(key: 'jwt_token', value: token.toString());
    }

    if (userId != null) {
      await _storage.write(key: 'user_id', value: userId.toString());
    }

    await _storage.write(key: 'user_name', value: userName.toString());
    await _storage.write(
      key: 'user_email',
      value: (result['email'] ?? email).toString(),
    );
    return result;
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: 'user_email');
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: 'user_name');
  }

  Future<double> getMonthlyBudget() async {
    final value = await _storage.read(key: 'monthly_budget');

    if (value == null) return 20000;

    return double.tryParse(value) ?? 20000;
  }

  Future<void> setMonthlyBudget(double budget) async {
    await _storage.write(key: 'monthly_budget', value: budget.toString());
  }

  Future<void> saveUserName(String name) async {
    await _storage.write(key: 'user_name', value: name);
  }

  Future<void> logout() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'user_id');
    await _storage.delete(key: 'user_name');
    await _storage.delete(key: 'user_email');
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    throw Exception(body['message'] ?? 'Request failed');
  }
}
