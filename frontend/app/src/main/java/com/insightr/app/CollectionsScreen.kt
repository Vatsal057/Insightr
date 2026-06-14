package com.insightr.app

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
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
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.insightr.app.data.ApiResult
import com.insightr.app.data.CollectionDto
import com.insightr.app.data.InsightrRepository
import kotlinx.coroutines.launch

/**
 * Vaults (collections) — covers GET/POST /api/collections (main.py
 * `collection list` / `collection add`). New vaults are created the first
 * time an entry is added to a not-yet-existing name (handled server-side
 * by db.add_to_collection), so creating one here just registers the name
 * locally until an entry is added to it from EntryDetailScreen.
 */
@Composable
fun CollectionsScreen(onCollectionClick: (String) -> Unit = {}) {
    var collections by remember { mutableStateOf<List<CollectionDto>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var offline by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        when (val result = InsightrRepository.getCollections()) {
            is ApiResult.Success -> { collections = result.data; offline = result.offline }
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
                SectionHeader("Vaults", subtitle = "Themed collections of everything you've saved.")
            }

            if (offline) item { OfflineBanner(onOpenSettings = {}) }

            when {
                isLoading -> item {
                    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 32.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = InsightrColors.Accent)
                    }
                }
                collections.isEmpty() -> item {
                    Text(
                        "No vaults yet — open an entry and add it to a vault to create one.",
                        color = InsightrColors.TextOnDarkMuted,
                        fontSize = 13.sp
                    )
                }
                else -> items(collections) { collection ->
                    VaultRow(name = collection.name, entryCount = collection.entryCount, onClick = { onCollectionClick(collection.name) })
                }
            }
        }
    }
}

@Composable
private fun VaultRow(name: String, entryCount: Int, onClick: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(
            modifier = Modifier
                .size(48.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(InsightrColors.PillDark),
            contentAlignment = Alignment.Center
        ) {
            Icon(Icons.Default.Folder, contentDescription = null, tint = InsightrColors.Accent)
        }
        Spacer(modifier = Modifier.width(14.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(name, color = InsightrColors.TextOnDark, fontSize = 15.sp, fontWeight = FontWeight.SemiBold)
            Text("$entryCount ${if (entryCount == 1) "entry" else "entries"}", color = InsightrColors.TextOnDarkMuted, fontSize = 12.sp)
        }
        Icon(Icons.Default.ChevronRight, contentDescription = null, tint = InsightrColors.TextOnDarkMuted)
    }
}

@Composable
fun CollectionDetailScreen(
    name: String,
    onEntryClick: (Int) -> Unit = {},
    onBack: () -> Unit = {}
) {
    var entries by remember { mutableStateOf<List<EntrySummary>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var offline by remember { mutableStateOf(false) }

    LaunchedEffect(name) {
        when (val result = InsightrRepository.getCollection(name)) {
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
                Row(verticalAlignment = Alignment.CenterVertically) {
                    CircleIconButton(icon = Icons.Default.ArrowBack, onClick = onBack, filled = false)
                    Spacer(modifier = Modifier.width(12.dp))
                    SectionHeader(name)
                }
            }

            if (offline) item { OfflineBanner(onOpenSettings = {}) }

            when {
                isLoading -> item {
                    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 32.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = InsightrColors.Accent)
                    }
                }
                entries.isEmpty() -> item { Text("Nothing saved here yet.", color = InsightrColors.TextOnDarkMuted, fontSize = 13.sp) }
                else -> items(entries) { entry ->
                    EntrySummaryCard(entry = entry, onClick = { onEntryClick(entry.id) })
                }
            }
        }
    }
}
