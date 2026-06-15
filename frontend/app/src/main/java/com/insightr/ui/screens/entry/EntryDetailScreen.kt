package com.insightr.ui.screens.entry

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.KeyboardArrowDown
import androidx.compose.material.icons.filled.KeyboardArrowUp
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.insightr.data.api.EntryResponse
import com.insightr.ui.components.blocks.NoteBlockRenderer
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.components.chips.EffortPill
import com.insightr.ui.components.chips.PriorityDot
import com.insightr.ui.components.chips.VerifiabilityBadge
import com.insightr.ui.components.common.EmptyState
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.viewmodel.EntryDetailViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EntryDetailScreen(
    onBackClick: () -> Unit,
    onDeepResearch: (Int) -> Unit,
    onConceptClick: (Int) -> Unit,
    onExport: (Int) -> Unit,
    viewModel: EntryDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(InsightrColors.Background)
    ) {
        // Top bar
        TopAppBar(
            title = {
                Text(
                    text = "Your Insights",
                    style = MaterialTheme.typography.titleMedium
                )
            },
            navigationIcon = {
                IconButton(onClick = onBackClick) {
                    Icon(
                        imageVector = Icons.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = InsightrColors.TextPrimary
                    )
                }
            },
            colors = TopAppBarDefaults.topAppBarColors(
                containerColor = InsightrColors.Background
            )
        )

        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(
                        color = InsightrColors.Accent
                    )
                }
            }
            uiState.error != null -> {
                EmptyState(
                    icon = Icons.Filled.ArrowBack,
                    title = "Error loading entry",
                    subtitle = uiState.error ?: "Unknown error"
                )
            }
            uiState.entry != null -> {
                EntryContent(
                    entry = uiState.entry!!,
                    isZone3Expanded = uiState.isZone3Expanded,
                    onToggleZone3 = { viewModel.toggleZone3() },
                    onDeepResearch = { onDeepResearch(uiState.entry!!.id ?: 0) },
                    onConceptClick = onConceptClick,
                    onExport = { onExport(uiState.entry!!.id ?: 0) }
                )
            }
        }
    }
}

