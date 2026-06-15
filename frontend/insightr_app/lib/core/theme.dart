import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// All design tokens extracted pixel-for-pixel from insightr_design.html :root {}
class InsightrColors {
  // Backgrounds
  static const bgBase = Color(0xFF0E0E06);
  static const bgDark = Color(0xFF0D0D06);
  static const bgCard = Color(0xFF1E1E10);
  static const bgCard2 = Color(0xFF232314);
  static const bgSurface = Color(0xFF252514);

  // Gold
  static const goldPrimary = Color(0xFFC9A84C);
  static const goldLight = Color(0xFFE0BC60);
  static const goldMuted = Color(0xFF8A6F2E);
  static const goldDim = Color(0xFF4A3A14);
  static const goldGlow = Color(0x2EC9A84C); // 18% opacity
  static const goldGlowStrong = Color(0x59C9A84C); // 35% opacity

  // Text
  static const textPrimary = Color(0xFFF2EDD8);
  static const textSecondary = Color(0xFF9A9070);
  static const textMuted = Color(0xFF5A5035);

  // Semantic
  static const white = Color(0xFFFFFFFF);
  static const red = Color(0xFFE05C4A);
  static const green = Color(0xFF5C9A6A);

  // Glass & Borders
  static const border = Color(0x0FFFFFFF); // 6% white
  static const borderGold = Color(0x33C9A84C); // 20% gold
  static const glassBg = Color(0x0AFFFFFF); // 4% white
  static const glassBg2 = Color(0x12FFFFFF); // 7% white
  static const glassBorder = Color(0x1AFFFFFF); // 10% white
  static const glassGold = Color(0x1EC9A84C); // 12% gold

  // Nav
  static const navBg = Color(0xD11E1C10); // rgba(30,28,16,0.82)

  // Claim badges
  static const claimFactBg = Color(0x265C9A6A);
  static const claimOpinionBg = Color(0x266A9AD4);
  static const claimUnverifiedBg = Color(0x26D47850);

  // Tag colors
  static const tagPurple = Color(0xFF9A6AD4);
  static const tagBlue = Color(0xFF6A9AD4);
}

class InsightrRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xl2 = 28.0;
  static const full = 999.0;

  static BorderRadius smAll = BorderRadius.circular(sm);
  static BorderRadius mdAll = BorderRadius.circular(md);
  static BorderRadius lgAll = BorderRadius.circular(lg);
  static BorderRadius xlAll = BorderRadius.circular(xl);
  static BorderRadius xl2All = BorderRadius.circular(xl2);
  static BorderRadius fullAll = BorderRadius.circular(full);
}

class InsightrTheme {
  static ThemeData get theme {
    final textTheme = GoogleFonts.interTextTheme(
      ThemeData.dark().textTheme,
    );

    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: InsightrColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: InsightrColors.goldPrimary,
        secondary: InsightrColors.goldLight,
        surface: InsightrColors.bgCard,
        error: InsightrColors.red,
        onPrimary: Color(0xFF1A1200),
        onSurface: InsightrColors.textPrimary,
      ),
      textTheme: textTheme.copyWith(
        // display-lg: splash heading — 56px/800/tight
        displayLarge: GoogleFonts.inter(
          fontSize: 56, fontWeight: FontWeight.w800,
          letterSpacing: -1.5, height: 1.05,
          color: InsightrColors.textPrimary,
        ),
        // display-md: action items "Actions" — 52px/900/tightest
        displayMedium: GoogleFonts.inter(
          fontSize: 52, fontWeight: FontWeight.w900,
          letterSpacing: -1.5, height: 1.0,
          color: InsightrColors.textPrimary,
        ),
        // display-sm: vault heading — 48px/800
        displaySmall: GoogleFonts.inter(
          fontSize: 48, fontWeight: FontWeight.w800,
          letterSpacing: -1.0, height: 1.05,
          color: InsightrColors.textPrimary,
        ),
        // headline-lg: feature heading — 42px/800
        headlineLarge: GoogleFonts.inter(
          fontSize: 42, fontWeight: FontWeight.w800,
          letterSpacing: -1.0, height: 1.1,
          color: InsightrColors.textPrimary,
        ),
        // headline-md: home title — 40px/800
        headlineMedium: GoogleFonts.inter(
          fontSize: 40, fontWeight: FontWeight.w800,
          letterSpacing: -1.0, height: 1.1,
          color: InsightrColors.textPrimary,
        ),
        // headline-sm: page header h1 — 36px/900
        headlineSmall: GoogleFonts.inter(
          fontSize: 36, fontWeight: FontWeight.w900,
          letterSpacing: -1.0, height: 1.2,
          color: InsightrColors.textPrimary,
        ),
        // title-lg: insight title — 28px/800
        titleLarge: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w800,
          letterSpacing: 0, height: 1.2,
          color: InsightrColors.textPrimary,
        ),
        // title-md: bottom-sheet title — 26px/800
        titleMedium: GoogleFonts.inter(
          fontSize: 26, fontWeight: FontWeight.w800,
          letterSpacing: 0, height: 1.2,
          color: InsightrColors.textPrimary,
        ),
        // title-sm: section h3 — 18px/700
        titleSmall: GoogleFonts.inter(
          fontSize: 18, fontWeight: FontWeight.w700,
          letterSpacing: 0, height: 1.3,
          color: InsightrColors.textPrimary,
        ),
        // body-lg: primary body text — 16px/600
        bodyLarge: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w600,
          letterSpacing: 0, height: 1.6,
          color: InsightrColors.textPrimary,
        ),
        // body-md: standard body — 15px/400
        bodyMedium: GoogleFonts.inter(
          fontSize: 15, fontWeight: FontWeight.w400,
          letterSpacing: 0, height: 1.5,
          color: InsightrColors.textSecondary,
        ),
        // body-sm: small text — 13px/400
        bodySmall: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w400,
          letterSpacing: 0, height: 1.5,
          color: InsightrColors.textSecondary,
        ),
        // label-lg: button/tag text — 13px/600
        labelLarge: GoogleFonts.inter(
          fontSize: 13, fontWeight: FontWeight.w600,
          letterSpacing: 0, height: 1.0,
          color: InsightrColors.textPrimary,
        ),
        // label-md: small tags — 11px/600
        labelMedium: GoogleFonts.inter(
          fontSize: 11, fontWeight: FontWeight.w600,
          letterSpacing: 0.5, height: 1.0,
          color: InsightrColors.textSecondary,
        ),
        // label-sm: section titles — 10px/700/spaced
        labelSmall: GoogleFonts.inter(
          fontSize: 10, fontWeight: FontWeight.w700,
          letterSpacing: 1.5, height: 1.0,
          color: InsightrColors.goldMuted,
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: InsightrColors.textPrimary,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        },
      ),
    );
  }
}
