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
    (label: 'Shorts', iconOutline: Icons.play_circle_outline, iconFilled: Icons.play_circle),
    (
      label: 'Chat',
      iconOutline: Icons.chat_bubble_outline,
      iconFilled: Icons.chat_bubble,
    ),
    (label: 'Profile', iconOutline: Icons.person_outline, iconFilled: Icons.person),
  ];

  static const _createTabIndex = 2;

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
            final isCreateTab = index == _createTabIndex;
            // Tapping the Shorts tab a second time (while already selected)
            // opens the capture screen (see MainShellScreen._onTabTap), so
            // only THEN does this slot read "Create" with the elevated "+"
            // button — otherwise it's a normal "Shorts" tab like the rest.
            final label = isCreateTab && selected ? 'Create' : item.label;
            return Expanded(
              child: GestureDetector(
                onTap: () => onTap(index),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isCreateTab && selected)
                        Transform.translate(
                          offset: const Offset(0, -10),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.orange,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.surface(context), width: 3),
                            ),
                            child: const Icon(Icons.add, size: 24, color: Colors.white),
                          ),
                        )
                      else if (selected)
                        Container(
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            color: AppColors.orange,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            item.iconFilled,
                            size: 20,
                            color: Colors.white,
                          ),
                        )
                      else
                        Icon(
                          item.iconOutline,
                          size: 22,
                          color: AppColors.mutedText(context),
                        ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? AppColors.orange
                              : AppColors.mutedText(context),
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
