package com.example.vault.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.example.vault.theme.*

/**
 * Shimmer loading skeleton — used while data is being fetched.
 * Matches the GlassCard aesthetic (dark background, subtle shimmer sweep).
 */
@Composable
fun ShimmerBox(
    modifier: Modifier = Modifier,
) {
    val shimmerColors = listOf(
        VaultSurfaceL1,
        VaultSurfaceL2,
        VaultSurfaceL1,
    )

    val transition = rememberInfiniteTransition(label = "shimmer")
    val translateAnim by transition.animateFloat(
        initialValue = 0f,
        targetValue = 1000f,
        animationSpec = infiniteRepeatable(
            animation = tween(durationMillis = 1200, easing = LinearEasing),
            repeatMode = RepeatMode.Restart,
        ),
        label = "shimmer_translate",
    )

    val brush = Brush.linearGradient(
        colors = shimmerColors,
        start = Offset(translateAnim - 200f, 0f),
        end   = Offset(translateAnim, 0f),
    )

    Box(modifier = modifier.background(brush, MediumCorner))
}

/**
 * Full InsightCard shimmer skeleton for the feed list.
 */
@Composable
fun InsightCardSkeleton(modifier: Modifier = Modifier) {
    Column(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 8.dp),
        verticalArrangement = Arrangement.spacedBy(10.dp),
    ) {
        // Field chip + type badge row
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            ShimmerBox(modifier = Modifier.width(80.dp).height(24.dp))
            ShimmerBox(modifier = Modifier.width(60.dp).height(24.dp))
        }
        // Title
        ShimmerBox(modifier = Modifier.fillMaxWidth(0.85f).height(20.dp))
        ShimmerBox(modifier = Modifier.fillMaxWidth(0.60f).height(20.dp))
        // Headline
        ShimmerBox(modifier = Modifier.fillMaxWidth().height(14.dp))
        ShimmerBox(modifier = Modifier.fillMaxWidth(0.9f).height(14.dp))
        // Tags
        Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
            ShimmerBox(modifier = Modifier.width(50.dp).height(20.dp))
            ShimmerBox(modifier = Modifier.width(64.dp).height(20.dp))
            ShimmerBox(modifier = Modifier.width(44.dp).height(20.dp))
        }
    }
}
