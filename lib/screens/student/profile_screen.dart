import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../services/api_service.dart';
import '../login/login_screen.dart';

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
                    backgroundColor: HammasirTheme.primary,
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
            onTap: () async {
              await ApiService.logout();

              if (!context.mounted) return;

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
          color: color ?? HammasirTheme.primary,
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