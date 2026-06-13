package com.example.vault.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.vault.data.api.SummaryCard
import com.example.vault.theme.*

/**
 * Feed InsightCard — the primary list item on the Discover screen.
 *
 * Liquid Glass floating card with:
 *   - Field chip + content-type badge
 *   - Title in Inter 18sp Bold
 *   - Headline in Inter 13sp muted italic
 *   - Tag row
 *   - Subtle violet left accent border
 */
@Composable
fun InsightCard(
    card: SummaryCard,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
) {
    GlassCard(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = LargeCorner,
        elevation = GlassElevation.Level2,
    ) {
        // Violet left accent line
        Row(modifier = Modifier.fillMaxWidth()) {
            Box(
                modifier = Modifier
                    .width(3.dp)
                    .fillMaxHeight()
                    .background(
                        Brush.verticalGradient(
                            listOf(VaultAccent, VaultAccentMuted)
                        )
                    )
            )

            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(start = 16.dp, end = 20.dp, top = 18.dp, bottom = 18.dp),
                verticalArrangement = Arrangement.spacedBy(10.dp),
            ) {
                // Badges row
                Row(
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    FieldChip(text = card.field)
                    ContentTypeChip(type = card.contentType)
                }

                // Title
                Text(
                    text = card.title,
                    color = VaultTextPrimary,
                    fontSize = 17.sp,
                    fontWeight = FontWeight.SemiBold,
                    lineHeight = 24.sp,
                )

                // Headline — secondary, muted
                Text(
                    text = card.headline,
                    color = VaultTextSecondary,
                    fontSize = 13.sp,
                    fontStyle = FontStyle.Normal,
                    lineHeight = 19.sp,
                    maxLines = 2,
                )

                // Tags
                if (card.tags.isNotEmpty()) {
                    Row(
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                        modifier = Modifier.fillMaxWidth(),
                    ) {
                        card.tags.take(3).forEach { tag ->
                            TagPill(tag = tag)
                        }
                    }
                }

                // Date
                Text(
                    text = formatDate(card.createdAt),
                    color = VaultTextTertiary,
                    fontSize = 11.sp,
                )
            }
        }
    }
}

@Composable
fun FieldChip(text: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .background(VaultAccentMuted, PillCorner)
            .padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(
            text = text,
            color = VaultAccent,
            fontSize = 11.sp,
            fontWeight = FontWeight.Medium,
        )
    }
}

@Composable
fun ContentTypeChip(type: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .background(VaultSurfaceL3, PillCorner)
            .padding(horizontal = 10.dp, vertical = 4.dp),
    ) {
        Text(
            text = type.replace("_", " ").replaceFirstChar { it.uppercase() },
            color = VaultTextTertiary,
            fontSize = 11.sp,
            fontWeight = FontWeight.Normal,
        )
    }
}

@Composable
fun TagPill(tag: String, modifier: Modifier = Modifier) {
    Box(
        modifier = modifier
            .background(VaultSurfaceL2, PillCorner)
            .padding(horizontal = 8.dp, vertical = 3.dp),
    ) {
        Text(
            text = "#$tag",
            color = VaultTextTertiary,
            fontSize = 10.sp,
        )
    }
}

fun formatDate(iso: String): String {
    return try {
        val date = java.time.LocalDateTime.parse(iso.take(19))
        val now  = java.time.LocalDateTime.now()
        val days = java.time.temporal.ChronoUnit.DAYS.between(date.toLocalDate(), now.toLocalDate())
        when {
            days == 0L -> "Today"
            days == 1L -> "Yesterday"
            days < 7   -> "$days days ago"
            days < 30  -> "${days / 7}w ago"
            else       -> date.toLocalDate().toString()
        }
    } catch (e: Exception) {
        iso.take(10)
    }
}
