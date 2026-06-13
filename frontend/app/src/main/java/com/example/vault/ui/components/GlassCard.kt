package com.example.vault.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.dp
import com.example.vault.theme.*

/**
 * The Vault liquid glass surface.
 * Combines translucent backgrounds, light-catching gradient borders,
 * and subtle neomorphic shadows.
 */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    shape: Shape = MediumCorner,
    elevation: GlassElevation = GlassElevation.Level1,
    borderAlpha: Float = 0.15f,
    content: @Composable BoxScope.() -> Unit,
) {
    val surfaceColor = when (elevation) {
        GlassElevation.Level0 -> VaultBackground
        GlassElevation.Level1 -> VaultSurfaceL1
        GlassElevation.Level2 -> VaultSurfaceL2
        GlassElevation.Level3 -> VaultSurfaceL3
    }

    val shadowElevation = when (elevation) {
        GlassElevation.Level0 -> 0.dp
        GlassElevation.Level1 -> 8.dp
        GlassElevation.Level2 -> 16.dp
        GlassElevation.Level3 -> 24.dp
    }

    val lightCatchGradient = Brush.linearGradient(
        colors = listOf(
            Color.White.copy(alpha = borderAlpha + 0.1f),
            Color.White.copy(alpha = borderAlpha * 0.2f),
            Color.White.copy(alpha = borderAlpha * 0.05f),
            Color.White.copy(alpha = borderAlpha * 0.4f)
        )
    )

    val glassModifier = modifier
        .shadow(shadowElevation, shape, spotColor = Color(0x99000000), ambientColor = Color(0x99000000))
        .clip(shape)
        .background(surfaceColor.copy(alpha = 0.65f), shape)
        .border(1.5.dp, lightCatchGradient, shape)

    Box(modifier = glassModifier, content = content)
}

enum class GlassElevation { Level0, Level1, Level2, Level3 }
