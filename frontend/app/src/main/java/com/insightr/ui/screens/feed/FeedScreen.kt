package com.insightr.ui.screens.feed

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.insightr.ui.components.cards.InsightCard
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.components.common.EmptyState
import com.insightr.ui.components.common.SkeletonCard
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.viewmodel.FeedViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun FeedScreen(
    onEntryClick: (Int) -> Unit,
    onAddClick: () -> Unit,
    viewModel: FeedViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Header
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Column {
                Text(
                    text = "Insightr",
                    style = MaterialTheme.typography.bodySmall,
                    color = InsightrColors.TextSecondary
                )
                Text(
                    text = "Your Vault",
                    style = MaterialTheme.typography.displayMedium,
                    color = InsightrColors.TextPrimary
                )
            }
            Icon(
                imageVector = Icons.Filled.Notifications,
                contentDescription = "Notifications",
                tint = InsightrColors.TextSecondary
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Field filter pills
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                CategoryPill(
                    label = "All",
                    isSelected = uiState.selectedField == null,
                    onClick = { viewModel.selectField(null) }
                )
            }
            val fields = uiState.feed.map { it.field }.distinct()
            items(fields) { field ->
                CategoryPill(
                    label = field,
                    isSelected = uiState.selectedField == field,
                    onClick = { viewModel.selectField(field) }
                )
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        when {
            uiState.isLoading -> {
                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(3) {
                        SkeletonCard()
                    }
                }
            }
            uiState.error != null -> {
                EmptyState(
                    icon = Icons.Filled.Notifications,
                    title = "Something went wrong",
                    subtitle = uiState.error ?: "Unknown error"
                )
            }
            uiState.feed.isEmpty() -> {
                EmptyState(
                    icon = Icons.Filled.Notifications,
                    title = "Your vault is empty",
                    subtitle = "Add a short to get started"
                )
            }
            else -> {
                val filteredFeed = if (uiState.selectedField != null) {
                    uiState.feed.filter { it.field == uiState.selectedField }
                } else {
                    uiState.feed
                }

                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    itemsIndexed(filteredFeed) { _, feedItem ->
                        InsightCard(
                            feedItem = feedItem,
                            onClick = { feedItem.id?.let { onEntryClick(it) } }
                        )
                    }
                }
            }
        }
    }
}
