import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000';

  static const String _tokenKey = 'access_token';

  static String? accessToken;
  static UserProfile? currentUser;

  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    accessToken = prefs.getString(_tokenKey);

    if (accessToken == null || accessToken!.isEmpty) {
      return;
    }

    try {
      await getCurrentUser();
    } catch (_) {
      await logout();
    }
  }

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();

    await prefs.remove(_tokenKey);

    accessToken = null;
    currentUser = null;
  }

  static Future<UserProfile> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'username': username,
        'password': password,
      },
    );

    if (response.statusCode != 200) {
      String message = 'نام کاربری یا رمز عبور اشتباه است';

      try {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic> && data['detail'] != null) {
          message = data['detail'].toString();
        }
      } catch (_) {}

      throw ApiException(message);
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic> ||
        data['access_token'] == null ||
        data['access_token'].toString().isEmpty) {
      throw ApiException('پاسخ نامعتبر از سرور دریافت شد');
    }

    accessToken = data['access_token'].toString();

    await _saveToken(accessToken!);

    return getCurrentUser();
  }

  static Future<UserProfile> getCurrentUser() async {
    if (accessToken == null || accessToken!.isEmpty) {
      throw ApiException('توکن ورود موجود نیست');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: {
        'Authorization': 'Bearer $accessToken',
      },
    );

    if (response.statusCode != 200) {
      if (response.statusCode == 401) {
        accessToken = null;
        currentUser = null;

        throw ApiException('نشست شما منقضی شده است');
      }

      throw ApiException('دریافت اطلاعات کاربر ناموفق بود');
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException('اطلاعات کاربر نامعتبر است');
    }

    final user = UserProfile.fromJson(data);

    currentUser = user;

    return user;
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}