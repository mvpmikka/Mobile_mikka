import 'dart:async';

import 'package:flutter/material.dart';

import '../models/place.dart';
import '../theme/app_colors.dart';
import 'place_detail_screen.dart';

class AlreadyCheckedInScreen extends StatefulWidget {
  const AlreadyCheckedInScreen({
    super.key,
    required this.place,
    required this.cooldownEndsAt,
  });

  final Place place;
  final DateTime cooldownEndsAt;

  @override
  State<AlreadyCheckedInScreen> createState() =>
      _AlreadyCheckedInScreenState();
}

class _AlreadyCheckedInScreenState extends State<AlreadyCheckedInScreen> {
  late int _secondsLeft = _computeSecondsLeft();
  Timer? _timer;

  int _computeSecondsLeft() {
    final diff = widget.cooldownEndsAt.difference(DateTime.now()).inSeconds;
    return diff > 0 ? diff : 0;
  }

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final secondsLeft = _computeSecondsLeft();
      if (secondsLeft <= 0) {
        _timer?.cancel();
        setState(() => _secondsLeft = 0);
        return;
      }
      setState(() => _secondsLeft = secondsLeft);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String get _formatted {
    final minutes = _secondsLeft ~/ 60;
    final seconds = _secondsLeft % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hourglass_bottom,
                  color: AppColors.orange,
                  size: 44,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Already checked-in',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'You can check in again at ${widget.place.name} in:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedText(context),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _formatted,
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.w800,
                  color: AppColors.orange,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => PlaceDetailScreen(place: widget.place),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.darkText(context),
                    side: BorderSide(color: AppColors.fieldBorder(context)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'View my check-in',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.mutedText(context),
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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
