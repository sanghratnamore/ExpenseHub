import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../models/friend.dart';
import '../models/friend_request.dart';

class FriendService {
  static const String baseUrl = 'http://10.0.2.2:8080/api/friends';
  static const _storage = FlutterSecureStorage();

  Future<Map<String, String>> _headers() async {
    final token = await _storage.read(key: 'jwt_token');

    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<List<Friend>> getFriends() async {
    final response = await http.get(
      Uri.parse(baseUrl),
      headers: await _headers(),
    );

    return _handleList<Friend>(
      response,
      (item) => Friend.fromJson(item),
    );
  }

  Future<List<FriendRequest>> getIncomingRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/requests/incoming'),
      headers: await _headers(),
    );

    return _handleList<FriendRequest>(
      response,
      (item) => FriendRequest.fromJson(item),
    );
  }

  Future<List<FriendRequest>> getOutgoingRequests() async {
    final response = await http.get(
      Uri.parse('$baseUrl/requests/outgoing'),
      headers: await _headers(),
    );

    return _handleList<FriendRequest>(
      response,
      (item) => FriendRequest.fromJson(item),
    );
  }

  Future<void> sendRequest(String email) async {
    final response = await http.post(
      Uri.parse('$baseUrl/requests'),
      headers: await _headers(),
      body: jsonEncode({'email': email}),
    );

    _checkResponse(response);
  }

  Future<void> acceptRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/requests/$requestId/accept'),
      headers: await _headers(),
    );

    _checkResponse(response);
  }

  Future<void> rejectRequest(String requestId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/requests/$requestId/reject'),
      headers: await _headers(),
    );

    _checkResponse(response);
  }

  Future<void> removeFriend(String friendId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/$friendId'),
      headers: await _headers(),
    );

    _checkResponse(response);
  }

  List<T> _handleList<T>(
    http.Response response,
    T Function(Map<String, dynamic>) fromJson,
  ) {
    final body = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return (body as List)
          .map(
            (item) => fromJson(item as Map<String, dynamic>),
          )
          .toList();
    }

    throw Exception(
      body is Map && body['message'] != null
          ? body['message']
          : 'Request failed',
    );
  }

  void _checkResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return;
    }

    final body = jsonDecode(response.body);

    throw Exception(
      body is Map && body['message'] != null
          ? body['message']
          : 'Could not send friend request',
    );
  }
}