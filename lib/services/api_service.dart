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
  // Services
  // =========================================================

  static Future<List<ServiceData>> getServices({
    int? universityId,
    int? routeId,
    bool? isActive,
  }) async {
    final queryParameters = <String, String>{};

    if (universityId != null) {
      queryParameters['university_id'] = universityId.toString();
    }

    if (routeId != null) {
      queryParameters['route_id'] = routeId.toString();
    }

    if (isActive != null) {
      queryParameters['is_active'] = isActive.toString();
    }

    final uri = Uri.parse('$baseUrl/services/').replace(
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
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
          'دریافت سرویس‌ها ناموفق بود',
        ),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException('اطلاعات سرویس‌ها نامعتبر است');
    }

    return data
        .whereType<Map<String, dynamic>>()
        .map(ServiceData.fromJson)
        .toList();
  }

  // =========================================================
  // Routes
  // =========================================================

  static Future<List<RouteStationData>> getRouteStations({
    required int routeId,
  }) async {
    final uri = Uri.parse('$baseUrl/route-stations/').replace(
      queryParameters: {
        'route_id': routeId.toString(),
      },
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
          'دریافت ایستگاه‌های مسیر ناموفق بود',
        ),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! List) {
      throw ApiException(
        'اطلاعات ایستگاه‌های مسیر نامعتبر است',
      );
    }

    final stations = data
        .whereType<Map<String, dynamic>>()
        .map(RouteStationData.fromJson)
        .toList();

    stations.sort(
      (a, b) => a.stopOrder.compareTo(b.stopOrder),
    );

    return stations;
  }

  // =========================================================
  // Stations
  // =========================================================

  static Future<StationData> getStation(
    int stationId,
  ) async {
    final response = await http.get(
      Uri.parse('$baseUrl/stations/$stationId'),
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
          'دریافت اطلاعات ایستگاه ناموفق بود',
        ),
      );
    }

    final data = jsonDecode(response.body);

    if (data is! Map<String, dynamic>) {
      throw ApiException(
        'اطلاعات ایستگاه نامعتبر است',
      );
    }

    return StationData.fromJson(data);
  }

  static Future<List<StationData>> getStationsForRoute({
    required int routeId,
  }) async {
    final routeStations = await getRouteStations(
      routeId: routeId,
    );

    if (routeStations.isEmpty) {
      return [];
    }

    final stations = <StationData>[];

    for (final routeStation in routeStations) {
      try {
        final station = await getStation(
          routeStation.stationId,
        );

        stations.add(
          station.copyWith(
            stopOrder: routeStation.stopOrder,
            estimatedMinutesFromStart:
                routeStation.estimatedMinutesFromStart,
            stopDurationSeconds:
                routeStation.stopDurationSeconds,
          ),
        );
      } catch (_) {
        // اگر اطلاعات یک ایستگاه قابل دریافت نبود،
        // سایر ایستگاه‌های مسیر همچنان نمایش داده شوند.
      }
    }

    stations.sort(
      (a, b) => (a.stopOrder ?? 0).compareTo(
        b.stopOrder ?? 0,
      ),
    );

    return stations;
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
      queryParameters:
          queryParameters.isEmpty ? null : queryParameters,
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
    int? stationId,
    required bool isStanding,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/reservations/'),
      headers: _authHeaders(),
      body: jsonEncode({
        'trip_id': tripId,
        'student_id': studentId,
        'station_id': stationId,
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
// Service Data
// =========================================================

class ServiceData {
  final int id;
  final int universityId;
  final int routeId;
  final int? contractId;

  final String name;
  final String code;
  final String serviceType;
  final String genderRestriction;

  final bool isActive;

  const ServiceData({
    required this.id,
    required this.universityId,
    required this.routeId,
    this.contractId,
    required this.name,
    required this.code,
    required this.serviceType,
    required this.genderRestriction,
    required this.isActive,
  });

  factory ServiceData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ServiceData(
      id: _toInt(json['id']) ?? 0,
      universityId:
          _toInt(json['university_id']) ?? 0,
      routeId:
          _toInt(json['route_id']) ?? 0,
      contractId:
          _toInt(json['contract_id']),
      name:
          json['name']?.toString() ?? '',
      code:
          json['code']?.toString() ?? '',
      serviceType:
          json['service_type']?.toString() ?? '',
      genderRestriction:
          json['gender_restriction']?.toString() ??
              'mixed',
      isActive:
          json['is_active'] == true,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }
}

// =========================================================
// Route Station Data
// =========================================================

class RouteStationData {
  final int id;
  final int routeId;
  final int stationId;
  final int stopOrder;
  final int? estimatedMinutesFromStart;
  final int? stopDurationSeconds;

  const RouteStationData({
    required this.id,
    required this.routeId,
    required this.stationId,
    required this.stopOrder,
    this.estimatedMinutesFromStart,
    this.stopDurationSeconds,
  });

  factory RouteStationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return RouteStationData(
      id: _toInt(json['id']) ?? 0,
      routeId:
          _toInt(json['route_id']) ?? 0,
      stationId:
          _toInt(json['station_id']) ?? 0,
      stopOrder:
          _toInt(json['stop_order']) ?? 0,
      estimatedMinutesFromStart:
          _toInt(
            json['estimated_minutes_from_start'],
          ),
      stopDurationSeconds:
          _toInt(
            json['stop_duration_seconds'],
          ),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }
}

// =========================================================
// Station Data
// =========================================================

class StationData {
  final int id;
  final int universityId;

  final String name;
  final String? address;

  final double? latitude;
  final double? longitude;

  final bool isActive;

  final int? stopOrder;
  final int? estimatedMinutesFromStart;
  final int? stopDurationSeconds;

  const StationData({
    required this.id,
    required this.universityId,
    required this.name,
    this.address,
    this.latitude,
    this.longitude,
    required this.isActive,
    this.stopOrder,
    this.estimatedMinutesFromStart,
    this.stopDurationSeconds,
  });

  factory StationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return StationData(
      id: _toInt(json['id']) ?? 0,
      universityId:
          _toInt(json['university_id']) ?? 0,
      name:
          json['name']?.toString() ?? '',
      address:
          json['address']?.toString(),
      latitude:
          _toDouble(json['latitude']),
      longitude:
          _toDouble(json['longitude']),
      isActive:
          json['is_active'] == true,
    );
  }

  StationData copyWith({
    int? stopOrder,
    int? estimatedMinutesFromStart,
    int? stopDurationSeconds,
  }) {
    return StationData(
      id: id,
      universityId: universityId,
      name: name,
      address: address,
      latitude: latitude,
      longitude: longitude,
      isActive: isActive,
      stopOrder:
          stopOrder ?? this.stopOrder,
      estimatedMinutesFromStart:
          estimatedMinutesFromStart ??
              this.estimatedMinutesFromStart,
      stopDurationSeconds:
          stopDurationSeconds ??
              this.stopDurationSeconds,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }

    if (value is double) {
      return value;
    }

    if (value is int) {
      return value.toDouble();
    }

    return double.tryParse(
      value.toString(),
    );
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
      universityId:
          _toInt(json['university_id']) ?? 0,
      serviceId:
          _toInt(json['service_id']) ?? 0,
      scheduleId:
          _toInt(json['schedule_id']),
      driverId:
          _toInt(json['driver_id']),
      vehicleId:
          _toInt(json['vehicle_id']),
      seatedCapacity:
          _toInt(json['seated_capacity']),
      standingCapacity:
          _toInt(json['standing_capacity']),
      allowStanding:
          json['allow_standing'] == true,
      tripDate:
          _toDateTime(json['trip_date']),
      plannedDepartureTime:
          _toDateTime(
            json['planned_departure_time'],
          ),
      actualDepartureTime:
          _toNullableDateTime(
            json['actual_departure_time'],
          ),
      actualArrivalTime:
          _toNullableDateTime(
            json['actual_arrival_time'],
          ),
      status:
          json['status']?.toString() ??
              'scheduled',
      isActive:
          json['is_active'] == true,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
  }

  static DateTime _toDateTime(dynamic value) {
    return DateTime.tryParse(
          value?.toString() ?? '',
        ) ??
        DateTime.now();
  }

  static DateTime? _toNullableDateTime(
    dynamic value,
  ) {
    if (value == null) return null;

    return DateTime.tryParse(
      value.toString(),
    );
  }
}

// =========================================================
// Reservation Data
// =========================================================

class ReservationData {
  final int id;
  final int tripId;
  final int studentId;
  final int? stationId;
  final DateTime reservationTime;
  final String status;
  final bool isStanding;

  const ReservationData({
    required this.id,
    required this.tripId,
    required this.studentId,
    this.stationId,
    required this.reservationTime,
    required this.status,
    required this.isStanding,
  });

  factory ReservationData.fromJson(
    Map<String, dynamic> json,
  ) {
    return ReservationData(
      id:
          _toInt(json['id']) ?? 0,
      tripId:
          _toInt(json['trip_id']) ?? 0,
      studentId:
          _toInt(json['student_id']) ?? 0,
      stationId:
          _toInt(json['station_id']),
      reservationTime:
          DateTime.tryParse(
                json['reservation_time']
                        ?.toString() ??
                    '',
              ) ??
              DateTime.now(),
      status:
          json['status']?.toString() ?? '',
      isStanding:
          json['is_standing'] == true,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) {
      return value;
    }

    return int.tryParse(
      value.toString(),
    );
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