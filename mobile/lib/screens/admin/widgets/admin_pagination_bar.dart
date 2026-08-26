import 'package:flutter/material.dart';

import '../../../theme/app_colors.dart';

/// Shared page-number pagination row for MIKKA Business mobile list
/// screens (Products, Orders, ...). Pure UI — the caller decides what
/// happens when a page is tapped; no backend/data-fetch logic here.
class AdminPaginationBar extends StatelessWidget {
  const AdminPaginationBar({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int currentPage;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final visiblePages = totalPages <= 3 ? List.generate(totalPages, (i) => i + 1) : const [1, 2, 3];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PageArrow(
          icon: Icons.chevron_left,
          enabled: currentPage > 1,
          onTap: () => onPageChanged(currentPage - 1),
        ),
        const SizedBox(width: 6),
        for (final page in visiblePages) ...[
          _PageNumber(
            page: page,
            isSelected: page == currentPage,
            onTap: () => onPageChanged(page),
          ),
          const SizedBox(width: 6),
        ],
        if (totalPages > visiblePages.length) ...[
          Text('...', style: TextStyle(color: AppColors.mutedText(context))),
          const SizedBox(width: 6),
        ],
        _PageArrow(
          icon: Icons.chevron_right,
          enabled: currentPage < totalPages,
          onTap: () => onPageChanged(currentPage + 1),
        ),
      ],
    );
  }
}

class _PageNumber extends StatelessWidget {
  const _PageNumber({required this.page, required this.isSelected, required this.onTap});

  final int page;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: isSelected ? AppColors.adminBrandGradient : null,
          border: isSelected ? null : Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Center(
          child: Text(
            '$page',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isSelected ? Colors.white : AppColors.darkText(context),
            ),
          ),
        ),
      ),
    );
  }
}

class _PageArrow extends StatelessWidget {
  const _PageArrow({required this.icon, required this.enabled, required this.onTap});

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: enabled ? onTap : null,
      customBorder: const CircleBorder(),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.darkText(context) : AppColors.mutedText(context),
        ),
      ),
    );
  }
}
