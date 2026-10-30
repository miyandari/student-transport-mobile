import 'package:flutter/material.dart';

import '../../app/app.dart';
import '../../services/api_service.dart';

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
        await ApiService.logout();

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