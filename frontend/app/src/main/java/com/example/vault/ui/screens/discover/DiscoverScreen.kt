package com.example.vault.ui.screens.discover

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Text
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vault.data.repository.VaultRepository
import com.example.vault.ui.components.*
import com.example.vault.theme.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiscoverScreen(
    repository: VaultRepository,
    onEntryClick: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val viewModel: DiscoverViewModel = viewModel(factory = DiscoverViewModel.factory(repository))
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val listState = rememberLazyListState()

    Box(
        modifier = modifier.fillMaxSize()
    ) {
        PullToRefreshBox(
            isRefreshing = uiState is DiscoverUiState.Loading,
            onRefresh    = viewModel::loadFeed,
        ) {
            LazyColumn(
                state = listState,
                modifier = Modifier.fillMaxSize(),
                contentPadding = PaddingValues(bottom = 120.dp),
            ) {
                // ─── Header ────────────────────────────────────────────────
                item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .statusBarsPadding()
                            .padding(horizontal = 24.dp)
                            .padding(top = 16.dp, bottom = 8.dp),
                    ) {
                        Text(
                            text = "Your Vault",
                            color = VaultTextTertiary,
                            fontSize = 13.sp,
                            fontWeight = FontWeight.Medium,
                            letterSpacing = 1.sp,
                        )
                        Spacer(Modifier.height(4.dp))
                        Row(
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.spacedBy(12.dp),
                        ) {
                            Text(
                                text = "Knowledge",
                                color = VaultTextPrimary,
                                fontSize = 32.sp,
                                fontWeight = FontWeight.Bold,
                            )
                            if (uiState is DiscoverUiState.Success) {
                                val count = (uiState as DiscoverUiState.Success).cards.size
                                Box(
                                    modifier = Modifier
                                        .background(VaultAccentMuted, PillCorner)
                                        .padding(horizontal = 10.dp, vertical = 4.dp),
                                ) {
                                    Text(
                                        text = "$count",
                                        color = VaultAccent,
                                        fontSize = 13.sp,
                                        fontWeight = FontWeight.SemiBold,
                                    )
                                }
                            }
                        }
                    }
                }

                when (val state = uiState) {
                    is DiscoverUiState.Loading -> {
                        items(5) { InsightCardSkeleton(modifier = Modifier.padding(vertical = 6.dp)) }
                    }

                    is DiscoverUiState.Error -> {
                        item {
                            ErrorState(message = state.message, onRetry = viewModel::loadFeed)
                        }
                    }

                    is DiscoverUiState.Success -> {
                        // Daily Discovery
                        if (state.dailyPick != null) {
                            item {
                                Column(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .padding(horizontal = 24.dp)
                                        .padding(bottom = 8.dp),
                                ) {
                                    Text(
                                        text = "Something Worth Revisiting",
                                        color = VaultTextTertiary,
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Medium,
                                        letterSpacing = 0.8f.sp,
                                        modifier = Modifier.padding(bottom = 10.dp),
                                    )
                                    DailyDiscoveryCard(
                                        card    = state.dailyPick,
                                        daysAgo = state.dailyPickDaysAgo,
                                        onClick = { onEntryClick(state.dailyPick.id) },
                                    )
                                }
                            }
                        }

                        // Recent horizontal strip
                        val recentCards = state.cards.take(6)
                        if (recentCards.isNotEmpty()) {
                            item {
                                Column(modifier = Modifier.fillMaxWidth().padding(top = 20.dp, bottom = 8.dp)) {
                                    Text(
                                        text = "Recent",
                                        color = VaultTextTertiary,
                                        fontSize = 11.sp,
                                        fontWeight = FontWeight.Medium,
                                        letterSpacing = 0.8f.sp,
                                        modifier = Modifier.padding(start = 24.dp, bottom = 10.dp),
                                    )
                                    LazyRow(
                                        contentPadding = PaddingValues(horizontal = 24.dp),
                                        horizontalArrangement = Arrangement.spacedBy(12.dp),
                                    ) {
                                        items(recentCards) { card ->
                                            MiniInsightCard(card = card, onClick = { onEntryClick(card.id) })
                                        }
                                    }
                                }
                            }
                        }

                        // Section header
                        item {
                            Text(
                                text = "All Insights",
                                color = VaultTextTertiary,
                                fontSize = 11.sp,
                                fontWeight = FontWeight.Medium,
                                letterSpacing = 0.8f.sp,
                                modifier = Modifier.padding(start = 24.dp, top = 16.dp, bottom = 8.dp),
                            )
                        }

                        // Feed
                        items(state.cards, key = { it.id }) { card ->
                            InsightCard(
                                card    = card,
                                onClick = { onEntryClick(card.id) },
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .padding(horizontal = 20.dp, vertical = 6.dp),
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun MiniInsightCard(card: com.example.vault.data.api.SummaryCard, onClick: () -> Unit) {
    GlassCard(
        modifier  = Modifier.width(200.dp).height(120.dp).clickable(onClick = onClick),
        shape     = MediumCorner,
        elevation = GlassElevation.Level1,
    ) {
        Column(
            modifier = Modifier.fillMaxSize().padding(14.dp),
            verticalArrangement = Arrangement.SpaceBetween,
        ) {
            FieldChip(text = card.field)
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(card.title, color = VaultTextPrimary, fontSize = 13.sp,
                    fontWeight = FontWeight.SemiBold, maxLines = 2, lineHeight = 18.sp)
                Text(formatDate(card.createdAt), color = VaultTextTertiary, fontSize = 10.sp)
            }
        }
    }
}

@Composable
private fun ErrorState(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier.fillMaxWidth().padding(40.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.spacedBy(16.dp),
    ) {
        Text("⚠", fontSize = 32.sp)
        Text("Can't reach Vault", color = VaultTextPrimary, fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
        Text(message, color = VaultTextSecondary, fontSize = 13.sp)
        Box(
            modifier = Modifier
                .background(VaultAccentMuted, PillCorner)
                .clickable(onClick = onRetry)
                .padding(horizontal = 20.dp, vertical = 10.dp),
        ) {
            Text("Retry", color = VaultAccent, fontSize = 14.sp, fontWeight = FontWeight.Medium)
        }
    }
}
