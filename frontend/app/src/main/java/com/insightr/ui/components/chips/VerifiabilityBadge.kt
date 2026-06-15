package com.insightr.ui.components.chips

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.unit.dp
import com.insightr.ui.theme.InsightrColors

@Composable
fun VerifiabilityBadge(
    verifiability: String,
    modifier: Modifier = Modifier
) {
    val (backgroundColor, textColor) = when (verifiability) {
        "fact" -> InsightrColors.VerifiabilityFact.copy(alpha = 0.2f) to InsightrColors.VerifiabilityFact
        "opinion" -> InsightrColors.VerifiabilityOpinion.copy(alpha = 0.2f) to InsightrColors.VerifiabilityOpinion
        else -> InsightrColors.VerifiabilityUnverified.copy(alpha = 0.2f) to InsightrColors.VerifiabilityUnverified
    }

    Box(
        modifier = modifier
            .clip(RoundedCornerShape(4.dp))
            .background(backgroundColor)
            .padding(horizontal = 8.dp, vertical = 4.dp)
    ) {
        Text(
            text = verifiability.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = textColor
        )
    }
}
