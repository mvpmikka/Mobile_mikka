import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../widgets/mikka_logo.dart';
import 'explore_screen.dart';

/// Shown after register/login while the account's email is still
/// unverified. Waits for the user to tap the verification link sent to
/// their inbox — the deep link handler in main.dart calls
/// [AuthController.verifyEmail], which flips [AppUser.isEmailVerified] and
/// this screen reacts by navigating to [ExploreScreen] automatically.
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
          MaterialPageRoute(builder: (_) => const ExploreScreen()),
          (route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const MikkaLogo(height: 32),
              const SizedBox(height: 40),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  size: 44,
                  color: AppColors.orange,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Emailingizni tasdiqlang',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText(context),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                '${widget.email} manziliga tasdiqlash havolasi yuborildi. '
                'Havolani bosgach, bu ekran avtomatik davom etadi.',
                style: TextStyle(fontSize: 15, color: AppColors.mutedText(context)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: _isResending ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: const BorderSide(color: AppColors.orange),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.4,
                            color: AppColors.orange,
                          ),
                        )
                      : const Text(
                          'Qayta yuborish',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
