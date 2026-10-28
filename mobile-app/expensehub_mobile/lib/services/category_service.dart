import 'dart:convert';

import 'package:flutter/material.dart';
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

    final url = Uri.parse('$baseUrl/me');

   

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

  
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);

      return data.map((item) => Category.fromJson(item)).toList();
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Failed to load categories: ${response.statusCode} ${response.body}',
    );
  }

  Future<Category> createCategory({
    required String name,
    required String type,
    required String userId,
  }) async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Please log in again');
    }

    final url = Uri.parse(baseUrl);
    final body = jsonEncode({
      'name': name,
      'type': type,
      'userId': userId,
    });

    debugPrint('CREATE CATEGORY URL: $url');
    debugPrint('CREATE CATEGORY BODY: $body');

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    debugPrint('CREATE CATEGORY STATUS: ${response.statusCode}');
    debugPrint('CREATE CATEGORY RESPONSE: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      return Category.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Failed to create category: ${response.statusCode} ${response.body}',
    );
  }

  Future<Category> updateCategory({
    required String categoryId,
    required String name,
    required String type,
    required String userId,
  }) async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Please log in again');
    }

    final url = Uri.parse('$baseUrl/$categoryId');
    final body = jsonEncode({
      'name': name,
      'type': type,
      'userId': userId,
    });

    debugPrint('UPDATE CATEGORY URL: $url');
    debugPrint('UPDATE CATEGORY BODY: $body');

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: body,
    );

    debugPrint('UPDATE CATEGORY STATUS: ${response.statusCode}');
    debugPrint('UPDATE CATEGORY RESPONSE: ${response.body}');

    if (response.statusCode == 200) {
      return Category.fromJson(jsonDecode(response.body));
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Failed to update category: ${response.statusCode} ${response.body}',
    );
  }

  Future<void> deleteCategory({required String categoryId}) async {
    final token = await authService.getToken();

    if (token == null) {
      throw Exception('Please log in again');
    }

    final url = Uri.parse('$baseUrl/$categoryId');

    debugPrint('DELETE CATEGORY URL: $url');

    final response = await http.delete(
      url,
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    debugPrint('DELETE CATEGORY STATUS: ${response.statusCode}');
    debugPrint('DELETE CATEGORY RESPONSE: ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 204) {
      return;
    }

    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    throw Exception(
      'Failed to delete category: ${response.statusCode} ${response.body}',
    );
  }
}