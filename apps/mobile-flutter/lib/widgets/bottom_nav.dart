import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../services/mock_data_service.dart';

class SecretBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTabSelected;

  const SecretBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final unreadCount = MockDataService().messages.where((m) => !m.isRead).length;

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0B0E14).withOpacity(0.96),
        border: const Border(
          top: BorderSide(color: AppTheme.outline, width: 1),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                icon: Icons.home_rounded,
                label: 'Home',
              ),
              _buildNavItem(
                index: 1,
                icon: Icons.casino_rounded,
                label: 'Dice',
              ),
              _buildNavItem(
                index: 2,
                icon: Icons.photo_filter_rounded,
                label: 'Stickers',
              ),
              _buildNavItem(
                index: 3,
                icon: Icons.mail_rounded,
                label: 'Inbox',
                badgeCount: unreadCount,
              ),
              _buildNavItem(
                index: 4,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
    int badgeCount = 0,
  }) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: () => onTabSelected(index),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 24,
                  color: isSelected ? AppTheme.primaryWhite : AppTheme.textMuted,
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -2,
                    right: -4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppTheme.wholesomeRose,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                color: isSelected ? AppTheme.primaryWhite : AppTheme.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primaryWhite : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
