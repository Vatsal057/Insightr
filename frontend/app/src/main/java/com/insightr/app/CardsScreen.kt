package com.insightr.app

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.insightr.app.data.ApiResult
import com.insightr.app.data.InsightrRepository

/**
 * Concepts screen — backed by GET /api/concepts (main.py `concepts`).
 * Filterable by ConceptType. Each concept links to the entries it appeared
 * in via GET /api/concepts/{id}/entries.
 *
 * Framed as a growing personal wiki ("Your Wiki") — every new video
 * processed adds to this index automatically, which is the compound-
 * interest engagement hook: the longer you use Insightr, the more
 * valuable this screen becomes.
 */
@Composable
fun CardsScreen(onCardClick: (Int) -> Unit = {}) {
    var concepts by remember { mutableStateOf<List<Concept>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var offline by remember { mutableStateOf(false) }
    var selectedType by remember { mutableStateOf<ConceptType?>(null) }
    var searchQuery by remember { mutableStateOf("") }

    // Re-fetch whenever filter changes
    LaunchedEffect(selectedType, searchQuery) {
        isLoading = true
        when (val result = InsightrRepository.getConcepts(
            conceptType = selectedType?.name?.lowercase(),
            query = searchQuery.takeIf { it.isNotBlank() }
        )) {
            is ApiResult.Success -> { concepts = result.data; offline = result.offline }
            is ApiResult.Error -> {}
        }
        isLoading = false
    }

    val conceptTypes = ConceptType.values().toList()

    Box(modifier = Modifier.fillMaxSize().background(InsightrColors.BackgroundGradient)) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
            contentPadding = PaddingValues(top = 32.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                SectionHeader(
                    "Your Wiki",
                    subtitle = "${concepts.size} concepts, frameworks, and ideas — growing with every video."
                )
            }

            if (offline) item { OfflineBanner(onOpenSettings = {}) }

            // Inline search bar
            item {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(20.dp))
                        .background(InsightrColors.Cream)
                        .padding(horizontal = 16.dp, vertical = 12.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Default.Search, contentDescription = null, tint = InsightrColors.TextOnCreamMuted)
                    Spacer(modifier = Modifier.width(10.dp))
                    Box(modifier = Modifier.weight(1f)) {
                        if (searchQuery.isEmpty()) {
                            Text("Search concepts by name...", color = InsightrColors.TextOnCreamMuted, fontSize = 14.sp)
                        }
                        androidx.compose.foundation.text.BasicTextField(
                            value = searchQuery,
                            onValueChange = { searchQuery = it },
                            singleLine = true,
                            textStyle = androidx.compose.ui.text.TextStyle(color = InsightrColors.TextOnCream, fontSize = 14.sp),
                            modifier = Modifier.fillMaxWidth()
                        )
                    }
                    if (searchQuery.isNotEmpty()) {
                        Icon(
                            Icons.Default.Close,
                            contentDescription = "Clear",
                            tint = InsightrColors.TextOnCreamMuted,
                            modifier = Modifier.clickable { searchQuery = "" }
                        )
                    }
                }
            }

            // Type filter chips
            item {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    item {
                        FilterChip(label = "All", selected = selectedType == null, onClick = { selectedType = null })
                    }
                    items(conceptTypes) { type ->
                        val label = type.name.lowercase().replaceFirstChar { it.uppercase() }
                        FilterChip(label = label, selected = selectedType == type, onClick = {
                            selectedType = if (selectedType == type) null else type
                        })
                    }
                }
            }

            when {
                isLoading -> item {
                    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 32.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = InsightrColors.Accent)
                    }
                }
                concepts.isEmpty() -> item {
                    Text(
                        if (searchQuery.isNotBlank()) "No concepts match \"$searchQuery\"."
                        else "No concepts of this type yet — process more content to grow your wiki.",
                        color = InsightrColors.TextOnDarkMuted,
                        fontSize = 13.sp
                    )
                }
                else -> items(concepts) { concept ->
                    ConceptRow(concept = concept, onClick = {
                        concept.id?.let { onCardClick(it) }
                    })
                }
            }
        }
    }
}

