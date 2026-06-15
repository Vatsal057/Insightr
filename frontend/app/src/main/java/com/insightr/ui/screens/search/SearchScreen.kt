package com.insightr.ui.screens.search

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
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.components.common.EmptyState
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.viewmodel.SearchViewModel

@Composable
fun SearchScreen(
    onEntryClick: (Int) -> Unit,
    onConceptClick: (Int) -> Unit,
    viewModel: SearchViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Header
        Text(
            text = "Insightr",
            style = MaterialTheme.typography.headlineLarge,
            color = InsightrColors.Accent
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Search bar
        OutlinedTextField(
            value = uiState.query,
            onValueChange = { viewModel.updateQuery(it) },
            modifier = Modifier.fillMaxWidth(),
            placeholder = {
                Text(
                    text = "Search insights...",
                    color = InsightrColors.TextDisabled
                )
            },
            leadingIcon = {
                Icon(
                    imageVector = Icons.Filled.Search,
                    contentDescription = null,
                    tint = InsightrColors.TextSecondary
                )
            },
            trailingIcon = {
                if (uiState.query.isNotBlank()) {
                    IconButton(onClick = { viewModel.updateQuery("") }) {
                        Icon(
                            imageVector = Icons.Filled.Clear,
                            contentDescription = "Clear",
                            tint = InsightrColors.TextSecondary
                        )
                    }
                }
            },
            shape = RoundedCornerShape(12.dp),
            colors = OutlinedTextFieldDefaults.colors(
                focusedBorderColor = InsightrColors.Accent,
                unfocusedBorderColor = InsightrColors.Border,
                focusedContainerColor = InsightrColors.Card,
                unfocusedContainerColor = InsightrColors.Card,
                focusedTextColor = InsightrColors.TextPrimary,
                unfocusedTextColor = InsightrColors.TextPrimary
            ),
            singleLine = true
        )

        Spacer(modifier = Modifier.height(12.dp))

        // Content type filter pills
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                CategoryPill(
                    label = "All",
                    isSelected = uiState.selectedContentType == null,
                    onClick = { viewModel.selectContentType(null) }
                )
            }
            val contentTypes = listOf("Article", "Paper", "Video", "Podcast", "Book")
            items(contentTypes) { type ->
                CategoryPill(
                    label = type,
                    isSelected = uiState.selectedContentType == type,
                    onClick = { viewModel.selectContentType(type) }
                )
            }
        }

        Spacer(modifier = Modifier.height(8.dp))

        // Tag filter pills
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            val tags = uiState.results.flatMap { it.tags }.distinct().take(5)
            items(tags) { tag ->
                CategoryPill(
                    label = tag,
                    isSelected = uiState.selectedTag == tag,
                    onClick = { viewModel.selectTag(tag) }
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        when {
            uiState.isLoading -> {
                Box(
                    modifier = Modifier.fillMaxSize(),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = InsightrColors.Accent)
                }
            }
            uiState.error != null -> {
                EmptyState(
                    icon = Icons.Filled.Search,
                    title = "Search failed",
                    subtitle = uiState.error ?: "Unknown error"
                )
            }
            uiState.hasSearched && uiState.results.isEmpty() -> {
                // No results
                Column(
                    modifier = Modifier.fillMaxSize(),
                    horizontalAlignment = Alignment.CenterHorizontally,
                    verticalArrangement = Arrangement.Center
                ) {
                    Icon(
                        imageVector = Icons.Filled.Search,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = InsightrColors.Accent
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "No results for \"${uiState.query}\"",
                        style = MaterialTheme.typography.headlineSmall,
                        color = InsightrColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(
                        text = "Try a broader query, or remove some filters to explore more of the knowledge base.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = InsightrColors.TextSecondary
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    CategoryPill(
                        label = "Clear Filters",
                        onClick = { viewModel.clearFilters() }
                    )
                }
            }
            uiState.results.isNotEmpty() -> {
                // Results count
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "${uiState.results.size} insights found",
                        style = MaterialTheme.typography.bodySmall,
                        color = InsightrColors.TextSecondary
                    )
                    Text(
                        text = "Relevance",
                        style = MaterialTheme.typography.bodySmall,
                        color = InsightrColors.TextSecondary
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(uiState.results) { feedItem ->
                        Card(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(vertical = 4.dp),
                            shape = RoundedCornerShape(12.dp),
                            colors = CardDefaults.cardColors(
                                containerColor = InsightrColors.Card
                            )
                        ) {
                            Column(
                                modifier = Modifier.padding(16.dp)
                            ) {
                                // Content type badge
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween
                                ) {
                                    CategoryPill(label = feedItem.field)
                                    if (feedItem.effortPill != null) {
                                        Text(
                                            text = feedItem.effortPill!!.timeToImplement,
                                            style = MaterialTheme.typography.labelSmall,
                                            color = InsightrColors.TextSecondary
                                        )
                                    }
                                }

                                Spacer(modifier = Modifier.height(8.dp))

                                Text(
                                    text = feedItem.title,
                                    style = MaterialTheme.typography.titleMedium,
                                    color = InsightrColors.TextPrimary,
                                    maxLines = 2,
                                    overflow = TextOverflow.Ellipsis
                                )

                                Spacer(modifier = Modifier.height(4.dp))

                                Text(
                                    text = feedItem.hook,
                                    style = MaterialTheme.typography.bodySmall,
                                    color = InsightrColors.TextSecondary,
                                    maxLines = 2,
                                    overflow = TextOverflow.Ellipsis
                                )

                                Spacer(modifier = Modifier.height(8.dp))

                                // Tags
                                LazyRow(
                                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                                ) {
                                    items(feedItem.tags.take(3)) { tag ->
                                        Card(
                                            shape = RoundedCornerShape(20.dp),
                                            colors = CardDefaults.cardColors(
                                                containerColor = InsightrColors.BackgroundSecondary
                                            )
                                        ) {
                                            Text(
                                                text = tag,
                                                style = MaterialTheme.typography.labelSmall,
                                                color = InsightrColors.TextSecondary,
                                                modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                                            )
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
