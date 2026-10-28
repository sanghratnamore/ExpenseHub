import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class EhBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onProfilePressed;

  const EhBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onProfilePressed,
  });

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(0, Icons.home_outlined, Icons.home_rounded, 'Home'),
      _NavItem(
        1,
        Icons.insights_outlined,
        Icons.insights_rounded,
        'Stats',
      ),
      _NavItem(
        2,
        Icons.group_outlined,
        Icons.group_rounded,
        'Groups',
      ),
      _NavItem(
        3,
        Icons.receipt_long_outlined,
        Icons.receipt_long_rounded,
        'History',
      ),
    ];

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.symmetric(
          horizontal: 8,
          vertical: 8,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Row(
          children: [
            ...items.map(
              (item) => Expanded(
                child: _navItem(item),
              ),
            ),
            Expanded(
              child: _profileItem(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _navItem(_NavItem item) {
    final isSelected = currentIndex == item.index;

    return GestureDetector(
      onTap: () => onTap(item.index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? item.activeIcon : item.icon,
              size: 22,
              color: isSelected
                  ? AppColors.primary
                  : AppColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: isSelected
                    ? FontWeight.w800
                    : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _profileItem() {
    return GestureDetector(
      onTap: onProfilePressed,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_rounded,
                size: 18,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Profile',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final int index;
  final IconData icon;
  final IconData activeIcon;
  final String label;

  const _NavItem(
    this.index,
    this.icon,
    this.activeIcon,
    this.label,
  );
}