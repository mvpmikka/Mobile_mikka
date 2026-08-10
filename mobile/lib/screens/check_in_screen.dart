import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/place.dart';
import '../providers/place_provider.dart';
import '../theme/app_colors.dart';
import '../theme/place_category_icon.dart';
import 'already_checked_in_screen.dart';
import 'checked_in_success_screen.dart';

const _moods = ['😀', '😊', '😄', '😁'];

class CheckInScreen extends ConsumerStatefulWidget {
  const CheckInScreen({super.key, required this.place});

  final Place place;

  @override
  ConsumerState<CheckInScreen> createState() => _CheckInScreenState();
}

class _CheckInScreenState extends ConsumerState<CheckInScreen> {
  final _noteController = TextEditingController();
  int _selectedMood = -1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitCheckIn() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);

    final position = await ref.read(locationServiceProvider).getCurrentPosition();
    if (position == null) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in uchun joylashuvga ruxsat kerak.'),
          backgroundColor: Color(0xFFCB4B4B),
        ),
      );
      return;
    }

    try {
      await ref
          .read(placeServiceProvider)
          .checkIn(
            widget.place.id,
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => CheckedInSuccessScreen(place: widget.place),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      if (e.statusCode == 409) {
        final cooldownEndsAt = _parseCooldownEndsAt(e.message);
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => AlreadyCheckedInScreen(
              place: widget.place,
              cooldownEndsAt: cooldownEndsAt ?? DateTime.now().add(const Duration(minutes: 15)),
            ),
          ),
        );
        return;
      }
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    }
  }

  DateTime? _parseCooldownEndsAt(String message) {
    final match = RegExp(r'after (.+)$').firstMatch(message);
    if (match == null) return null;
    return DateTime.tryParse(match.group(1) ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Check-in',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, color: AppColors.darkText),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.orange.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      placeCategoryIcon(place.category.name),
                      color: AppColors.orange,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        place.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText,
                        ),
                      ),
                      if (place.distanceLabel != null)
                        Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.mutedText,
                              size: 14,
                            ),
                            Text(
                              place.distanceLabel!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedText,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),
              const Text(
                'How are you feeling?',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(_moods.length, (index) {
                  final selected = _selectedMood == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedMood = index),
                    child: Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.orange.withValues(alpha: 0.15)
                            : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected
                              ? AppColors.orange
                              : AppColors.fieldBorder,
                          width: selected ? 2 : 1,
                        ),
                      ),
                      child: Text(
                        _moods[index],
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                  );
                }),
              ),
              const SizedBox(height: 24),
              const Text(
                'Add a note (optional)',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.fieldBorder),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _noteController,
                          maxLength: 200,
                          maxLines: null,
                          expands: true,
                          textAlignVertical: TextAlignVertical.top,
                          style: const TextStyle(color: AppColors.darkText),
                          decoration: const InputDecoration(
                            hintText: 'Say something about this place...',
                            hintStyle: TextStyle(color: AppColors.mutedText),
                            border: InputBorder.none,
                            counterText: '',
                          ),
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          '${_noteController.text.length}/200',
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.mutedText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitCheckIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Check-in',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'You can check-in here once every 15 minutes.',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
