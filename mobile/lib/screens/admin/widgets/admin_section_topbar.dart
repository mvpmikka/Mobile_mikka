import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Shared top bar for MIKKA Business mobile section screens (Place,
/// Products, Inventory, ...): back button, title, optional search field,
/// notification bell and profile avatar. Pure UI — no backend calls.
class AdminSectionTopBar extends StatelessWidget {
  const AdminSectionTopBar({
    super.key,
    required this.title,
    this.onNotification,
    this.searchController,
    this.searchHint,
    this.onSearchChanged,
  });

  final String title;
  final VoidCallback? onNotification;
  final TextEditingController? searchController;
  final String? searchHint;
  final ValueChanged<String>? onSearchChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            InkWell(
              onTap: () => Navigator.of(context).maybePop(),
              customBorder: const CircleBorder(),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.fieldBorder(context)),
                ),
                child: Icon(Icons.arrow_back, size: 18, color: AppColors.darkText(context)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText(context),
                ),
              ),
            ),
            Stack(
              clipBehavior: Clip.none,
              children: [
                IconButton(
                  onPressed: onNotification,
                  icon: Icon(Icons.notifications_outlined, color: AppColors.darkText(context)),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFCB4B4B),
                    ),
                  ),
                ),
              ],
            ),
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.adminGradientMid,
              child: const Icon(Icons.person, color: Colors.white, size: 18),
            ),
          ],
        ),
        if (searchController != null) ...[
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: TextStyle(color: AppColors.darkText(context)),
            decoration: InputDecoration(
              hintText: searchHint ?? 'Qidiruv...',
              prefixIcon: const Icon(Icons.search, size: 20),
              filled: true,
              fillColor: AppColors.surface(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.fieldBorder(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: AppColors.fieldBorder(context)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: AppColors.adminGradientMid, width: 1.5),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
