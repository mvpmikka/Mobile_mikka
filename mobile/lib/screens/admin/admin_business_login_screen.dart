import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'admin_business_dashboard_screen.dart';
import 'admin_business_forgot_password_screen.dart';
import 'widgets/admin_brand_topbar.dart';
import 'widgets/admin_text_field.dart';

/// MIKKA Business uchun mobil "Kirish" ekrani. Butunlay sof UI — hech
/// qanday autentifikatsiya/backend chaqiruvi yo'q, faqat maydonlarni
/// tekshirib, boshqaruv paneliga (demo sifatida) o'tkazadi.
class AdminBusinessLoginScreen extends StatefulWidget {
  const AdminBusinessLoginScreen({super.key});

  @override
  State<AdminBusinessLoginScreen> createState() => _AdminBusinessLoginScreenState();
}

class _AdminBusinessLoginScreenState extends State<AdminBusinessLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _goToDashboard() {
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      _showMessage('Email va parolni kiriting');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminBusinessDashboardScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminBrandTopBar(
                title: 'Kirish',
                onHelp: () => _showMessage(
                  'Yordam kerakmi? Admin panel qo\'llab-quvvatlash bo\'limiga murojaat qiling.',
                ),
                onProfile: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 40),
              Center(
                child: Text(
                  'MIKKA BUSINESS',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2,
                    color: AppColors.mutedText(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.fieldBorder(context)),
                ),
                child: Column(
                  children: [
                    Text(
                      'Xush kelibsiz',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText(context),
                      ),
                    ),
                    const SizedBox(height: 20),
                    AdminTextField(
                      label: 'Email manzil',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    AdminTextField(
                      label: 'Parol',
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: AppColors.mutedText(context),
                        ),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminBusinessForgotPasswordScreen(),
                          ),
                        ),
                        child: const Text('Parolni unutdingizmi?'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.adminBrandGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _goToDashboard,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'KIRISH',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(child: Divider(color: AppColors.fieldBorder(context))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 10),
                          child: Text(
                            'yoki',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.mutedText(context),
                            ),
                          ),
                        ),
                        Expanded(child: Divider(color: AppColors.fieldBorder(context))),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: _goToDashboard,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkText(context),
                          side: BorderSide(color: AppColors.fieldBorder(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.g_mobiledata, size: 24),
                        label: const Text(
                          'GOOGLE ORQALI DAVOM ETISH',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Hisobingiz yo\'qmi? ',
                      style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                    ),
                    GestureDetector(
                      onTap: () => _showMessage(
                        'Savdo bo\'limi bilan bog\'lanish tez orada qo\'shiladi',
                      ),
                      child: const Text(
                        'Savdo bo\'limiga murojaat qiling',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.adminGradientMid,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
