import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/admin_brand_topbar.dart';
import 'widgets/admin_text_field.dart';

/// "Parolni tiklash" mobil UI ekrani. Sof UI — real email yuborilmaydi,
/// faqat tasdiqlovchi xabar ko'rsatilib, kirish ekraniga qaytariladi.
class AdminBusinessForgotPasswordScreen extends StatefulWidget {
  const AdminBusinessForgotPasswordScreen({super.key});

  @override
  State<AdminBusinessForgotPasswordScreen> createState() =>
      _AdminBusinessForgotPasswordScreenState();
}

class _AdminBusinessForgotPasswordScreenState
    extends State<AdminBusinessForgotPasswordScreen> {
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetLink() {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Email manzilni kiriting')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Parolni tiklash havolasi emailingizga yuborildi'),
      ),
    );
    Navigator.of(context).pop();
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
                onProfile: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 60),
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
                      'Parolni unutdingizmi',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText(context),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Email manzilingizni kiriting, biz sizga parolni tiklash '
                      'bo\'yicha ko\'rsatmalarni yuboramiz.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.mutedText(context),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    AdminTextField(
                      label: 'Email manzil',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: const Icon(Icons.mail_outline),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.adminBrandGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton(
                          onPressed: _sendResetLink,
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
                            'YUBORISH',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(color: AppColors.fieldBorder(context)),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.of(context).pop(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkText(context),
                          side: BorderSide(color: AppColors.fieldBorder(context)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.arrow_back, size: 18),
                        label: const Text('Kirishga qaytish'),
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
