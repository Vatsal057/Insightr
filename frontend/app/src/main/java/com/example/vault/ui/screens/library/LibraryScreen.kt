package com.example.vault.ui.screens.library

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vault.data.api.SummaryCard
import com.example.vault.data.repository.VaultRepository
import com.example.vault.ui.components.*
import com.example.vault.theme.*

@Composable
fun LibraryScreen(
    repository: VaultRepository,
    onEntryClick: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val viewModel: LibraryViewModel = viewModel(factory = LibraryViewModel.factory(repository))
    val state by viewModel.state.collectAsStateWithLifecycle()
    var tab by remember { mutableIntStateOf(0) }

    Box(modifier = modifier.fillMaxSize()) {
        LazyColumn(modifier = Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 120.dp)) {
            // Header
            item {
                Column(
                    modifier = Modifier.fillMaxWidth()
                        .background(Brush.verticalGradient(listOf(VaultAccentDim, VaultBackground)))
                        .statusBarsPadding()
                        .padding(horizontal = 24.dp).padding(top = 16.dp, bottom = 20.dp),
                ) {
                    Text("Library", color = VaultTextPrimary, fontSize = 32.sp, fontWeight = FontWeight.Bold)
                    Text("Your curated knowledge", color = VaultTextSecondary, fontSize = 14.sp, modifier = Modifier.padding(top = 4.dp))
                }
            }

            // Tabs
            item {
                Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    listOf("All" to state.allEntries.size, "Favorites" to state.favorites.size).forEachIndexed { idx, (label, count) ->
                        Row(
                            modifier = Modifier.background(if (tab == idx) VaultAccentMuted else VaultSurfaceL2, PillCorner)
                                .clickable { tab = idx }.padding(horizontal = 16.dp, vertical = 8.dp),
                            horizontalArrangement = Arrangement.spacedBy(6.dp), verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Text(label, color = if (tab == idx) VaultAccent else VaultTextTertiary, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                            if (count > 0) {
                                Box(Modifier.background(if (tab == idx) VaultAccent else VaultSurfaceL3, PillCorner).padding(horizontal = 6.dp, vertical = 1.dp)) {
                                    Text("$count", color = if (tab == idx) VaultBackground else VaultTextTertiary, fontSize = 10.sp)
                                }
                            }
                        }
                    }
                }
            }

            val displayCards = if (tab == 0) state.allEntries else state.favorites

            if (state.isLoading) {
                items(4) { InsightCardSkeleton(modifier = Modifier.padding(vertical = 6.dp)) }
            } else if (displayCards.isEmpty()) {
                item {
                    Box(Modifier.fillMaxWidth().padding(60.dp), contentAlignment = Alignment.Center) {
                        Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text(if (tab == 0) "⊞" else "★", fontSize = 32.sp, color = VaultTextTertiary)
                            Text(if (tab == 0) "No entries yet" else "No favorites yet", color = VaultTextSecondary, fontSize = 15.sp)
                        }
                    }
                }
            } else {
                items(displayCards, key = { it.id }) { card ->
                    LibraryEntryRow(card, card.id in state.favoriteIds, { onEntryClick(card.id) }, { viewModel.toggleFavorite(card.id) })
                }
            }
        }
    }
}

@Composable
private fun LibraryEntryRow(card: SummaryCard, isFavorite: Boolean, onClick: () -> Unit, onFavorite: () -> Unit) {
    Row(modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 24.dp, vertical = 14.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(modifier = Modifier.size(44.dp).background(VaultAccentMuted, MediumCorner), contentAlignment = Alignment.Center) {
            Text("◈", color = VaultAccent, fontSize = 20.sp)
        }
        Column(modifier = Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(card.title, color = VaultTextPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium, maxLines = 1)
            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                FieldChip(text = card.field)
                Text(formatDate(card.createdAt), color = VaultTextTertiary, fontSize = 11.sp)
            }
        }
        Text(if (isFavorite) "★" else "☆", color = if (isFavorite) VaultWarmAmber else VaultTextTertiary, fontSize = 20.sp,
            modifier = Modifier.clickable(onClick = onFavorite))
    }
    HorizontalDivider(color = VaultDivider, modifier = Modifier.padding(horizontal = 24.dp))
}
