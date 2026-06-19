import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// The floating liquid-glass pill bottom navigation bar.
/// Matches .bottom-nav-glass from the HTML exactly.
class InsightrBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int pendingCount;

  const InsightrBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.pendingCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12, top: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  InsightrColors.navBg.withAlpha(180),
                  InsightrColors.navBg.withAlpha(100),
                ],
              ),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: const Color(0x2BFFFFFF), // slightly brighter highlight for edge refraction
                width: 0.8,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x80000000),
                  blurRadius: 32,
                  offset: Offset(0, 8),
                ),
                BoxShadow(
                  color: Color(0x0FC9A84C), // rgba(201,168,76,0.06)
                  blurRadius: 0,
                  spreadRadius: 1,
                ),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              children: [
                _NavItem(icon: Icons.home_rounded, label: 'Home', index: 0, currentIndex: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.inventory_2_rounded, label: 'Vault', index: 1, currentIndex: currentIndex, onTap: onTap),
                _NavItemWithBadge(icon: Icons.check_circle_outline_rounded, label: 'Actions', index: 2, currentIndex: currentIndex, onTap: onTap, badgeCount: pendingCount),
                _NavItem(icon: Icons.search_rounded, label: 'Search', index: 3, currentIndex: currentIndex, onTap: onTap),
                _NavItem(icon: Icons.person_outline_rounded, label: 'Profile', index: 4, currentIndex: currentIndex, onTap: onTap),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
  });

  bool get isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gold indicator line above active item
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 28 : 0,
              decoration: BoxDecoration(
                color: InsightrColors.goldPrimary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: InsightrColors.goldPrimary.withAlpha(180),
                          blurRadius: 8,
                        )
                      ]
                    : [],
              ),
            ),
            const SizedBox(height: 6),
            Icon(
              icon,
              size: 22,
              color: isActive
                  ? InsightrColors.goldPrimary
                  : InsightrColors.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w500,
                color: isActive
                    ? InsightrColors.goldPrimary
                    : InsightrColors.textSecondary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _NavItemWithBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final int badgeCount;

  const _NavItemWithBadge({
    required this.icon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    required this.badgeCount,
  });

  bool get isActive => index == currentIndex;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: () => onTap(index),
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 2,
              width: isActive ? 28 : 0,
              decoration: BoxDecoration(
                color: InsightrColors.goldPrimary,
                borderRadius: BorderRadius.circular(2),
                boxShadow: isActive
                    ? [BoxShadow(color: InsightrColors.goldPrimary.withAlpha(180), blurRadius: 8)]
                    : [],
              ),
            ),
            const SizedBox(height: 6),
            Stack(clipBehavior: Clip.none, children: [
              Icon(icon, size: 22,
                color: isActive ? InsightrColors.goldPrimary : InsightrColors.textSecondary),
              if (badgeCount > 0)
                Positioned(
                  top: -4, right: -6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: InsightrColors.goldPrimary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                    child: Text(
                      badgeCount > 99 ? '99+' : '$badgeCount',
                      style: GoogleFonts.inter(
                        fontSize: 8, fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A1200),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 4),
            Text(label, style: GoogleFonts.inter(
              fontSize: 10, fontWeight: FontWeight.w500,
              color: isActive ? InsightrColors.goldPrimary : InsightrColors.textSecondary,
              letterSpacing: 0.3,
            )),
          ],
        ),
      ),
    );
  }
}

/// The gold gradient floating action button shown on the Home screen
class InsightrFab extends StatelessWidget {
  final VoidCallback onPressed;

  const InsightrFab({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [InsightrColors.goldLight, InsightrColors.goldPrimary],
          ),
          boxShadow: [
            BoxShadow(
              color: InsightrColors.goldPrimary.withAlpha(115),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: InsightrColors.goldPrimary.withAlpha(76),
              blurRadius: 0,
              spreadRadius: 1,
            ),
          ],
        ),
        child: const Icon(Icons.add_rounded, color: Color(0xFF1A1200), size: 24),
      ),
    );
  }
}
