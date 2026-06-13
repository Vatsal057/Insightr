package com.example.vault.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.vault.data.api.SummaryCard
import com.example.vault.theme.*

/**
 * Daily Discovery card — surfaces a past entry worth revisiting.
 * Has a warm amber glow to distinguish it from the regular feed.
 * Playfair Display is used ONLY here for the headline — a special moment.
 */
@Composable
fun DailyDiscoveryCard(
    card: SummaryCard,
    daysAgo: Long,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val pulse = rememberInfiniteTransition(label = "glow")
    val glowAlpha by pulse.animateFloat(
        initialValue = 0.15f,
        targetValue  = 0.30f,
        animationSpec = infiniteRepeatable(
            animation  = tween(2000, easing = FastOutSlowInEasing),
            repeatMode = RepeatMode.Reverse,
        ),
        label = "glow_alpha",
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .clip(LargeCorner)
            .background(
                Brush.verticalGradient(
                    listOf(VaultWarmGlow, VaultSurfaceL2)
                )
            )
            .border(
                width = 1.dp,
                brush = Brush.linearGradient(
                    listOf(VaultWarmAmber.copy(alpha = glowAlpha), VaultBorder)
                ),
                shape = LargeCorner,
            )
            .clickable(onClick = onClick)
            .padding(20.dp),
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            // Label row
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalAlignment = Alignment.CenterVertically,
            ) {
                Text(text = "✦", color = VaultWarmAmber, fontSize = 12.sp)
                Text(
                    text = "From $daysAgo days ago",
                    color = VaultWarmAmber,
                    fontSize = 11.sp,
                    fontWeight = FontWeight.Medium,
                    letterSpacing = 0.5f.sp,
                )
                Spacer(Modifier.weight(1f))
                FieldChip(text = card.field)
            }

            // Title in standard Inter
            Text(
                text = card.title,
                color = VaultTextPrimary,
                fontSize = 18.sp,
                fontWeight = FontWeight.Bold,
                lineHeight = 26.sp,
            )

            // Headline — Playfair Display ONLY here as a special editorial moment
            Text(
                text = "\"${card.headline}\"",
                color = VaultTextSecondary,
                fontSize = 14.sp,
                fontStyle = FontStyle.Italic,
                fontFamily = PlayfairFamily,
                lineHeight = 22.sp,
            )

            // CTA
            Text(
                text = "Revisit →",
                color = VaultWarmAmber,
                fontSize = 12.sp,
                fontWeight = FontWeight.SemiBold,
            )
        }
    }
}
