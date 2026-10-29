import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

void main() {
  runApp(const HammasirApp());
}

// ------------------------------------------------------------
// API
// ------------------------------------------------------------

class ApiService {
  // برای گوشی فیزیکی از adb reverse استفاده می‌کنیم.
  static const String baseUrl = 'http://127.0.0.1:8000';

  static String? accessToken;
  static UserProfile? currentUser;

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

  static void logout() {
    accessToken = null;
    currentUser = null;
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => message;
}

class UserProfile {
  final int id;
  final String username;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String role;
  final int? universityId;
  final int? transportCompanyId;
  final int? studentId;
  final int? driverId;
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.username,
    this.firstName,
    this.lastName,
    this.phone,
    required this.role,
    this.universityId,
    this.transportCompanyId,
    this.studentId,
    this.driverId,
    required this.isActive,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: _toInt(json['id']) ?? 0,
      username: json['username']?.toString() ?? '',
      firstName: json['first_name']?.toString(),
      lastName: json['last_name']?.toString(),
      phone: json['phone']?.toString(),
      role: json['role']?.toString() ?? '',
      universityId: _toInt(json['university_id']),
      transportCompanyId: _toInt(json['transport_company_id']),
      studentId: _toInt(json['student_id']),
      driverId: _toInt(json['driver_id']),
      isActive: json['is_active'] == true,
    );
  }

  String get fullName {
    final name = [
      if (firstName != null && firstName!.trim().isNotEmpty) firstName!,
      if (lastName != null && lastName!.trim().isNotEmpty) lastName!,
    ].join(' ');

    return name.isEmpty ? 'دانشجو' : name;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;

    if (value is int) return value;

    return int.tryParse(value.toString());
  }
}

// ------------------------------------------------------------
// APP
// ------------------------------------------------------------

class HammasirApp extends StatelessWidget {
  const HammasirApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'هم‌مسیر',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Vazirmatn',
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF087F8C),
        ),
        scaffoldBackgroundColor: const Color(0xFFF7F9FA),
      ),
      home: const SplashPage(),
    );
  }
}

