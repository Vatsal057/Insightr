package com.example.vault.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.vault.theme.*

/**
 * Concept chip — a glass pill that renders a concept with type-specific color.
 * Used in Explore screen, Entry Detail extras drawer, Concept Galaxy, Knowledge Graph.
 */
@Composable
fun ConceptChip(
    name: String,
    conceptType: String,
    modifier: Modifier = Modifier,
    onClick: (() -> Unit)? = null,
) {
    val color = conceptTypeColor(conceptType)
    val icon  = conceptTypeIcon(conceptType)

    val chipModifier = modifier
        .background(color.copy(alpha = 0.12f), PillCorner)
        .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
        .padding(horizontal = 12.dp, vertical = 6.dp)

    Row(
        modifier = chipModifier,
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Text(
            text = icon,
            fontSize = 12.sp,
        )
        Text(
            text = name,
            color = color,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium,
            maxLines = 1,
        )
    }
}

fun conceptTypeColor(type: String): Color = when (type) {
    "concept"     -> VaultConceptColor
    "framework"   -> VaultFrameworkColor
    "tool"        -> VaultToolColor
    "book"        -> VaultBookColor
    "person"      -> VaultPersonColor
    "methodology" -> VaultMethodColor
    "website"     -> VaultWebsiteColor
    else          -> VaultTextSecondary
}

fun conceptTypeIcon(type: String): String = when (type) {
    "concept"     -> "◈"
    "framework"   -> "⬡"
    "tool"        -> "⚙"
    "book"        -> "📖"
    "person"      -> "◉"
    "methodology" -> "⟡"
    "website"     -> "◎"
    else          -> "•"
}
