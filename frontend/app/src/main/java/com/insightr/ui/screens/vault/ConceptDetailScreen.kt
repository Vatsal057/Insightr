package com.insightr.ui.screens.vault

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
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
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.components.common.EmptyState
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.viewmodel.ConceptDetailUiState
import com.insightr.ui.viewmodel.ConceptDetailViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ConceptDetailScreen(
    onBackClick: () -> Unit,
    onEntryClick: (Int) -> Unit,
    viewModel: ConceptDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(InsightrColors.Background)
    ) {
        TopAppBar(
            title = { },
            navigationIcon = {
                IconButton(onClick = onBackClick) {
                    Icon(
                        imageVector = Icons.Filled.ArrowBack,
                        contentDescription = "Back",
                        tint = InsightrColors.TextPrimary
                    )
                }
            },
            actions = {
                IconButton(onClick = { }) {
                    Icon(
                        imageVector = Icons.Filled.Check,
                        contentDescription = "Bookmark",
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
                    CircularProgressIndicator(color = InsightrColors.Accent)
                }
            }
            uiState.error != null -> {
                EmptyState(
                    icon = Icons.Filled.ArrowBack,
                    title = "Error",
                    subtitle = uiState.error ?: "Unknown error"
                )
            }
            uiState.concept != null -> {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxSize()
                        .padding(16.dp),
                    verticalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // Concept type badge
                    item {
                        CategoryPill(label = uiState.concept!!.conceptType.replaceFirstChar { it.uppercase() })
                    }

                    // Title
                    item {
                        Text(
                            text = uiState.concept!!.name,
                            style = MaterialTheme.typography.displayMedium,
                            color = InsightrColors.TextPrimary
                        )
                    }

                    // Summary card
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
                                    text = "SUMMARY",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = InsightrColors.Accent,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Text(
                                    text = uiState.concept!!.summary,
                                    style = MaterialTheme.typography.bodyLarge,
                                    color = InsightrColors.TextPrimary
                                )
                            }
                        }
                    }

                    // Appears in
                    if (uiState.entries.isNotEmpty()) {
                        item {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                Text(
                                    text = "Appears in",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = InsightrColors.TextPrimary,
                                    fontWeight = FontWeight.Bold
                                )
                                Text(
                                    text = "See all",
                                    style = MaterialTheme.typography.bodySmall,
                                    color = InsightrColors.Accent
                                )
                            }
                        }

                        items(uiState.entries.take(4)) { entry ->
                            Card(
                                modifier = Modifier
                                    .fillMaxWidth(),
                                shape = RoundedCornerShape(8.dp),
                                colors = CardDefaults.cardColors(
                                    containerColor = InsightrColors.Card
                                )
                            ) {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(12.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Icon(
                                        imageVector = Icons.Filled.Check,
                                        contentDescription = null,
                                        tint = InsightrColors.Accent
                                    )
                                    Spacer(modifier = Modifier.padding(8.dp))
                                    Text(
                                        text = entry.title,
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = InsightrColors.TextPrimary,
                                        modifier = Modifier.weight(1f)
                                    )
                                    Text(
                                        text = entry.createdAt.take(10),
                                        style = MaterialTheme.typography.bodySmall,
                                        color = InsightrColors.TextSecondary
                                    )
                                }
                            }
                        }
                    }

                    // Add a note button
                    item {
                        Card(
                            modifier = Modifier.fillMaxWidth(),
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
                                    text = "+ Add a Note",
                                    style = MaterialTheme.typography.titleMedium,
                                    color = InsightrColors.Background,
                                    fontWeight = FontWeight.Bold
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}


