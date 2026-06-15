package com.insightr.ui.components.cards

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
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
import com.insightr.data.api.ConceptDto
import com.insightr.ui.theme.InsightrColors

@Composable
fun ConceptCard(
    concept: ConceptDto,
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
            Row(
                verticalAlignment = Alignment.CenterVertically
            ) {
                // Concept type badge
                Box(
                    modifier = Modifier
                        .background(
                            getConceptTypeColor(concept.conceptType).copy(alpha = 0.2f),
                            RoundedCornerShape(4.dp)
                        )
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = concept.conceptType.replaceFirstChar { it.uppercase() },
                        style = MaterialTheme.typography.labelSmall,
                        color = getConceptTypeColor(concept.conceptType)
                    )
                }
            }

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = concept.name,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )

            Spacer(modifier = Modifier.height(4.dp))

            Text(
                text = concept.summary,
                style = MaterialTheme.typography.bodySmall,
                color = InsightrColors.TextSecondary,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
    }
}

private fun getConceptTypeColor(type: String): androidx.compose.ui.graphics.Color {
    return when (type) {
        "framework" -> InsightrColors.ConceptFramework
        "book" -> InsightrColors.ConceptBook
        "person" -> InsightrColors.ConceptPerson
        "tool" -> InsightrColors.ConceptTool
        "methodology" -> InsightrColors.ConceptMethodology
        else -> InsightrColors.ConceptTheory
    }
}
