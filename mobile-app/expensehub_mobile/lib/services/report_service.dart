import 'dart:convert';


import 'package:http/http.dart' as http;


import '../models/monthly_report.dart';
import 'auth_service.dart';


class ReportService {
  static const String baseUrl =
      'http://10.0.2.2:8080/api/reports';


  final AuthService authService = AuthService();


  Future<MonthlyReport> getMonthlyReport({
    required int year,
    required int month,
  }) async {
    final token = await authService.getToken();


    if (token == null) {
      throw Exception('Please log in again');
    }


    final response = await http.get(
      Uri.parse(
        '$baseUrl/monthly?year=$year&month=$month',
      ),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );


    if (response.statusCode == 200) {
      return MonthlyReport.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
    }


    if (response.statusCode == 401) {
      await authService.logout();
      throw Exception(
        'Session expired. Please log in again.',
      );
    }


    throw Exception(
      'Failed to load report: '
      '${response.statusCode} ${response.body}',
    );
  }
}