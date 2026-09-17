import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/privacy_settings.dart';
import '../providers/privacy_provider.dart';
import '../theme/app_colors.dart';

class PrivacyScreen extends ConsumerStatefulWidget {
  const PrivacyScreen({super.key});

  @override
  ConsumerState<PrivacyScreen> createState() => _PrivacyScreenState();
}

class _PrivacyScreenState extends ConsumerState<PrivacyScreen> {
  bool _saving = false;

  static const _options = [
    (value: CheckInVisibility.public, label: 'Hammaga ochiq'),
    (value: CheckInVisibility.friends, label: 'Faqat do\'stlarga'),
    (value: CheckInVisibility.private, label: 'Faqat menga'),
  ];

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(privacySettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        title: Text(
          'Maxfiylik',
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.darkText(context)),
      ),
      body: settingsAsync.when(
        loading: () =>
            const Center(child: CircularProgressIndicator(color: AppColors.orange)),
        error: (_, _) => Center(
          child: Text(
            'Yuklab bo\'lmadi',
            style: TextStyle(color: AppColors.mutedText(context)),
          ),
        ),
        data: (settings) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Check-inlarni kim ko\'ra oladi',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText(context),
                ),
              ),
              const SizedBox(height: 8),
              RadioGroup<CheckInVisibility>(
                groupValue: settings.checkInVisibility,
                onChanged: (value) {
                  if (!_saving && value != null) _update(value);
                },
                child: Column(
                  children: _options
                      .map(
                        (option) => RadioListTile<CheckInVisibility>(
                          contentPadding: EdgeInsets.zero,
                          activeColor: AppColors.orange,
                          title: Text(
                            option.label,
                            style: TextStyle(color: AppColors.darkText(context)),
                          ),
                          value: option.value,
                        ),
                      )
                      .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _update(CheckInVisibility value) async {
    setState(() => _saving = true);
    try {
      await ref.read(privacyServiceProvider).update(value);
      ref.invalidate(privacySettingsProvider);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
