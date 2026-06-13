package com.example.vault.theme

import androidx.compose.material3.Typography
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

// ─── Inter Font Family ────────────────────────────────────────────────────────
// Using system default Sans-serif as Inter fallback (downloadable fonts
// require network; for production, bundle Inter TTF files in res/font/)
val InterFamily = FontFamily.SansSerif

// ─── Playfair Display — SPECIAL MOMENTS ONLY ─────────────────────────────────
// Only used for: entry headline hero, onboarding.
// NOT used across the app — Inter is the dominant typeface.
val PlayfairFamily = FontFamily.Serif

// ─── Typography Scale ─────────────────────────────────────────────────────────
val VaultTypography = Typography(

  // Display — Playfair: entry headline hero / onboarding
  displayLarge = TextStyle(
    fontFamily = PlayfairFamily,
    fontWeight = FontWeight.Bold,
    fontStyle  = FontStyle.Italic,
    fontSize   = 36.sp,
    lineHeight = 44.sp,
    color      = VaultTextPrimary,
  ),

  // Headline — Inter: screen titles, card titles
  headlineLarge = TextStyle(
    fontFamily = InterFamily,
    fontWeight = FontWeight.Bold,
    fontSize   = 24.sp,
    lineHeight = 32.sp,
    color      = VaultTextPrimary,
  ),

  headlineMedium = TextStyle(
    fontFamily = InterFamily,
    fontWeight = FontWeight.Bold,
    fontSize   = 20.sp,
    lineHeight = 28.sp,
    color      = VaultTextPrimary,
  ),

  headlineSmall = TextStyle(
    fontFamily = InterFamily,
    fontWeight = FontWeight.SemiBold,
    fontSize   = 18.sp,
    lineHeight = 26.sp,
    color      = VaultTextPrimary,
  ),

  // Title — Inter: card titles, section headers
  titleLarge = TextStyle(
    fontFamily = InterFamily,
    fontWeight = FontWeight.SemiBold,
    fontSize   = 18.sp,
    lineHeight = 24.sp,
    color      = VaultTextPrimary,
  ),

  titleMedium = TextStyle(
    fontFamily = InterFamily,
    fontWeight = FontWeight.Medium,
    fontSize   = 15.sp,
    lineHeight = 22.sp,
    color      = VaultTextPrimary,
  ),

  titleSmall = TextStyle(
    fontFamily = InterFamily,
    fontWeight = FontWeight.Medium,
    fontSize   = 13.sp,
    lineHeight = 20.sp,
    color      = VaultTextSecondary,
  ),

  // Body — Inter: content paragraphs
  bodyLarge = TextStyle(
    fontFamily  = InterFamily,
    fontWeight  = FontWeight.Normal,
    fontSize    = 16.sp,
    lineHeight  = 26.sp,
    color       = VaultTextPrimary,
  ),

  bodyMedium = TextStyle(
    fontFamily  = InterFamily,
    fontWeight  = FontWeight.Normal,
    fontSize    = 14.sp,
    lineHeight  = 22.sp,
    color       = VaultTextSecondary,
  ),

  bodySmall = TextStyle(
    fontFamily  = InterFamily,
    fontWeight  = FontWeight.Normal,
    fontSize    = 12.sp,
    lineHeight  = 18.sp,
    color       = VaultTextTertiary,
  ),

  // Label — Inter: chips, badges, tabs
  labelLarge = TextStyle(
    fontFamily    = InterFamily,
    fontWeight    = FontWeight.Medium,
    fontSize      = 13.sp,
    lineHeight    = 18.sp,
    letterSpacing = 0.3.sp,
    color         = VaultTextSecondary,
  ),

  labelMedium = TextStyle(
    fontFamily    = InterFamily,
    fontWeight    = FontWeight.Medium,
    fontSize      = 11.sp,
    lineHeight    = 16.sp,
    letterSpacing = 0.4.sp,
    color         = VaultTextTertiary,
  ),

  labelSmall = TextStyle(
    fontFamily    = InterFamily,
    fontWeight    = FontWeight.Medium,
    fontSize      = 10.sp,
    lineHeight    = 14.sp,
    letterSpacing = 0.5.sp,
    color         = VaultTextTertiary,
  ),
)
