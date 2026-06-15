import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme.dart';

/// Pill-shaped filter/toggle button matching .pill-btn from the HTML
class PillButton extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const PillButton({
    super.key,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
        decoration: BoxDecoration(
          borderRadius: InsightrRadii.fullAll,
          color: isActive ? InsightrColors.goldPrimary : InsightrColors.glassBg,
          border: Border.all(
            color: isActive
                ? InsightrColors.goldPrimary
                : const Color(0x14FFFFFF), // rgba(255,255,255,0.08)
            width: 1,
          ),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: InsightrColors.goldPrimary.withAlpha(76),
                    blurRadius: 16,
                  )
                ]
              : [],
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? const Color(0xFF1A1200) : InsightrColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// Full-width primary gold gradient button — matches .btn-primary
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final Widget? icon;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: InsightrRadii.fullAll,
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [InsightrColors.goldLight, InsightrColors.goldPrimary],
          ),
          boxShadow: [
            BoxShadow(
              color: InsightrColors.goldPrimary.withAlpha(89),
              blurRadius: 32,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: InsightrColors.goldPrimary.withAlpha(51),
              blurRadius: 0,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1200),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Full-width secondary glass button — matches .btn-secondary
class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: InsightrRadii.fullAll,
          color: InsightrColors.glassBg,
          border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: InsightrColors.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Circular glass icon button — matches .icon-btn and .back-btn
class CircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;

  const CircleIconButton({
    super.key,
    required this.icon,
    this.onTap,
    this.size = 40,
    this.iconSize = 18,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0x12FFFFFF), // rgba(255,255,255,0.07)
          border: Border.all(color: const Color(0x1AFFFFFF), width: 1),
        ),
        child: Icon(icon, size: iconSize, color: InsightrColors.textSecondary),
      ),
    );
  }
}
