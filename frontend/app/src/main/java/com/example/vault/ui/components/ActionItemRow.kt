package com.example.vault.ui.components

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.vault.theme.*

/**
 * Interactive action item row with animated checkbox.
 * Uses text symbols instead of material-icons to avoid extra dependency.
 */
@Composable
fun ActionItemRow(
    text: String,
    done: Boolean,
    onToggle: () -> Unit,
    modifier: Modifier = Modifier,
) {
    val bgColor by animateColorAsState(
        targetValue = if (done) VaultAccent.copy(alpha = 0.15f) else Color.Transparent,
        animationSpec = spring(stiffness = Spring.StiffnessMedium),
        label = "action_bg",
    )
    val checkBg by animateColorAsState(
        targetValue = if (done) VaultAccent else Color.Transparent,
        animationSpec = spring(stiffness = Spring.StiffnessMedium),
        label = "check_bg",
    )
    val textColor by animateColorAsState(
        targetValue = if (done) VaultTextTertiary else VaultTextPrimary,
        animationSpec = spring(stiffness = Spring.StiffnessMedium),
        label = "text_color",
    )

    Row(
        modifier = modifier
            .fillMaxWidth()
            .clip(SmallCorner)
            .background(bgColor)
            .clickable(onClick = onToggle)
            .padding(horizontal = 12.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Box(
            modifier = Modifier
                .size(22.dp)
                .clip(CircleShape)
                .background(checkBg)
                .border(
                    width = 1.5.dp,
                    color = if (done) VaultAccent else VaultBorderStrong,
                    shape = CircleShape,
                ),
            contentAlignment = Alignment.Center,
        ) {
            if (done) {
                Text(
                    text = "✓",
                    color = VaultBackground,
                    fontSize = 12.sp,
                    fontWeight = FontWeight.Bold,
                )
            }
        }

        Text(
            text = text,
            color = textColor,
            fontSize = 14.sp,
            lineHeight = 20.sp,
            textDecoration = if (done) TextDecoration.LineThrough else TextDecoration.None,
            modifier = Modifier.weight(1f),
        )
    }
}
