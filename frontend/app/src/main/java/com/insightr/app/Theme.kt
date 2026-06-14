package com.insightr.app

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

/* =========================================================================
 * COLOR PALETTE — warm olive/charcoal background, cream cards, amber accent
 * ====================================================================== */

object InsightrColors {
    val BackgroundDark = Color(0xFF2A2722)
    val BackgroundDarkAlt = Color(0xFF3A352D)
    val Cream = Color(0xFFF6F1E7)
    val CreamMuted = Color(0xFFEDE6D8)
    val Accent = Color(0xFFE6A95C)
    val AccentSoft = Color(0xFFF1C998)
    val TextOnDark = Color(0xFFF6F1E7)
    val TextOnDarkMuted = Color(0xFFC9C3B7)
    val TextOnCream = Color(0xFF2A2722)
    val TextOnCreamMuted = Color(0xFF8A8377)
    val PillDark = Color(0xFF4A453B)
    val Success = Color(0xFF8FAE7E)
    val Danger = Color(0xFFD98C7A)

    val BackgroundGradient = Brush.verticalGradient(
        colors = listOf(BackgroundDarkAlt, BackgroundDark)
    )
}

/* =========================================================================
 * NAVIGATION ROUTES
 * ====================================================================== */

object Routes {
    const val ONBOARDING = "onboarding"
    const val HOME = "home"
    const val ADD = "add"
    const val TODO = "todo"
    const val COLLECTIONS = "collections"
    const val CARDS = "cards"
    const val SETTINGS = "settings"
    const val ENTRY_DETAIL = "entry/{entryId}"
    const val COLLECTION_DETAIL = "collection/{name}"
    const val CARD_DETAIL = "card/{cardId}"

    fun entryDetail(id: Int) = "entry/$id"
    fun collectionDetail(name: String) = "collection/$name"
    fun cardDetail(id: Int) = "card/$id"
}

/* =========================================================================
 * SHARED COMPONENTS
 * ====================================================================== */

@Composable
fun PillButton(
    text: String,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    trailingIcon: Boolean = true,
    enabled: Boolean = true
) {
    Row(
        modifier = modifier
            .clip(RoundedCornerShape(32.dp))
            .background(if (enabled) InsightrColors.PillDark else InsightrColors.PillDark.copy(alpha = 0.5f))
            .clickable(enabled = enabled, onClick = onClick)
            .padding(horizontal = 8.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = text,
            color = InsightrColors.TextOnDark,
            fontSize = 16.sp,
            fontWeight = FontWeight.Medium,
            modifier = Modifier.padding(start = 16.dp, end = 12.dp)
        )
        if (trailingIcon) {
            Box(
                modifier = Modifier
                    .size(40.dp)
                    .clip(CircleShape)
                    .background(InsightrColors.Cream),
                contentAlignment = Alignment.Center
            ) {
                Icon(Icons.Default.ArrowForward, contentDescription = null, tint = InsightrColors.TextOnCream)
            }
        }
    }
}

@Composable
fun FilterChip(label: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(20.dp))
            .background(
                if (selected) InsightrColors.Cream
                else Color.White.copy(alpha = 0.06f)
            )
            .clickable(onClick = onClick)
            .padding(horizontal = 18.dp, vertical = 10.dp)
    ) {
        Text(
            text = label,
            color = if (selected) InsightrColors.TextOnCream else InsightrColors.TextOnDark,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal,
            fontSize = 14.sp
        )
    }
}

@Composable
fun SectionHeader(title: String, subtitle: String? = null) {
    Column {
        Text(
            text = title,
            color = InsightrColors.TextOnDark,
            fontSize = 26.sp,
            fontWeight = FontWeight.Bold,
            lineHeight = 30.sp
        )
        if (subtitle != null) {
            Spacer(modifier = Modifier.height(4.dp))
            Text(
                text = subtitle,
                color = InsightrColors.TextOnDarkMuted,
                fontSize = 14.sp
            )
        }
    }
}

@Composable
fun CircleIconButton(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    onClick: () -> Unit = {},
    filled: Boolean = true
) {
    Box(
        modifier = Modifier
            .size(40.dp)
            .clip(CircleShape)
            .background(if (filled) InsightrColors.Cream else InsightrColors.PillDark)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = if (filled) InsightrColors.TextOnCream else InsightrColors.TextOnDark
        )
    }
}

/** Small amber dot used for streaks / unread badges. */
@Composable
fun Dot(color: Color = InsightrColors.Accent, size: Int = 8) {
    Box(
        modifier = Modifier
            .size(size.dp)
            .clip(CircleShape)
            .background(color)
    )
}

/** Icon associated with each content type, for entry cards & cards screen. */
fun contentTypeIcon(contentType: String): androidx.compose.ui.graphics.vector.ImageVector = when (contentType) {
    "coding_tutorial" -> Icons.Default.Code
    "workout_routine", "fitness_nutrition" -> Icons.Default.FitnessCenter
    "movie_tv_recommendation" -> Icons.Default.Movie
    "music_recommendation" -> Icons.Default.MusicNote
    "book_recommendation" -> Icons.Default.MenuBook
    "recipe" -> Icons.Default.Restaurant
    "tool_app_recommendation", "tool_review" -> Icons.Default.Build
    "travel_guide" -> Icons.Default.Flight
    "finance_tip" -> Icons.Default.AttachMoney
    "career_advice" -> Icons.Default.Work
    "life_hack" -> Icons.Default.Lightbulb
    "fashion_outfit" -> Icons.Default.Checkroom
    "home_diy" -> Icons.Default.Handyman
    "language_learning" -> Icons.Default.Translate
    "comparison" -> Icons.Default.CompareArrows
    "listicle" -> Icons.Default.List
    "opinion" -> Icons.Default.Forum
    "story" -> Icons.Default.AutoStories
    "news" -> Icons.Default.Newspaper
    "research_breakdown" -> Icons.Default.Science
    "motivational" -> Icons.Default.SelfImprovement
    "qna" -> Icons.Default.QuestionAnswer
    else -> Icons.Default.Lightbulb
}

fun conceptTypeIcon(conceptType: ConceptType): androidx.compose.ui.graphics.vector.ImageVector = when (conceptType) {
    ConceptType.CONCEPT -> Icons.Default.Lightbulb
    ConceptType.FRAMEWORK -> Icons.Default.AccountTree
    ConceptType.TOOL -> Icons.Default.Build
    ConceptType.BOOK -> Icons.Default.MenuBook
    ConceptType.PERSON -> Icons.Default.Person
    ConceptType.METHODOLOGY -> Icons.Default.Rule
    ConceptType.WEBSITE -> Icons.Default.Language
}

fun verifiabilityColor(v: Verifiability): Color = when (v) {
    Verifiability.FACT -> InsightrColors.Success
    Verifiability.OPINION -> InsightrColors.Accent
    Verifiability.UNVERIFIED -> InsightrColors.Danger
}

fun verifiabilityLabel(v: Verifiability): String = when (v) {
    Verifiability.FACT -> "Fact"
    Verifiability.OPINION -> "Opinion"
    Verifiability.UNVERIFIED -> "Unverified"
}
