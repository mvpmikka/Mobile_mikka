import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import '../../widgets/mikka_logo.dart';
import 'admin_business_register_screen.dart';
import 'widgets/admin_brand_topbar.dart';

/// Email tasdiqlash (6 xonali kod) mobil UI ekrani. Sof UI — kod haqiqatda
/// tekshirilmaydi, faqat 6 ta katak to'lganda muvaffaqiyat ekraniga o'tadi.
class AdminBusinessVerifyEmailScreen extends StatefulWidget {
  const AdminBusinessVerifyEmailScreen({super.key});

  @override
  State<AdminBusinessVerifyEmailScreen> createState() =>
      _AdminBusinessVerifyEmailScreenState();
}

class _AdminBusinessVerifyEmailScreenState
    extends State<AdminBusinessVerifyEmailScreen> {
  final List<TextEditingController> _controllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty && index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }
  }

  void _verify() {
    final code = _controllers.map((c) => c.text).join();
    if (code.length < 6) {
      _showMessage('6 xonali kodni to\'liq kiriting');
      return;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AdminBusinessRegisterSuccessScreen()),
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
                onProfile: () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(height: 40),
              Center(child: MikkaLogo(height: 56)),
              const SizedBox(height: 32),
              Text(
                'Emailingizni tasdiqlang',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Email manzilingizga 6 xonali kod yubordik.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
              ),
              const SizedBox(height: 28),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (index) {
                  return SizedBox(
                    width: 46,
                    height: 54,
                    child: TextField(
                      controller: _controllers[index],
                      focusNode: _focusNodes[index],
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      maxLength: 1,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText(context),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        filled: true,
                        fillColor: AppColors.surface(context),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: AppColors.adminGradientMid, width: 1.5),
                        ),
                      ),
                      onChanged: (value) => _onDigitChanged(index, value),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 16),
              Center(
                child: Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    Text(
                      'Kod kelmadimi? ',
                      style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                    ),
                    GestureDetector(
                      onTap: () => _showMessage('Kod qayta yuborildi'),
                      child: const Text(
                        'Qayta yuborish',
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
              const SizedBox(height: 24),
              SizedBox(
                height: 52,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.adminBrandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ElevatedButton(
                    onPressed: _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text(
                      'Emailni tasdiqlash',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton.icon(
                  onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Kirishga qaytish'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
