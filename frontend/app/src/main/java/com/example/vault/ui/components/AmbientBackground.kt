package com.example.vault.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import com.example.vault.theme.VaultBackground

import androidx.compose.foundation.layout.BoxScope

@Composable
fun AmbientBackground(modifier: Modifier = Modifier, content: @Composable BoxScope.() -> Unit) {
    val infiniteTransition = rememberInfiniteTransition(label = "ambient_glow")
    
    val xOffset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(25000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "xOffset"
    )
    
    val yOffset by infiniteTransition.animateFloat(
        initialValue = 0f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(20000, easing = LinearEasing),
            repeatMode = RepeatMode.Reverse
        ),
        label = "yOffset"
    )

    Box(modifier = modifier.fillMaxSize().background(VaultBackground)) {
        Canvas(modifier = Modifier.fillMaxSize()) {
            val canvasWidth = size.width
            val canvasHeight = size.height

            // Glow 1: Violet/Accent
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(Color(0x33A78BFA), Color.Transparent),
                    center = Offset(canvasWidth * (0.2f + 0.6f * xOffset), canvasHeight * (0.1f + 0.3f * yOffset)),
                    radius = canvasWidth * 0.8f
                ),
                radius = canvasWidth * 0.8f,
                center = Offset(canvasWidth * (0.2f + 0.6f * xOffset), canvasHeight * (0.1f + 0.3f * yOffset))
            )

            // Glow 2: Blue/Cyan
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(Color(0x2260A5FA), Color.Transparent),
                    center = Offset(canvasWidth * (0.8f - 0.4f * xOffset), canvasHeight * (0.7f - 0.2f * yOffset)),
                    radius = canvasWidth * 0.9f
                ),
                radius = canvasWidth * 0.9f,
                center = Offset(canvasWidth * (0.8f - 0.4f * xOffset), canvasHeight * (0.7f - 0.2f * yOffset))
            )
            
            // Glow 3: Emerald
            drawCircle(
                brush = Brush.radialGradient(
                    colors = listOf(Color(0x1A34D399), Color.Transparent),
                    center = Offset(canvasWidth * 0.5f, canvasHeight * (0.9f - 0.4f * xOffset)),
                    radius = canvasWidth * 0.7f
                ),
                radius = canvasWidth * 0.7f,
                center = Offset(canvasWidth * 0.5f, canvasHeight * (0.9f - 0.4f * xOffset))
            )
        }
        content()
    }
}
