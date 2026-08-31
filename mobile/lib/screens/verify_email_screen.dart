import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/mikka_logo.dart';
import 'main_shell_screen.dart';

/// Shown after register/login while the account's email is still
/// unverified. Waits for the user to tap the verification link sent to
/// their inbox — the deep link handler in main.dart calls
/// [AuthController.verifyEmail], which flips [AppUser.isEmailVerified] and
/// this screen reacts by navigating to [MainShellScreen] automatically.
class VerifyEmailScreen extends ConsumerStatefulWidget {
  const VerifyEmailScreen({super.key, required this.email});

  final String email;

  @override
  ConsumerState<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends ConsumerState<VerifyEmailScreen> {
  bool _isResending = false;

  Future<void> _resend() async {
    setState(() => _isResending = true);
    try {
      await ref.read(authControllerProvider.notifier).resendVerification();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tasdiqlash havolasi qayta yuborildi')),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(authControllerProvider, (previous, next) {
      final user = next.value?.user;
      if (user != null && user.isEmailVerified) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainShellScreen()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(child: MikkaLogo(height: 28)),
                  const SizedBox(height: 24),
                  Center(
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        size: 40,
                        color: AppColors.orange,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Emailingizni tekshiring',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${widget.email} manziliga tasdiqlash havolasi yuborildi. '
                    'Havolani bosgach, bu ekran avtomatik davom etadi.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: AppColors.mutedText(context)),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: TextButton(
                      onPressed: _isResending ? null : _resend,
                      child: _isResending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: AppColors.orange,
                              ),
                            )
                          : RichText(
                              text: const TextSpan(
                                style: TextStyle(fontSize: 14),
                                children: [
                                  TextSpan(
                                    text: 'Havola kelmadimi? ',
                                    style: TextStyle(color: AppColors.orange),
                                  ),
                                  TextSpan(
                                    text: 'Qayta yuborish',
                                    style: TextStyle(
                                      color: AppColors.orange,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
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
