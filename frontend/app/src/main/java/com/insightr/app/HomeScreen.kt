package com.insightr.app

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
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
import kotlinx.coroutines.delay

/**
 * Home screen — backed by GET /api/feed and GET /api/search.
 * Falls back to SampleData (with an [OfflineBanner]) if the backend
 * is unreachable, so the app stays usable as a demo.
 */
@Composable
fun HomeScreen(
    onEntryClick: (Int) -> Unit = {},
    onAddClick: () -> Unit = {},
    onSettingsClick: () -> Unit = {}
) {
    var query by remember { mutableStateOf("") }
    var selectedField by remember { mutableStateOf("All") }

    var entries by remember { mutableStateOf<List<EntrySummary>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var offline by remember { mutableStateOf(false) }
    var refreshKey by remember { mutableStateOf(0) }

    // Initial feed load (and pull-to-refresh via refreshKey)
    LaunchedEffect(refreshKey) {
        isLoading = true
        when (val result = InsightrRepository.getFeed()) {
            is ApiResult.Success -> {
                entries = result.data
                offline = result.offline
            }
            is ApiResult.Error -> offline = true
        }
        isLoading = false
    }

    // Debounced search — re-queries the backend as the user types, or
    // restores the unfiltered feed when the query/filter is cleared
    LaunchedEffect(query, selectedField) {
        if (query.isBlank() && selectedField == "All") {
            when (val result = InsightrRepository.getFeed()) {
                is ApiResult.Success -> { entries = result.data; offline = result.offline }
                is ApiResult.Error -> {}
            }
            return@LaunchedEffect
        }
        delay(350)
        val fieldFilter = if (selectedField == "All") null else selectedField
        when (val result = InsightrRepository.search(query, fieldFilter)) {
            is ApiResult.Success -> { entries = result.data; offline = result.offline }
            is ApiResult.Error -> {}
        }
    }

    val fields = listOf("All") + entries.map { it.field }.distinct()

    Box(modifier = Modifier.fillMaxSize().background(InsightrColors.BackgroundGradient)) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
            contentPadding = PaddingValues(top = 32.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.Top
                ) {
                    SectionHeader("Your\nKnowledge Base")
                    CircleIconButton(icon = Icons.Default.Settings, onClick = onSettingsClick, filled = false)
                }
            }

            if (offline) {
                item { OfflineBanner(onOpenSettings = onSettingsClick) }
            }

            item { SearchBar(query = query, onQueryChange = { query = it }) }

            item {
                LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    items(fields) { f ->
                        FilterChip(label = f, selected = f == selectedField, onClick = { selectedField = f })
                    }
                }
            }

            item { StatsStrip(entries = entries) }

            item {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Text("Recent Entries", color = InsightrColors.TextOnDark, fontSize = 18.sp, fontWeight = FontWeight.SemiBold)
                    Icon(
                        Icons.Default.Refresh,
                        contentDescription = "Refresh",
                        tint = InsightrColors.TextOnDarkMuted,
                        modifier = Modifier.size(18.dp).clickable { refreshKey++ }
                    )
                }
            }

            when {
                isLoading -> item {
                    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 32.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = InsightrColors.Accent)
                    }
                }
                entries.isEmpty() -> item { EmptyState(query = query, onAddClick = onAddClick) }
                else -> items(entries) { entry ->
                    EntrySummaryCard(entry = entry, onClick = { onEntryClick(entry.id) })
                }
            }

            item {
                PillButton(text = "Add new content", onClick = onAddClick)
                Spacer(modifier = Modifier.height(8.dp))
            }
        }
    }
}

@Composable
private fun SearchBar(query: String, onQueryChange: (String) -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(InsightrColors.Cream)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Default.Search, contentDescription = null, tint = InsightrColors.TextOnCreamMuted)
        Spacer(modifier = Modifier.width(10.dp))
        Box(modifier = Modifier.weight(1f)) {
            if (query.isEmpty()) {
                Text("Search entries, tags, topics...", color = InsightrColors.TextOnCreamMuted, fontSize = 14.sp)
            }
            BasicTextField(
                value = query,
                onValueChange = onQueryChange,
                singleLine = true,
                textStyle = androidx.compose.ui.text.TextStyle(color = InsightrColors.TextOnCream, fontSize = 14.sp),
                modifier = Modifier.fillMaxWidth()
            )
        }
        if (query.isNotEmpty()) {
            Icon(
                Icons.Default.Close,
                contentDescription = "Clear",
                tint = InsightrColors.TextOnCreamMuted,
                modifier = Modifier.clickable { onQueryChange("") }
            )
        }
    }
}

@Composable
private fun StatsStrip(entries: List<EntrySummary>) {
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
        StatPill(modifier = Modifier.weight(1f), value = entries.size.toString(), label = "Entries")
        StatPill(modifier = Modifier.weight(1f), value = entries.map { it.field }.distinct().size.toString(), label = "Fields")
        StatPill(modifier = Modifier.weight(1f), value = entries.flatMap { it.tags }.distinct().size.toString(), label = "Tags")
    }
}

@Composable
private fun StatPill(modifier: Modifier = Modifier, value: String, label: String) {
    Column(
        modifier = modifier
            .clip(RoundedCornerShape(16.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .padding(vertical = 12.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Text(value, color = InsightrColors.TextOnDark, fontSize = 18.sp, fontWeight = FontWeight.Bold)
        Text(label, color = InsightrColors.TextOnDarkMuted, fontSize = 11.sp)
    }
}

@Composable
fun EntrySummaryCard(entry: EntrySummary, onClick: () -> Unit = {}) {
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
                .size(52.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(InsightrColors.AccentSoft),
            contentAlignment = Alignment.Center
        ) {
            Icon(contentTypeIcon(entry.contentType), contentDescription = null, tint = InsightrColors.TextOnCream)
        }

        Spacer(modifier = Modifier.width(14.dp))

        Column(modifier = Modifier.weight(1f)) {
            Text(entry.title, color = InsightrColors.TextOnCream, fontSize = 15.sp, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Spacer(modifier = Modifier.height(2.dp))
            if (entry.headline.isNotBlank()) {
                Text(entry.headline, color = InsightrColors.TextOnCreamMuted, fontSize = 12.sp, maxLines = 1, overflow = TextOverflow.Ellipsis)
            } else {
                Text(
                    "${entry.field} · ${ContentTypes.displayName(entry.contentType)}",
                    color = InsightrColors.TextOnCreamMuted,
                    fontSize = 12.sp,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
            }
        }

        Box(
            modifier = Modifier
                .clip(CircleShape)
                .background(Color.White.copy(alpha = 0.5f))
                .padding(horizontal = 8.dp, vertical = 4.dp)
        ) {
            Text(entry.field, color = InsightrColors.TextOnCream, fontSize = 10.sp, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun EmptyState(query: String, onAddClick: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .padding(24.dp),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Icon(Icons.Default.SearchOff, contentDescription = null, tint = InsightrColors.TextOnDarkMuted)
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            if (query.isEmpty()) "Nothing here yet" else "No entries match \"$query\"",
            color = InsightrColors.TextOnDarkMuted,
            fontSize = 13.sp
        )
        Spacer(modifier = Modifier.height(12.dp))
        PillButton(text = "Add your first reel", onClick = onAddClick)
    }
}