// ------------------------------------------------------------
// SPLASH
// ------------------------------------------------------------

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(milliseconds: 1600), () {
      if (!mounted) return;

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoginPage(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF087F8C),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_bus_rounded,
                size: 52,
                color: Color(0xFF087F8C),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'هم‌مسیر',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'همراه تو در مسیر دانشگاه',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// LOGIN
// ------------------------------------------------------------

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  bool obscurePassword = true;
  bool isLoading = false;

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();

    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      _showError('شماره دانشجویی و رمز عبور را وارد کنید.');
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final user = await ApiService.login(
        username: username,
        password: password,
      );

      if (!mounted) return;

      if (user.role != 'student') {
        ApiService.logout();
        _showError('این حساب کاربری مربوط به دانشجو نیست.');
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const MainNavigation(),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      _showError(e.message);
    } catch (_) {
      if (!mounted) return;
      _showError(
        'ارتباط با سرور برقرار نشد. اتصال اینترنت و وضعیت سرور را بررسی کنید.',
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FA),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 430,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F3F4),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      size: 42,
                      color: Color(0xFF087F8C),
                    ),
                  ),
                  const SizedBox(height: 25),
                  const Text(
                    'ورود به هم‌مسیر',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'برای استفاده از خدمات سرویس دانشجویی وارد حساب خود شوید.',
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      height: 1.7,
                    ),
                  ),
                  const SizedBox(height: 30),
                  TextField(
                    controller: usernameController,
                    textDirection: TextDirection.ltr,
                    keyboardType: TextInputType.text,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      labelText: 'شماره دانشجویی',
                      hintText: 'مثلاً ۱۴۰۲۰۰۱۲۳',
                      prefixIcon: const Icon(
                        Icons.person_outline_rounded,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8EA),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF087F8C),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    textDirection: TextDirection.ltr,
                    enabled: !isLoading,
                    onSubmitted: (_) => _login(),
                    decoration: InputDecoration(
                      labelText: 'رمز عبور',
                      prefixIcon: const Icon(
                        Icons.lock_outline_rounded,
                      ),
                      suffixIcon: IconButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setState(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFFE2E8EA),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: const BorderSide(
                          color: Color(0xFF087F8C),
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton(
                      onPressed: isLoading ? null : () {},
                      child: const Text(
                        'فراموشی رمز عبور',
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    height: 54,
                    child: FilledButton(
                      onPressed: isLoading ? null : _login,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF087F8C),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'ورود',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'اطلاعات ورود توسط دانشگاه در اختیار شما قرار می‌گیرد.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.black38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// MAIN NAVIGATION
// ------------------------------------------------------------

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int currentIndex = 0;

  final pages = const [
    HomePage(),
    TripsPage(),
    NotificationsPage(),
    ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() => currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'خانه',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_bus_outlined),
            selectedIcon: Icon(Icons.directions_bus),
            label: 'سفرها',
          ),
          NavigationDestination(
            icon: Icon(Icons.notifications_none),
            selectedIcon: Icon(Icons.notifications),
            label: 'اعلان‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'پروفایل',
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// HOME
// ------------------------------------------------------------

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  static const LatLng universityLocation = LatLng(35.7219, 51.3347);

  static final List<LatLng> routePoints = [
    const LatLng(35.7219, 51.3347),
    const LatLng(35.7209, 51.3362),
    const LatLng(35.7198, 51.3376),
    const LatLng(35.7187, 51.3390),
    const LatLng(35.7175, 51.3405),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE3F3F4),
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: const Icon(
                      Icons.directions_bus_rounded,
                      color: Color(0xFF087F8C),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'هم‌مسیر',
                          style: TextStyle(
                            fontSize: 21,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'همراه تو در مسیر دانشگاه',
                          style: TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.notifications_none_rounded),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _MapCard(
                center: universityLocation,
                routePoints: routePoints,
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'سرویس‌های نزدیک شما',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: const Text('همه'),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _ServiceCard(
                onDetails: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ServiceDetailsPage(),
                    ),
                  );
                },
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
            sliver: SliverToBoxAdapter(
              child: _ActiveTripCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TripStatusPage(),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// MAP
// ------------------------------------------------------------

class _MapCard extends StatelessWidget {
  final LatLng center;
  final List<LatLng> routePoints;

  const _MapCard({
    required this.center,
    required this.routePoints,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 270,
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                initialCenter: center,
                initialZoom: 15.8,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'ir.hammasir.student_transport',
                  maxZoom: 19,
                ),
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: routePoints,
                      strokeWidth: 5,
                      color: const Color(0xFF087F8C),
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: routePoints.first,
                      width: 42,
                      height: 42,
                      child: _MapMarker(
                        icon: Icons.school_rounded,
                        color: const Color(0xFF087F8C),
                      ),
                    ),
                    Marker(
                      point: routePoints[2],
                      width: 42,
                      height: 42,
                      child: _MapMarker(
                        icon: Icons.directions_bus_rounded,
                        color: const Color(0xFFEF7D32),
                      ),
                    ),
                    Marker(
                      point: routePoints.last,
                      width: 42,
                      height: 42,
                      child: _MapMarker(
                        icon: Icons.home_rounded,
                        color: const Color(0xFF5B6B7A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Positioned(
              top: 12,
              right: 12,
              child: _MapStatusBadge(),
            ),
            Positioned(
              bottom: 12,
              left: 12,
              child: Material(
                color: Colors.white,
                elevation: 3,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {},
                  child: const Padding(
                    padding: EdgeInsets.all(11),
                    child: Icon(
                      Icons.my_location_rounded,
                      size: 21,
                      color: Color(0xFF087F8C),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapMarker extends StatelessWidget {
  final IconData icon;
  final Color color;

  const _MapMarker({
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 3,
        ),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black26,
          ),
        ],
      ),
      child: Icon(
        icon,
        color: Colors.white,
        size: 21,
      ),
    );
  }
}

class _MapStatusBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            blurRadius: 8,
            color: Colors.black12,
          ),
        ],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.circle,
            size: 8,
            color: Color(0xFF2E9B62),
          ),
          SizedBox(width: 6),
          Text(
            'سرویس فعال',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// SERVICE CARD
// ------------------------------------------------------------

class _ServiceCard extends StatelessWidget {
  final VoidCallback onDetails;

  const _ServiceCard({
    required this.onDetails,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5F6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.directions_bus_rounded,
                    color: Color(0xFF087F8C),
                    size: 27,
                  ),
                ),
                const SizedBox(width: 13),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'پردیس → خوابگاه آوینی',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 5),
                      Text(
                        'مینی‌بوس ۳',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF7EF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'فعال',
                    style: TextStyle(
                      color: Color(0xFF277A4B),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 17),
            const Row(
              children: [
                Expanded(
                  child: _ServiceInfo(
                    icon: Icons.event_seat_outlined,
                    title: '۷ صندلی',
                    subtitle: 'خالی',
                  ),
                ),
                Expanded(
                  child: _ServiceInfo(
                    icon: Icons.location_on_outlined,
                    title: '۲ ایستگاه',
                    subtitle: 'تا شما',
                  ),
                ),
                Expanded(
                  child: _ServiceInfo(
                    icon: Icons.access_time_rounded,
                    title: '۴ دقیقه',
                    subtitle: 'تا ایستگاه',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: onDetails,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF087F8C),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('مشاهده جزئیات'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceInfo extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ServiceInfo({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: const Color(0xFF087F8C),
        ),
        const SizedBox(height: 5),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          subtitle,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

// ------------------------------------------------------------
// ACTIVE TRIP
// ------------------------------------------------------------

class _ActiveTripCard extends StatelessWidget {
  final VoidCallback onTap;

  const _ActiveTripCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFEAF6F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(17),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Color(0xFF087F8C),
                child: Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'وضعیت سفر من',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'رزرو شما تأیید شده است',
                      style: TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF087F8C),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// SERVICE DETAILS
// ------------------------------------------------------------

class ServiceDetailsPage extends StatefulWidget {
  const ServiceDetailsPage({super.key});

  @override
  State<ServiceDetailsPage> createState() => _ServiceDetailsPageState();
}

class _ServiceDetailsPageState extends State<ServiceDetailsPage> {
  String selectedStation = 'ایستگاه اصلی دانشگاه';

  static const LatLng center = LatLng(35.7219, 51.3347);

  static final List<LatLng> routePoints = [
    const LatLng(35.7219, 51.3347),
    const LatLng(35.7209, 51.3362),
    const LatLng(35.7198, 51.3376),
    const LatLng(35.7187, 51.3390),
    const LatLng(35.7175, 51.3405),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('جزئیات سرویس'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 30),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: SizedBox(
                height: 260,
                child: FlutterMap(
                  options: MapOptions(
                    initialCenter: center,
                    initialZoom: 15.8,
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName:
                          'ir.hammasir.student_transport',
                      maxZoom: 19,
                    ),
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: routePoints,
                          strokeWidth: 5,
                          color: const Color(0xFF087F8C),
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePoints[0],
                          width: 42,
                          height: 42,
                          child: _MapMarker(
                            icon: Icons.school_rounded,
                            color: const Color(0xFF087F8C),
                          ),
                        ),
                        Marker(
                          point: routePoints[2],
                          width: 42,
                          height: 42,
                          child: _MapMarker(
                            icon: Icons.directions_bus_rounded,
                            color: const Color(0xFFEF7D32),
                          ),
                        ),
                        Marker(
                          point: routePoints[4],
                          width: 42,
                          height: 42,
                          child: _MapMarker(
                            icon: Icons.home_rounded,
                            color: const Color(0xFF5B6B7A),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _ServiceHeader(),
            const SizedBox(height: 16),
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(
                  color: Color(0xFFE3E8EA),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ایستگاه سوارشدن',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 9),
                    DropdownButtonFormField<String>(
                      value: selectedStation,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: const Color(0xFFF6F8F9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'ایستگاه اصلی دانشگاه',
                          child: Text('ایستگاه اصلی دانشگاه'),
                        ),
                        DropdownMenuItem(
                          value: 'ایستگاه دانشکده',
                          child: Text('ایستگاه دانشکده'),
                        ),
                        DropdownMenuItem(
                          value: 'ایستگاه خوابگاه',
                          child: Text('ایستگاه خوابگاه'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedStation = value;
                          });
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            const _CapacityCard(),
            const SizedBox(height: 16),
            const _InfoRow(
              icon: Icons.access_time_rounded,
              title: 'زمان تقریبی رسیدن',
              value: '۴ دقیقه',
            ),
            const _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'مقصد',
              value: 'خوابگاه آوینی',
            ),
            const _InfoRow(
              icon: Icons.directions_bus_outlined,
              title: 'وسیله نقلیه',
              value: 'مینی‌بوس ۳',
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () {
                  _showReservationSheet(context);
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF087F8C),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
                child: const Text(
                  'درخواست سوارشدن',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showReservationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'انتخاب نوع سفر',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFE7F5F6),
                    child: Icon(
                      Icons.event_seat_outlined,
                      color: Color(0xFF087F8C),
                    ),
                  ),
                  title: const Text('صندلی'),
                  subtitle: const Text('رزرو یک صندلی'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmation(context, 'صندلی');
                  },
                ),
                const SizedBox(height: 6),
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF1E8),
                    child: Icon(
                      Icons.accessibility_new_rounded,
                      color: Color(0xFFEF7D32),
                    ),
                  ),
                  title: const Text('سفر ایستاده'),
                  subtitle: const Text('در صورت تکمیل صندلی‌ها'),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () {
                    Navigator.pop(context);
                    _showConfirmation(context, 'ایستاده');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showConfirmation(
    BuildContext context,
    String type,
  ) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('درخواست ثبت شد'),
          content: Text(
            'درخواست سفر $type برای ایستگاه «$selectedStation» ثبت شد.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('باشه'),
            ),
          ],
        );
      },
    );
  }
}

class _ServiceHeader extends StatelessWidget {
  const _ServiceHeader();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFEAF6F7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Padding(
        padding: EdgeInsets.all(17),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: Color(0xFF087F8C),
              child: Icon(
                Icons.directions_bus_rounded,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'پردیس → خوابگاه آوینی',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    'مینی‌بوس ۳ • در حال حرکت',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityCard extends StatelessWidget {
  const _CapacityCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(17),
        child: Row(
          children: [
            Expanded(
              child: _CapacityItem(
                icon: Icons.event_seat_outlined,
                value: '۷',
                title: 'صندلی خالی',
              ),
            ),
            Expanded(
              child: _CapacityItem(
                icon: Icons.accessibility_new_rounded,
                value: '۳',
                title: 'ظرفیت ایستاده',
              ),
            ),
            Expanded(
              child: _CapacityItem(
                icon: Icons.people_outline_rounded,
                value: '۱۳',
                title: 'مسافر',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CapacityItem extends StatelessWidget {
  final IconData icon;
  final String value;
  final String title;

  const _CapacityItem({
    required this.icon,
    required this.value,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(
          icon,
          color: const Color(0xFF087F8C),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 10,
            color: Colors.black54,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            icon,
            color: const Color(0xFF087F8C),
            size: 21,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Colors.black54,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ------------------------------------------------------------
// TRIP STATUS
// ------------------------------------------------------------

class TripStatusPage extends StatelessWidget {
  const TripStatusPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('وضعیت سفر'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 0,
              color: const Color(0xFFEAF6F7),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Color(0xFF087F8C),
                      child: Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'رزرو شما تأیید شده است',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'سرویس در حال نزدیک‌شدن به ایستگاه شماست.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            const _TripProgress(),
            const SizedBox(height: 18),
            const _InfoRow(
              icon: Icons.location_on_outlined,
              title: 'ایستگاه سوارشدن',
              value: 'ایستگاه اصلی دانشگاه',
            ),
            const _InfoRow(
              icon: Icons.access_time_rounded,
              title: 'زمان تقریبی رسیدن',
              value: '۴ دقیقه',
            ),
            const _InfoRow(
              icon: Icons.directions_bus_outlined,
              title: 'وسیله',
              value: 'مینی‌بوس ۳',
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('لغو رزرو'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TripProgress extends StatelessWidget {
  const _TripProgress();

  @override
  Widget build(BuildContext context) {
    final steps = [
      ('رزرو تأیید شد', true),
      ('خودرو در مسیر', true),
      ('نزدیک ایستگاه', true),
      ('سوارشدن', false),
      ('پایان سفر', false),
    ];

    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: List.generate(
            steps.length,
            (index) {
              final item = steps[index];

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      CircleAvatar(
                        radius: 11,
                        backgroundColor: item.$2
                            ? const Color(0xFF087F8C)
                            : const Color(0xFFE1E6E8),
                        child: item.$2
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 14,
                              )
                            : null,
                      ),
                      if (index != steps.length - 1)
                        Container(
                          width: 2,
                          height: 28,
                          color: item.$2
                              ? const Color(0xFF087F8C)
                              : const Color(0xFFE1E6E8),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      item.$1,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            item.$2 ? FontWeight.bold : FontWeight.normal,
                        color: item.$2 ? Colors.black87 : Colors.black45,
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// TRIPS
// ------------------------------------------------------------

class TripsPage extends StatelessWidget {
  const TripsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 18, 16, 10),
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'سفرهای من',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const TabBar(
              tabs: [
                Tab(text: 'امروز'),
                Tab(text: 'آینده'),
                Tab(text: 'گذشته'),
              ],
            ),
            const Expanded(
              child: TabBarView(
                children: [
                  _TodayTrips(),
                  _UpcomingTrips(),
                  _PastTrips(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayTrips extends StatelessWidget {
  const _TodayTrips();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _TripListCard(
          title: 'پردیس → خوابگاه آوینی',
          time: '۱۴:۳۰',
          status: 'تأیید شده',
          statusColor: Color(0xFF277A4B),
        ),
      ],
    );
  }
}

class _UpcomingTrips extends StatelessWidget {
  const _UpcomingTrips();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _TripListCard(
          title: 'خوابگاه آوینی → پردیس',
          time: '۰۷:۳۰',
          status: 'رزرو شده',
          statusColor: Color(0xFF087F8C),
        ),
      ],
    );
  }
}

class _PastTrips extends StatelessWidget {
  const _PastTrips();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _TripListCard(
          title: 'پردیس → خوابگاه آوینی',
          time: '۱۴:۳۰',
          status: 'تکمیل شده',
          statusColor: Color(0xFF68747D),
        ),
        SizedBox(height: 10),
        _TripListCard(
          title: 'خوابگاه آوینی → پردیس',
          time: '۰۷:۳۰',
          status: 'عدم حضور ثبت شد',
          statusColor: Color(0xFF68747D),
        ),
      ],
    );
  }
}

class _TripListCard extends StatelessWidget {
  final String title;
  final String time;
  final String status;
  final Color statusColor;

  const _TripListCard({
    required this.title,
    required this.time,
    required this.status,
    required this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF6F7),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.directions_bus_outlined,
                color: Color(0xFF087F8C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 6,
              ),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                status,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// NOTIFICATIONS
// ------------------------------------------------------------

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          Padding(
            padding: EdgeInsets.only(bottom: 18),
            child: Text(
              'اعلان‌ها',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          _NotificationCard(
            icon: Icons.directions_bus_rounded,
            title: 'سرویس در حال نزدیک‌شدن است',
            message: 'مینی‌بوس ۳ حدود ۴ دقیقه دیگر به ایستگاه می‌رسد.',
            time: 'چند دقیقه پیش',
          ),
          SizedBox(height: 10),
          _NotificationCard(
            icon: Icons.check_circle_outline,
            title: 'رزرو تأیید شد',
            message: 'رزرو شما برای سرویس پردیس به خوابگاه آوینی تأیید شد.',
            time: 'امروز',
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: const Color(0xFFEAF6F7),
              child: Icon(
                icon,
                color: const Color(0xFF087F8C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    time,
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black38,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// PROFILE
// ------------------------------------------------------------

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser;

    final displayName = user?.fullName ?? 'دانشجو';
    final studentNumber = user?.username ?? '---';

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: Text(
              'پروفایل',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Card(
            elevation: 0,
            color: const Color(0xFFEAF6F7),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 30,
                    backgroundColor: Color(0xFF087F8C),
                    child: Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          displayName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'شماره دانشجویی: $studentNumber',
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          _ProfileItem(
            icon: Icons.person_outline,
            title: 'اطلاعات حساب',
            onTap: () {},
          ),
          _ProfileItem(
            icon: Icons.lock_outline,
            title: 'تغییر رمز عبور',
            onTap: () {},
          ),
          _ProfileItem(
            icon: Icons.notifications_none,
            title: 'تنظیمات اعلان‌ها',
            onTap: () {},
          ),
          _ProfileItem(
            icon: Icons.language,
            title: 'زبان',
            trailing: 'فارسی',
            onTap: () {},
          ),
          _ProfileItem(
            icon: Icons.dark_mode_outlined,
            title: 'حالت نمایش',
            trailing: 'روشن',
            onTap: () {},
          ),
          _ProfileItem(
            icon: Icons.help_outline,
            title: 'راهنما',
            onTap: () {},
          ),
          _ProfileItem(
            icon: Icons.logout,
            title: 'خروج از حساب',
            color: Colors.redAccent,
            onTap: () {
              ApiService.logout();

              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(
                  builder: (_) => const LoginPage(),
                ),
                (route) => false,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Color? color;
  final VoidCallback onTap;

  const _ProfileItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final itemColor = color ?? Colors.black87;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(
          color: Color(0xFFE8ECEE),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          icon,
          color: color ?? const Color(0xFF087F8C),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: itemColor,
            fontSize: 14,
          ),
        ),
        trailing: trailing != null
            ? Text(
                trailing!,
                style: const TextStyle(
                  color: Colors.black45,
                  fontSize: 12,
                ),
              )
            : const Icon(
                Icons.chevron_left,
                color: Colors.black38,
              ),
      ),
    );
  }
}