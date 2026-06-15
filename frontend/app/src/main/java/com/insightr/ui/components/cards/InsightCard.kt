package com.insightr.ui.components.cards

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.insightr.data.api.FeedItem
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.components.chips.EffortPill
import com.insightr.ui.theme.InsightrColors

@Composable
fun InsightCard(
    feedItem: FeedItem,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = InsightrColors.Card
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            // Field category pill
            CategoryPill(label = feedItem.field)

            Spacer(modifier = Modifier.height(12.dp))

            // Title
            Text(
                text = feedItem.title,
                style = MaterialTheme.typography.headlineSmall,
                color = InsightrColors.TextPrimary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(8.dp))

            // Hook / subtitle
            Text(
                text = feedItem.hook,
                style = MaterialTheme.typography.bodyMedium,
                color = InsightrColors.TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(12.dp))

            // Count chips row
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                if (feedItem.actionItemCount > 0) {
                    CountChip(label = "${feedItem.actionItemCount} actions")
                }
                if (feedItem.implementationStepCount > 0) {
                    CountChip(label = "${feedItem.implementationStepCount} steps")
                }
                if (feedItem.toolCount > 0) {
                    CountChip(label = "${feedItem.toolCount} tools")
                }
            }

            // Effort pill
            feedItem.effortPill?.let { pill ->
                Spacer(modifier = Modifier.height(8.dp))
                EffortPill(label = pill.label)
            }

            // Top action
            feedItem.topAction?.let { action ->
                Spacer(modifier = Modifier.height(12.dp))
                TopActionCard(actionText = action.text)
            }
        }
    }
}

@Composable
private fun CountChip(label: String) {
    Box(
        modifier = Modifier
            .background(InsightrColors.BackgroundSecondary, RoundedCornerShape(20.dp))
            .padding(horizontal = 10.dp, vertical = 4.dp)
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = InsightrColors.TextSecondary
        )
    }
}

@Composable
fun TopActionCard(
    actionText: String,
    modifier: Modifier = Modifier
) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(8.dp),
        colors = CardDefaults.cardColors(
            containerColor = InsightrColors.Accent.copy(alpha = 0.15f)
        )
    ) {
        Column(
            modifier = Modifier.padding(12.dp)
        ) {
            Text(
                text = "Top Action",
                style = MaterialTheme.typography.labelMedium,
                color = InsightrColors.Accent
            )
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = actionText,
                style = MaterialTheme.typography.bodyMedium,
                color = InsightrColors.TextPrimary
            )
        }
    }
}
