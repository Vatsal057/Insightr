package com.example.vault.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color

// ─── Vault Dark Color Scheme ──────────────────────────────────────────────────
// Force dark everywhere — no dynamic color, no light theme.
// Liquid Glass only makes sense on a deep dark background.
private val VaultDarkColorScheme = darkColorScheme(
  primary         = VaultAccent,
  onPrimary       = VaultBackground,
  primaryContainer      = VaultAccentMuted,
  onPrimaryContainer    = VaultAccent,
  secondary       = VaultTextSecondary,
  onSecondary     = VaultBackground,
  tertiary        = VaultFact,
  onTertiary      = VaultBackground,
  background      = VaultBackground,
  onBackground    = VaultTextPrimary,
  surface         = VaultSurfaceL1,
  onSurface       = VaultTextPrimary,
  surfaceVariant  = VaultSurfaceL2,
  onSurfaceVariant = VaultTextSecondary,
  outline         = VaultBorderStrong,
  outlineVariant  = VaultBorder,
  error           = VaultError,
  onError         = Color.White,
  scrim           = Color(0xCC08080C),
)

@Composable
fun VaultTheme(content: @Composable () -> Unit) {
  MaterialTheme(
    colorScheme = VaultDarkColorScheme,
    typography  = VaultTypography,
    shapes      = VaultShapes,
    content     = content,
  )
}
