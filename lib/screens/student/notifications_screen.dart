import 'package:flutter/material.dart';

import '../../app/theme.dart';

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