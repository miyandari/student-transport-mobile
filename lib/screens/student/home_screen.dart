import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';
import 'my_reservations_screen.dart';
import 'service_details_screen.dart';
import 'trips_screen.dart';

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
                      color: HammasirTheme.primary,
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
                    icon: const Icon(
                      Icons.notifications_none_rounded,
                    ),
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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            sliver: SliverToBoxAdapter(
              child: _MyReservationsCard(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MyReservationsPage(),
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
                      color: HammasirTheme.primary,
                    ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: routePoints.first,
                      width: 42,
                      height: 42,
                      child: const _MapMarker(
                        icon: Icons.school_rounded,
                        color: HammasirTheme.primary,
                      ),
                    ),
                    Marker(
                      point: routePoints[2],
                      width: 42,
                      height: 42,
                      child: const _MapMarker(
                        icon: Icons.directions_bus_rounded,
                        color: Color(0xFFEF7D32),
                      ),
                    ),
                    Marker(
                      point: routePoints.last,
                      width: 42,
                      height: 42,
                      child: const _MapMarker(
                        icon: Icons.home_rounded,
                        color: Color(0xFF5B6B7A),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Positioned(
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
                      color: HammasirTheme.primary,
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
  const _MapStatusBadge();

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
                    color: HammasirTheme.primary,
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
                  backgroundColor: HammasirTheme.primary,
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
          color: HammasirTheme.primary,
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

class _MyReservationsCard extends StatelessWidget {
  final VoidCallback onTap;

  const _MyReservationsCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: const Color(0xFFF5F8F9),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: Color(0xFFE3E8EA),
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: const Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFE3F3F4),
                child: Icon(
                  Icons.event_note_rounded,
                  color: HammasirTheme.primary,
                ),
              ),
              SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'رزروهای من',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'مشاهده و مدیریت رزروهای سرویس',
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
                color: HammasirTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

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
                backgroundColor: HammasirTheme.primary,
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
                color: HammasirTheme.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}