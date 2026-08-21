import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Underlined tab row matching the Figma profile tabs (My Posts / Memories
/// / Badges on your own profile, Posts / Reviews / Titles on someone
/// else's) — equal-width segments, active tab bold + orange with a 2px
/// underline spanning the segment, inactive tabs muted gray with no
/// underline.
class SegmentedTabBar extends StatelessWidget {
  const SegmentedTabBar({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(labels.length, (index) {
        final selected = index == selectedIndex;
        return Expanded(
          child: InkWell(
            onTap: () => onChanged(index),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.orange
                          : AppColors.mutedText(context),
                    ),
                  ),
                ),
                Container(
                  height: 2,
                  color: selected ? AppColors.orange : Colors.transparent,
                ),
              ],
            ),
          ),
        );
      }),
    );
  }
}
