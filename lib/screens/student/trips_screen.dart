import 'package:flutter/material.dart';

import '../../app/theme.dart';

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
                      backgroundColor: HammasirTheme.primary,
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
                            ? HammasirTheme.primary
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
                              ? HammasirTheme.primary
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
          statusColor: HammasirTheme.primary,
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
                color: HammasirTheme.primary,
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