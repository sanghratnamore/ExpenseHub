import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/category.dart';
import 'auth_service.dart';

class CategoryService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/categories';
  final AuthService authService = AuthService();

  Future<List<Category>> getCategories() async {
    final token = await authService.getToken();
    final userId = await authService.getUserId();

    if (token == null || userId == null) {
      throw Exception('Please log in again');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/user/$userId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((item) => Category.fromJson(item)).toList();
    }

    throw Exception(
      'Failed to load categories: ${response.statusCode} ${response.body}',
    );
  }
}