@Composable
private fun EntryContent(
    entry: EntryResponse,
    isZone3Expanded: Boolean,
    onToggleZone3: () -> Unit,
    onDeepResearch: () -> Unit,
    onConceptClick: (Int) -> Unit,
    onExport: () -> Unit
) {
    LazyColumn(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp),
        verticalArrangement = Arrangement.spacedBy(16.dp)
    ) {
        // Tags row
        item {
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(entry.tags) { tag ->
                    CategoryPill(label = tag)
                }
            }
        }

        // Title
        item {
            Text(
                text = entry.title,
                style = MaterialTheme.typography.displayMedium,
                color = InsightrColors.TextPrimary
            )
        }

        // Meta row (effort + read time)
        item {
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                entry.zoneGrab.effortPill?.let { pill ->
                    EffortPill(label = "Effort ${pill.label}")
                }
            }
        }

        // Zone 1: The Grab - DO THIS NOW card
        item {
            entry.zoneGrab.topAction?.let { action ->
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.Accent.copy(alpha = 0.15f)
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Row(
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "\u26A1",
                                style = MaterialTheme.typography.titleMedium
                            )
                            Spacer(modifier = Modifier.width(8.dp))
                            Text(
                                text = "DO THIS NOW",
                                style = MaterialTheme.typography.labelMedium,
                                color = InsightrColors.Accent,
                                fontWeight = FontWeight.Bold
                            )
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = action.text,
                            style = MaterialTheme.typography.bodyLarge,
                            color = InsightrColors.TextPrimary
                        )
                    }
                }
            }
        }

        // Next step
        item {
            Text(
                text = entry.zoneGrab.nextStep,
                style = MaterialTheme.typography.bodyMedium,
                color = InsightrColors.TextSecondary
            )
        }

        // Zone 2: The Substance - Core Takeaway
        item {
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Card
                )
            ) {
                Column(
                    modifier = Modifier.padding(16.dp)
                ) {
                    Text(
                        text = "CORE TAKEAWAY",
                        style = MaterialTheme.typography.labelMedium,
                        color = InsightrColors.Accent,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = entry.zoneSubstance.coreTakeaway.body,
                        style = MaterialTheme.typography.bodyLarge,
                        color = InsightrColors.TextPrimary
                    )
                }
            }
        }

        // Note blocks
        items(entry.zoneSubstance.noteBlocks) { block ->
            NoteBlockRenderer(block = block)
        }

        // Stat row from note blocks (if any stat_row type)
        entry.zoneSubstance.noteBlocks.filter { it.blockType == "stat_row" }.forEach { block ->
            item {
                NoteBlockRenderer(block = block)
            }
        }

        // Implementation Steps
        if (entry.zoneSubstance.implementationPlan.isNotEmpty()) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.Card
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "IMPLEMENTATION STEPS",
                            style = MaterialTheme.typography.labelMedium,
                            color = InsightrColors.Accent,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(12.dp))
                        entry.zoneSubstance.implementationPlan.forEach { step ->
                            Row(
                                modifier = Modifier.padding(vertical = 4.dp),
                                verticalAlignment = Alignment.Top
                            ) {
                                Box(
                                    modifier = Modifier
                                        .background(InsightrColors.Accent, RoundedCornerShape(50))
                                        .padding(horizontal = 8.dp, vertical = 2.dp)
                                ) {
                                    Text(
                                        text = "${step.stepNumber}",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = InsightrColors.Background
                                    )
                                }
                                Spacer(modifier = Modifier.width(12.dp))
                                Column {
                                    Text(
                                        text = step.title,
                                        style = MaterialTheme.typography.bodyLarge,
                                        color = InsightrColors.TextPrimary,
                                        fontWeight = FontWeight.SemiBold
                                    )
                                    Text(
                                        text = step.description,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = InsightrColors.TextSecondary
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // Action Items
        if (entry.zoneSubstance.actionItems.isNotEmpty()) {
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.Card
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "ACTION ITEMS",
                            style = MaterialTheme.typography.labelMedium,
                            color = InsightrColors.Accent,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(12.dp))

                        val grouped = entry.zoneSubstance.actionItems.groupBy { it.priority }
                        listOf("now", "soon", "someday").forEach { priority ->
                            grouped[priority]?.let { items ->
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(vertical = 4.dp)
                                ) {
                                    PriorityDot(priority = priority)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = priority.replaceFirstChar { it.uppercase() },
                                        style = MaterialTheme.typography.labelMedium,
                                        color = InsightrColors.TextPrimary
                                    )
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = "${items.size}",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = InsightrColors.TextSecondary
                                    )
                                }
                                items.forEach { action ->
                                    Row(
                                        modifier = Modifier
                                            .fillMaxWidth()
                                            .padding(start = 24.dp, vertical = 4.dp)
                                    ) {
                                        Text(
                                            text = "\u2022 ${action.text}",
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = InsightrColors.TextSecondary
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        // Recommended Tools
        if (entry.zoneSubstance.toolsResources.isNotEmpty()) {
            item {
                Column {
                    Text(
                        text = "RECOMMENDED TOOLS",
                        style = MaterialTheme.typography.labelMedium,
                        color = InsightrColors.Accent,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    LazyRow(
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        items(entry.zoneSubstance.toolsResources) { tool ->
                            Card(
                                shape = RoundedCornerShape(20.dp),
                                colors = CardDefaults.cardColors(
                                    containerColor = InsightrColors.BackgroundSecondary
                                )
                            ) {
                                Row(
                                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 8.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Text(
                                        text = tool.name,
                                        style = MaterialTheme.typography.labelMedium,
                                        color = InsightrColors.TextPrimary
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        // Go Deeper button (Zone 3 toggle)
        item {
            Card(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { onToggleZone3() },
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Accent
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.Center,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "Go Deeper",
                        style = MaterialTheme.typography.titleMedium,
                        color = InsightrColors.Background,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Icon(
                        imageVector = if (isZone3Expanded) Icons.Filled.KeyboardArrowUp else Icons.Filled.KeyboardArrowDown,
                        contentDescription = null,
                        tint = InsightrColors.Background
                    )
                }
            }
        }

        // Zone 3: The Deep End
        if (isZone3Expanded) {
            // Claims
            if (entry.zoneDeep.claims.isNotEmpty()) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = InsightrColors.Card
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "Claims ${entry.zoneDeep.claims.size}",
                                style = MaterialTheme.typography.titleMedium,
                                color = InsightrColors.TextPrimary,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            entry.zoneDeep.claims.forEach { claim ->
                                Row(
                                    modifier = Modifier.padding(vertical = 4.dp),
                                    verticalAlignment = Alignment.Top
                                ) {
                                    VerifiabilityBadge(verifiability = claim.verifiability)
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = claim.claim,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = InsightrColors.TextSecondary
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // What's Missing
            if (entry.zoneDeep.missingContext.isNotEmpty()) {
                item {
                    Card(
                        modifier = Modifier.fillMaxWidth(),
                        shape = RoundedCornerShape(12.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = InsightrColors.Card
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(16.dp)
                        ) {
                            Text(
                                text = "What's Missing ${entry.zoneDeep.missingContext.size}",
                                style = MaterialTheme.typography.titleMedium,
                                color = InsightrColors.TextPrimary,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                            entry.zoneDeep.missingContext.forEach { item ->
                                Row(
                                    modifier = Modifier.padding(vertical = 4.dp),
                                    verticalAlignment = Alignment.Top
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .background(
                                                getMissingContextColor(item.category).copy(alpha = 0.2f),
                                                RoundedCornerShape(4.dp)
                                            )
                                            .padding(horizontal = 8.dp, vertical = 2.dp)
                                    ) {
                                        Text(
                                            text = "[${item.category}]",
                                            style = MaterialTheme.typography.labelSmall,
                                            color = getMissingContextColor(item.category)
                                        )
                                    }
                                    Spacer(modifier = Modifier.width(8.dp))
                                    Text(
                                        text = item.text,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = InsightrColors.TextSecondary
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Rabbit Hole
            item {
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.Card
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Text(
                            text = "Rabbit Hole",
                            style = MaterialTheme.typography.titleMedium,
                            color = InsightrColors.TextPrimary,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(12.dp))

                        if (entry.zoneDeep.rabbitHole.followUpQuestions.isNotEmpty()) {
                            Text(
                                text = "Questions ${entry.zoneDeep.rabbitHole.followUpQuestions.size}",
                                style = MaterialTheme.typography.labelMedium,
                                color = InsightrColors.Accent
                            )
                            entry.zoneDeep.rabbitHole.followUpQuestions.forEach { q ->
                                Text(
                                    text = "\u2022 $q",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = InsightrColors.TextSecondary,
                                    modifier = Modifier.padding(start = 8.dp, vertical = 2.dp)
                                )
                            }
                        }

                        if (entry.zoneDeep.rabbitHole.knowledgeGaps.isNotEmpty()) {
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "Knowledge Gaps ${entry.zoneDeep.rabbitHole.knowledgeGaps.size}",
                                style = MaterialTheme.typography.labelMedium,
                                color = InsightrColors.Accent
                            )
                            entry.zoneDeep.rabbitHole.knowledgeGaps.forEach { gap ->
                                Text(
                                    text = "\u2022 $gap",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = InsightrColors.TextSecondary,
                                    modifier = Modifier.padding(start = 8.dp, vertical = 2.dp)
                                )
                            }
                        }
                    }
                }
            }

            // Knowledge Cards
            if (entry.zoneDeep.knowledgeCards.isNotEmpty()) {
                item {
                    Column {
                        Text(
                            text = "Knowledge Cards ${entry.zoneDeep.knowledgeCards.size}",
                            style = MaterialTheme.typography.titleMedium,
                            color = InsightrColors.TextPrimary,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        LazyRow(
                            horizontalArrangement = Arrangement.spacedBy(8.dp)
                        ) {
                            items(entry.zoneDeep.knowledgeCards) { concept ->
                                Card(
                                    modifier = Modifier.clickable { concept.id?.let { onConceptClick(it) } },
                                    shape = RoundedCornerShape(8.dp),
                                    colors = CardDefaults.cardColors(
                                        containerColor = InsightrColors.Card
                                    )
                                ) {
                                    Column(
                                        modifier = Modifier.padding(12.dp)
                                    ) {
                                        Box(
                                            modifier = Modifier
                                                .background(
                                                    InsightrColors.ConceptFramework.copy(alpha = 0.2f),
                                                    RoundedCornerShape(4.dp)
                                                )
                                                .padding(horizontal = 6.dp, vertical = 2.dp)
                                        ) {
                                            Text(
                                                text = concept.conceptType,
                                                style = MaterialTheme.typography.labelSmall,
                                                color = InsightrColors.ConceptFramework
                                            )
                                        }
                                        Spacer(modifier = Modifier.height(4.dp))
                                        Text(
                                            text = concept.name,
                                            style = MaterialTheme.typography.bodyMedium,
                                            color = InsightrColors.TextPrimary
                                        )
                                        Text(
                                            text = concept.summary,
                                            style = MaterialTheme.typography.bodySmall,
                                            color = InsightrColors.TextSecondary,
                                            maxLines = 2
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // Related Notes (Connections)
            if (entry.zoneDeep.connections.isNotEmpty()) {
                item {
                    Column {
                        Text(
                            text = "Related Notes ${entry.zoneDeep.connections.size}",
                            style = MaterialTheme.typography.titleMedium,
                            color = InsightrColors.TextPrimary,
                            fontWeight = FontWeight.Bold
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        entry.zoneDeep.connections.forEach { connection ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(vertical = 4.dp),
                                shape = RoundedCornerShape(8.dp),
                                colors = CardDefaults.cardColors(
                                    containerColor = InsightrColors.Card
                                )
                            ) {
                                Column(
                                    modifier = Modifier.padding(12.dp)
                                ) {
                                    Text(
                                        text = connection.title,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = InsightrColors.TextPrimary
                                    )
                                    Text(
                                        text = connection.reason,
                                        style = MaterialTheme.typography.bodySmall,
                                        color = InsightrColors.TextSecondary
                                    )
                                }
                            }
                        }
                    }
                }
            }

            // Deep Research button
            item {
                Card(
                    modifier = Modifier
                        .fillMaxWidth()
                        .clickable { onDeepResearch() },
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.Accent
                    )
                ) {
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(16.dp),
                        horizontalArrangement = Arrangement.Center,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "Open Deep Research Prompt",
                            style = MaterialTheme.typography.titleMedium,
                            color = InsightrColors.Background,
                            fontWeight = FontWeight.Bold
                        )
                    }
                }
            }

            // Tags at bottom
            item {
                LazyRow(
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    items(entry.tags) { tag ->
                        CategoryPill(label = "#$tag")
                    }
                }
            }
        }
    }
}

private fun getMissingContextColor(category: String): androidx.compose.ui.graphics.Color {
    return when (category) {
        "risk" -> InsightrColors.CategoryRisk
        "assumption" -> InsightrColors.CategoryAssumption
        "trade_off" -> InsightrColors.CategoryTradeOff
        "limitation" -> InsightrColors.CategoryLimitation
        "alternative" -> InsightrColors.CategoryAlternative
        else -> InsightrColors.CategoryAdditionalContext
    }
}
