import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (label: 'Map', iconOutline: Icons.map_outlined, iconFilled: Icons.map),
    (label: 'Friends', iconOutline: Icons.people_outline, iconFilled: Icons.people),
    (
      label: 'Shorts',
      iconOutline: Icons.play_circle_outline,
      iconFilled: Icons.play_circle,
    ),
    (
      label: 'Chat',
      iconOutline: Icons.chat_bubble_outline,
      iconFilled: Icons.chat_bubble,
    ),
    (label: 'Profile', iconOutline: Icons.person_outline, iconFilled: Icons.person),
  ];

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          border: Border(top: BorderSide(color: AppColors.fieldBorder(context))),
        ),
        child: Row(
          children: List.generate(_items.length, (index) {
            final item = _items[index];
            final selected = index == currentIndex;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Center(
                  child: selected
                      ? Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.orange,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            item.iconFilled,
                            size: 22,
                            color: Colors.white,
                          ),
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              item.iconOutline,
                              size: 22,
                              color: AppColors.mutedText(context),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.label,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.mutedText(context),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
