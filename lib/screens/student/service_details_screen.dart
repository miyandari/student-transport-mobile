import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../app/theme.dart';

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
                          color: HammasirTheme.primary,
                        ),
                      ],
                    ),
                    MarkerLayer(
                      markers: [
                        Marker(
                          point: routePoints[0],
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
                          point: routePoints[4],
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
                      initialValue: selectedStation,
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
                  backgroundColor: HammasirTheme.primary,
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
                      color: HammasirTheme.primary,
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
              backgroundColor: HammasirTheme.primary,
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
          color: HammasirTheme.primary,
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
            color: HammasirTheme.primary,
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