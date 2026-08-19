import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/place_provider.dart';
import '../../theme/app_colors.dart';

/// Onboarding page 5 — Ghost Mode / Location toggles are local-only UI
/// state, illustrative of the app's privacy controls. There's no backend
/// field for either yet (PrivacySettings only has checkInVisibility /
/// storyVisibility), so nothing here is persisted.
class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  bool _ghostMode = false;
  bool _locationEnabled = true;

  Future<void> _enableLocationSharing() async {
    await ref.read(locationServiceProvider).getCurrentPosition();
    ref.invalidate(currentPositionProvider);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(
            'Privacy Settings',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "You're always in control of what you share.",
            style: TextStyle(fontSize: 14, color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 20),
          _buildToggleRow(
            title: 'Ghost Mode',
            description: 'Hide your location from everyone else.',
            value: _ghostMode,
            onChanged: (value) => setState(() => _ghostMode = value),
          ),
          Divider(color: AppColors.fieldBorder(context), height: 32),
          _buildToggleRow(
            title: 'Location',
            description: 'Share your location with friends.',
            value: _locationEnabled,
            onChanged: (value) => setState(() => _locationEnabled = value),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _enableLocationSharing,
              style: OutlinedButton.styleFrom(
                backgroundColor: AppColors.surface(context),
                foregroundColor: AppColors.darkText(context),
                side: BorderSide(color: AppColors.fieldBorder(context)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: const Text(
                'Enable Location Sharing',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppColors.orange,
        ),
      ],
    );
  }
}
