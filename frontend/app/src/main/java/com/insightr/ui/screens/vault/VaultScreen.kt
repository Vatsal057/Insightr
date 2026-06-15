package com.insightr.ui.screens.vault

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
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Search
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
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
import com.insightr.ui.components.cards.ConceptCard
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.components.common.EmptyState
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.viewmodel.VaultViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VaultScreen(
    onConceptClick: (Int) -> Unit,
    onCollectionsClick: () -> Unit,
    viewModel: VaultViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Box(
        modifier = Modifier.fillMaxSize()
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(16.dp)
        ) {
            // Header
            Column {
                Text(
                    text = "Insightr",
                    style = MaterialTheme.typography.bodySmall,
                    color = InsightrColors.TextSecondary
                )
                Text(
                    text = "Knowledge\nVault",
                    style = MaterialTheme.typography.displayMedium,
                    color = InsightrColors.TextPrimary
                )
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Stats row
            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Card
                )
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp),
                    horizontalArrangement = Arrangement.SpaceEvenly
                ) {
                    StatItem(value = "${uiState.totalConcepts}", label = "Total Concepts")
                    StatItem(value = "6", label = "This Week")
                    StatItem(value = "218", label = "Linked Notes")
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Concept type filter pills
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                item {
                    CategoryPill(
                        label = "All",
                        isSelected = uiState.selectedConceptType == null,
                        onClick = { viewModel.selectConceptType(null) }
                    )
                }
                val types = listOf("Framework", "Tool", "Book", "Person", "Methodology")
                items(types) { type ->
                    CategoryPill(
                        label = type,
                        isSelected = uiState.selectedConceptType == type.lowercase(),
                        onClick = { viewModel.selectConceptType(type.lowercase()) }
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
                        title = "Error",
                        subtitle = uiState.error ?: "Unknown error"
                    )
                }
                else -> {
                    LazyColumn(
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(uiState.concepts) { concept ->
                            ConceptCard(
                                concept = concept,
                                onClick = { concept.id?.let { onConceptClick(it) } }
                            )
                        }
                    }
                }
            }
        }

        // FAB
        FloatingActionButton(
            onClick = onCollectionsClick,
            containerColor = InsightrColors.Accent,
            contentColor = InsightrColors.Background,
            modifier = Modifier
                .align(Alignment.BottomEnd)
                .padding(16.dp)
        ) {
            Icon(
                imageVector = Icons.Filled.Add,
                contentDescription = "Add"
            )
        }
    }
}

@Composable
private fun StatItem(value: String, label: String) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(
            text = value,
            style = MaterialTheme.typography.headlineMedium,
            color = InsightrColors.Accent,
            fontWeight = FontWeight.Bold
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = InsightrColors.TextSecondary
        )
    }
}
