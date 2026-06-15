package com.insightr.ui.screens.actions

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
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CheckboxDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
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
import com.insightr.data.api.ActionItemDto
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.components.common.EmptyState
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.viewmodel.ActionsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ActionsScreen(
    onEntryClick: (Int) -> Unit,
    viewModel: ActionsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Header
        Column {
            Text(
                text = "INSIGHTR",
                style = MaterialTheme.typography.labelSmall,
                color = InsightrColors.TextSecondary
            )
            Text(
                text = "Action\nItems",
                style = MaterialTheme.typography.displayMedium,
                color = InsightrColors.TextPrimary
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Filter pills
        LazyRow(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            item {
                CategoryPill(
                    label = "All",
                    isSelected = uiState.selectedFilter == null,
                    onClick = { viewModel.selectFilter(null) }
                )
            }
            item {
                CategoryPill(
                    label = "Now",
                    isSelected = uiState.selectedFilter == "now",
                    onClick = { viewModel.selectFilter("now") }
                )
            }
            item {
                CategoryPill(
                    label = "Soon",
                    isSelected = uiState.selectedFilter == "soon",
                    onClick = { viewModel.selectFilter("soon") }
                )
            }
            item {
                CategoryPill(
                    label = "Someday",
                    isSelected = uiState.selectedFilter == "someday",
                    onClick = { viewModel.selectFilter("someday") }
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
                    icon = Icons.Filled.CheckCircle,
                    title = "Error",
                    subtitle = uiState.error ?: "Unknown error"
                )
            }
            else -> {
                val filteredTodos = if (uiState.selectedFilter != null) {
                    uiState.pendingTodos.filter { it.priority == uiState.selectedFilter }
                } else {
                    uiState.pendingTodos
                }

                val groupedTodos = filteredTodos.groupBy { it.priority }

                LazyColumn(
                    verticalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    listOf("now", "soon", "someday").forEach { priority ->
                        val items = groupedTodos[priority] ?: emptyList()
                        if (items.isNotEmpty()) {
                            item {
                                Row(
                                    verticalAlignment = Alignment.CenterVertically,
                                    modifier = Modifier.padding(vertical = 4.dp)
                                ) {
                                    com.insightr.ui.components.chips.PriorityDot(priority = priority)
                                    Spacer(modifier = Modifier.padding(4.dp))
                                    Text(
                                        text = priority.replaceFirstChar { it.uppercase() },
                                        style = MaterialTheme.typography.titleMedium,
                                        color = InsightrColors.TextPrimary,
                                        fontWeight = FontWeight.Bold
                                    )
                                    Spacer(modifier = Modifier.padding(4.dp))
                                    Text(
                                        text = "${items.size}",
                                        style = MaterialTheme.typography.bodyMedium,
                                        color = InsightrColors.TextSecondary
                                    )
                                }
                            }

                            itemsIndexed(items) { _, action ->
                                ActionTodoCard(
                                    action = action,
                                    onCheck = { done -> viewModel.toggleTodo(action.id!!, done) }
                                )
                            }
                        }
                    }

                    // Completed section
                    if (uiState.completedTodos.isNotEmpty() && uiState.showCompleted) {
                        item {
                            HorizontalDivider(
                                modifier = Modifier.padding(vertical = 8.dp),
                                color = InsightrColors.Border
                            )
                            Text(
                                text = "Completed",
                                style = MaterialTheme.typography.titleMedium,
                                color = InsightrColors.TextPrimary,
                                fontWeight = FontWeight.Bold
                            )
                        }

                        items(uiState.completedTodos) { action ->
                            CompletedTodoCard(action = action)
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun ActionTodoCard(
    action: ActionItemDto,
    onCheck: (Boolean) -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = InsightrColors.Card
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = action.done,
                onCheckedChange = { onCheck(!action.done) },
                colors = CheckboxDefaults.colors(
                    checkedColor = InsightrColors.Accent,
                    uncheckedColor = InsightrColors.TextSecondary
                )
            )

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = action.text,
                    style = MaterialTheme.typography.bodyLarge,
                    color = InsightrColors.TextPrimary
                )
                action.title?.let { title ->
                    Text(
                        text = title,
                        style = MaterialTheme.typography.bodySmall,
                        color = InsightrColors.TextSecondary
                    )
                }
            }

            // Priority label
            if (action.timeEstimate != null) {
                Card(
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(4.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.BackgroundSecondary
                    )
                ) {
                    Text(
                        text = action.timeEstimate,
                        style = MaterialTheme.typography.labelSmall,
                        color = InsightrColors.TextSecondary,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
        }
    }
}

@Composable
private fun CompletedTodoCard(action: ActionItemDto) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = androidx.compose.foundation.shape.RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = InsightrColors.Card.copy(alpha = 0.5f)
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Checkbox(
                checked = true,
                onCheckedChange = null,
                colors = CheckboxDefaults.colors(
                    checkedColor = InsightrColors.Accent
                )
            )

            Column(
                modifier = Modifier.weight(1f)
            ) {
                Text(
                    text = action.text,
                    style = MaterialTheme.typography.bodyLarge,
                    color = InsightrColors.TextDisabled
                )
            }

            if (action.timeEstimate != null) {
                Card(
                    shape = androidx.compose.foundation.shape.RoundedCornerShape(4.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.BackgroundSecondary
                    )
                ) {
                    Text(
                        text = action.timeEstimate,
                        style = MaterialTheme.typography.labelSmall,
                        color = InsightrColors.TextDisabled,
                        modifier = Modifier.padding(horizontal = 8.dp, vertical = 4.dp)
                    )
                }
            }
        }
    }
}
