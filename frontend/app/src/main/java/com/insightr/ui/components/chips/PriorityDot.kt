package com.insightr.ui.components.chips

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.insightr.ui.theme.InsightrColors

@Composable
fun PriorityDot(
    priority: String,
    modifier: Modifier = Modifier
) {
    val color = when (priority) {
        "now" -> InsightrColors.PriorityNow
        "soon" -> InsightrColors.PrioritySoon
        else -> InsightrColors.PrioritySomeday
    }

    Box(
        modifier = modifier
            .size(8.dp)
            .clip(CircleShape)
            .background(color)
    )
}
