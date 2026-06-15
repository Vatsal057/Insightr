package com.insightr.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.runtime.Composable

private val InsightrDarkColorScheme = darkColorScheme(
    primary = InsightrColors.Accent,
    onPrimary = InsightrColors.Background,
    primaryContainer = InsightrColors.Accent,
    onPrimaryContainer = InsightrColors.Background,
    secondary = InsightrColors.AccentLight,
    onSecondary = InsightrColors.Background,
    secondaryContainer = InsightrColors.Card,
    onSecondaryContainer = InsightrColors.TextPrimary,
    tertiary = InsightrColors.Accent,
    onTertiary = InsightrColors.Background,
    background = InsightrColors.Background,
    onBackground = InsightrColors.TextPrimary,
    surface = InsightrColors.Background,
    onSurface = InsightrColors.TextPrimary,
    surfaceVariant = InsightrColors.BackgroundSecondary,
    onSurfaceVariant = InsightrColors.TextSecondary,
    outline = InsightrColors.Border,
    error = InsightrColors.Danger,
    onError = InsightrColors.TextPrimary
)

@Composable
fun InsightrTheme(content: @Composable () -> Unit) {
    MaterialTheme(
        colorScheme = InsightrDarkColorScheme,
        typography = InsightrTypography,
        shapes = InsightrShapes,
        content = content
    )
}
