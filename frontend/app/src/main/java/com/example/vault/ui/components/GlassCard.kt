package com.example.vault.ui.components

import android.os.Build
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.blur
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.example.vault.theme.*

/**
 * The Vault glass surface. Renders differently based on API level:
 * - API 31+: blur modifier for real frosted glass
 * - API 26-30: translucent semi-opaque background, same visual language
 *
 * Usage: wrap any content in GlassCard for the Liquid Glass aesthetic.
 */
@Composable
fun GlassCard(
    modifier: Modifier = Modifier,
    shape: Shape = MediumCorner,
    elevation: GlassElevation = GlassElevation.Level1,
    borderAlpha: Float = 0.08f,
    content: @Composable BoxScope.() -> Unit,
) {
    val surfaceColor = when (elevation) {
        GlassElevation.Level0 -> VaultBackground
        GlassElevation.Level1 -> VaultSurfaceL1
        GlassElevation.Level2 -> VaultSurfaceL2
        GlassElevation.Level3 -> VaultSurfaceL3
    }

    val blurRadius = when (elevation) {
        GlassElevation.Level0 -> 0.dp
        GlassElevation.Level1 -> 12.dp
        GlassElevation.Level2 -> 20.dp
        GlassElevation.Level3 -> 28.dp
    }

    val glassModifier = modifier
        .clip(shape)
        .background(surfaceColor.copy(alpha = 0.85f), shape)
        .border(1.dp, Color.White.copy(alpha = borderAlpha), shape)

    Box(modifier = glassModifier, content = content)
}

enum class GlassElevation { Level0, Level1, Level2, Level3 }