@Composable
fun ConceptRow(concept: Concept, onClick: () -> Unit = {}) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(InsightrColors.Cream)
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(InsightrColors.AccentSoft),
            contentAlignment = Alignment.Center
        ) {
            Icon(conceptTypeIcon(concept.conceptType), contentDescription = null, tint = InsightrColors.TextOnCream)
        }
        Spacer(modifier = Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                concept.conceptType.name.lowercase().replaceFirstChar { it.uppercase() },
                color = InsightrColors.TextOnCreamMuted,
                fontSize = 11.sp,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                concept.name,
                color = InsightrColors.TextOnCream,
                fontSize = 15.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis
            )
            Text(
                concept.summary,
                color = InsightrColors.TextOnCreamMuted,
                fontSize = 12.sp,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
        }
        Spacer(modifier = Modifier.width(8.dp))
        // Badge showing how many entries mention this concept
        Box(
            modifier = Modifier
                .clip(RoundedCornerShape(10.dp))
                .background(Color.White.copy(alpha = 0.5f))
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Text(
                "${concept.entryCount}",
                color = InsightrColors.TextOnCream,
                fontSize = 11.sp,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
fun CardDetailScreen(
    cardId: Int,
    onEntryClick: (Int) -> Unit = {},
    onBack: () -> Unit = {}
) {
    var concept by remember { mutableStateOf<Concept?>(null) }
    var entries by remember { mutableStateOf<List<EntrySummary>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var offline by remember { mutableStateOf(false) }

    LaunchedEffect(cardId) {
        // Load the concept from the all-concepts list first (cheap)
        concept = SampleData.allConcepts.find { it.id == cardId }
            ?: InsightrRepository.getConcepts().let {
                if (it is ApiResult.Success) it.data.find { c -> c.id == cardId } else null
            }

        // Load entries that reference this concept
        when (val result = InsightrRepository.getConceptEntries(cardId)) {
            is ApiResult.Success -> { entries = result.data; offline = result.offline }
            is ApiResult.Error -> {}
        }
        isLoading = false
    }

    Box(modifier = Modifier.fillMaxSize().background(InsightrColors.BackgroundGradient)) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
            contentPadding = PaddingValues(top = 32.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                CircleIconButton(icon = Icons.Default.ArrowBack, onClick = onBack, filled = false)
            }

            if (offline) item { OfflineBanner(onOpenSettings = {}) }

            when {
                isLoading -> item {
                    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 32.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = InsightrColors.Accent)
                    }
                }
                concept == null -> item {
                    Text("Concept not found.", color = InsightrColors.TextOnDark, fontSize = 14.sp)
                }
                else -> {
                    val c = concept!!

                    item {
                        Column(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clip(RoundedCornerShape(24.dp))
                                .background(InsightrColors.Cream)
                                .padding(20.dp)
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Icon(
                                    conceptTypeIcon(c.conceptType),
                                    contentDescription = null,
                                    tint = InsightrColors.Accent,
                                    modifier = Modifier.size(20.dp)
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(
                                    c.conceptType.name.lowercase().replaceFirstChar { it.uppercase() },
                                    color = InsightrColors.TextOnCreamMuted,
                                    fontSize = 12.sp,
                                    fontWeight = FontWeight.SemiBold
                                )
                            }
                            Spacer(modifier = Modifier.height(6.dp))
                            Text(
                                c.name,
                                color = InsightrColors.TextOnCream,
                                fontSize = 24.sp,
                                fontWeight = FontWeight.Bold,
                                lineHeight = 30.sp
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                c.summary,
                                color = InsightrColors.TextOnCreamMuted,
                                fontSize = 14.sp,
                                lineHeight = 20.sp
                            )
                        }
                    }

                    item {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            Icon(
                                Icons.Default.Style,
                                contentDescription = null,
                                tint = InsightrColors.TextOnDarkMuted,
                                modifier = Modifier.size(16.dp)
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                "Mentioned in ${entries.size} ${if (entries.size == 1) "entry" else "entries"}",
                                color = InsightrColors.TextOnDark,
                                fontSize = 16.sp,
                                fontWeight = FontWeight.SemiBold
                            )
                        }
                    }

                    if (entries.isEmpty()) {
                        item {
                            Text(
                                "No entries linked yet.",
                                color = InsightrColors.TextOnDarkMuted,
                                fontSize = 13.sp
                            )
                        }
                    } else {
                        items(entries) { entry ->
                            EntrySummaryCard(entry = entry, onClick = { onEntryClick(entry.id) })
                        }
                    }
                }
            }
        }
    }
}
