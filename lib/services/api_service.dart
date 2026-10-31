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

  static Map<String, String> _authHeaders() {
    if (accessToken == null || accessToken!.isEmpty) {
      throw ApiException('توکن ورود موجود نیست');
    }

    return {
      'Authorization': 'Bearer $accessToken',
      'Content-Type': 'application/json',
    };
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

  // =========================================================
  // Trips
  // =========================================================

  static Future<List<TripData>> getTrips({
    int? universityId,
    int? serviceId,
    String? status,
  }) async {
    final queryParameters = <String, String>{};

    if (universityId != null) {
      queryParameters['university_id'] = universityId.toString();
    }

    if (serviceId != null) {
      queryParameters['service_id'] = serviceId.toString();
    }

    if (status != null && status.trim().isNotEmpty) {
      queryParameters['status'] = status.trim();
    }

    final uri = Uri.parse('$baseUrl/trips/').replace(
      queryParameters: queryParameters.isEmpty ? null : queryParameters,
    );

    final response = await http.get(
      uri,
      headers: _authHeaders(),
    );

    if (response.statusCode == 401) {
      await logout();
      throw ApiException('نشست شما منقضی شده است');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(
          response,
          'دریافت سفرها ناموفق بود',
        ),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException('اطلاعات سفرها نامعتبر است');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(TripData.fromJson)
        .toList();
  }

  // =========================================================
  // Reservations
  // =========================================================

  static Future<ReservationData> createReservation({
    required int tripId,
    required int studentId,
    required bool isStanding,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/'),
      headers: _authHeaders(),
      body: jsonEncode({
        'trip_id': tripId,
        'student_id': studentId,
        'is_standing': isStanding,
      }),
    );

    if (response.statusCode == 401) {
      await logout();
      throw ApiException('نشست شما منقضی شده است');
    }

    if (response.statusCode != 201) {
      throw ApiException(
        _extractErrorMessage(
          response,
          'ثبت درخواست سوارشدن ناموفق بود',
        ),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException('پاسخ نامعتبر از سرور دریافت شد');
    }

    return ReservationData.fromJson(data);
  }

  static Future<List<ReservationData>> getReservations({
    int? tripId,
    int? studentId,
    bool onlyActive = true,
  }) async {
    final queryParameters = <String, String>{
      'only_active': onlyActive.toString(),
    };

    if (tripId != null) {
      queryParameters['trip_id'] = tripId.toString();
    }

    if (studentId != null) {
      queryParameters['student_id'] = studentId.toString();
    }

    final uri = Uri.parse('$baseUrl/reservations/').replace(
      queryParameters: queryParameters,
    );

    final response = await http.get(
      uri,
      headers: _authHeaders(),
    );

    if (response.statusCode == 401) {
      await logout();
      throw ApiException('نشست شما منقضی شده است');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(
          response,
          'دریافت رزروها ناموفق بود',
        ),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException('اطلاعات رزروها نامعتبر است');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(ReservationData.fromJson)
        .toList();
  }

  // =========================================================
  // Cancel Reservation
  // =========================================================

  static Future<ReservationData> cancelReservation(
    int reservationId,
  ) async {
    final response = await http.patch(
      Uri.parse('$baseUrl/reservations/$reservationId/cancel'),
      headers: _authHeaders(),
    );

    if (response.statusCode == 401) {
      await logout();
      throw ApiException('نشست شما منقضی شده است');
    }

    if (response.statusCode != 200) {
      throw ApiException(
        _extractErrorMessage(
          response,
          'لغو رزرو ناموفق بود',
        ),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException('پاسخ نامعتبر از سرور دریافت شد');
    }

    return ReservationData.fromJson(data);
  }

  static String _extractErrorMessage(
    http.Response response,
    String fallback,
  ) {
    try {
      final data = jsonDecode(response.body);

      if (data is Map<String, dynamic>) {
        final detail = data['detail'];

        if (detail != null) {
          if (detail is List) {
            return detail
                .map((item) {
                  if (item is Map && item['msg'] != null) {
                    return item['msg'].toString();
                  }

                  return item.toString();
                })
                .join('\n');
          }

          return detail.toString();
        }
      }
    } catch (_) {}

    return fallback;
  }
}

// =========================================================
// Trip Data
// =========================================================

class TripData {
  final int id;
  final int universityId;
  final int serviceId;
  final int? scheduleId;
  final int? driverId;
  final int? vehicleId;

  final int? seatedCapacity;
  final int? standingCapacity;
  final bool allowStanding;

  final DateTime tripDate;
  final DateTime plannedDepartureTime;
  final DateTime? actualDepartureTime;
  final DateTime? actualArrivalTime;

  final String status;
  final bool isActive;

  const TripData({
    required this.id,
    required this.universityId,
    required this.serviceId,
    this.scheduleId,
    this.driverId,
    this.vehicleId,
    this.seatedCapacity,
    this.standingCapacity,
    required this.allowStanding,
    required this.tripDate,
    required this.plannedDepartureTime,
    this.actualDepartureTime,
    this.actualArrivalTime,
    required this.status,
    required this.isActive,
  });

  factory TripData.fromJson(Map<String, dynamic> json) {
    return TripData(
      id: _toInt(json['id']) ?? 0,
      universityId: _toInt(json['university_id']) ?? 0,
      serviceId: _toInt(json['service_id']) ?? 0,
      scheduleId: _toInt(json['schedule_id']),
      driverId: _toInt(json['driver_id']),
      vehicleId: _toInt(json['vehicle_id']),
      seatedCapacity: _toInt(json['seated_capacity']),
      standingCapacity: _toInt(json['standing_capacity']),
      allowStanding: json['allow_standing'] == true,
      tripDate: _toDateTime(json['trip_date']),
      plannedDepartureTime: _toDateTime(
        json['planned_departure_time'],
      ),
      actualDepartureTime: _toNullableDateTime(
        json['actual_departure_time'],
      ),
      actualArrivalTime: _toNullableDateTime(
        json['actual_arrival_time'],
      ),
      status: json['status']?.toString() ?? 'scheduled',
      isActive: json['is_active'] == true,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }

  static DateTime _toDateTime(dynamic value) {
    return DateTime.tryParse(value?.toString() ?? '') ??
        DateTime.now();
  }

  static DateTime? _toNullableDateTime(dynamic value) {
    if (value == null) return null;

    return DateTime.tryParse(value.toString());
  }
}

// =========================================================
// Reservation Data
// =========================================================

class ReservationData {
  final int id;
  final int tripId;
  final int studentId;
  final DateTime reservationTime;
  final String status;
  final bool isStanding;

  const ReservationData({
    required this.id,
    required this.tripId,
    required this.studentId,
    required this.reservationTime,
    required this.status,
    required this.isStanding,
  });

  factory ReservationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReservationData(
      id: _toInt(json['id']) ?? 0,
      tripId: _toInt(json['trip_id']) ?? 0,
      studentId: _toInt(json['student_id']) ?? 0,
      reservationTime:
          DateTime.tryParse(
                json['reservation_time']?.toString() ?? '',
              ) ??
              DateTime.now(),
      status: json['status']?.toString() ?? '',
      isStanding: json['is_standing'] == true,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    return int.tryParse(value.toString());
  }
}

// =========================================================
// API Exception
// =========================================================

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}