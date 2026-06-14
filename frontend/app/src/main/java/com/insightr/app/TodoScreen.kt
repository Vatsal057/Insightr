package com.insightr.app

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
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
import com.insightr.app.data.InsightrRepository
import kotlinx.coroutines.launch

/**
 * Cross-entry action item list — covers main.py `todo` / `check` via
 * GET /api/todo and POST /api/todo/{id}/check. Grouped by source entry,
 * with a circular completion ring as an engagement hook.
 */
@Composable
fun TodoScreen(onEntryClick: (Int) -> Unit = {}) {
    val scope = rememberCoroutineScope()
    val snackbarHostState = remember { SnackbarHostState() }

    var items by remember { mutableStateOf<List<Pair<ActionItem, String>>>(emptyList()) }
    var isLoading by remember { mutableStateOf(true) }
    var offline by remember { mutableStateOf(false) }
    var showDone by remember { mutableStateOf(false) }

    LaunchedEffect(Unit) {
        when (val result = InsightrRepository.getTodoWithEntryTitles()) {
            is ApiResult.Success -> { items = result.data; offline = result.offline }
            is ApiResult.Error -> {}
        }
        isLoading = false
    }

    val total = items.size
    val done = items.count { (action, _) -> action.done }
    val progress by animateFloatAsState(targetValue = if (total == 0) 0f else done.toFloat() / total)

    val grouped = items
        .filter { (action, _) -> showDone || !action.done }
        .groupBy { (action, title) -> (action.entryId ?: -1) to title }

    Box(modifier = Modifier.fillMaxSize().background(InsightrColors.BackgroundGradient)) {
        LazyColumn(
            modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
            contentPadding = PaddingValues(top = 32.dp, bottom = 24.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            item {
                SectionHeader("Action Items", subtitle = "Things to actually do with what you've learned.")
            }

            if (offline) item { OfflineBanner(onOpenSettings = {}) }

            item { ProgressCard(done = done, total = total, progress = progress) }

            item {
                Row(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                    FilterChip(label = "Pending", selected = !showDone, onClick = { showDone = false })
                    FilterChip(label = "All", selected = showDone, onClick = { showDone = true })
                }
            }

            when {
                isLoading -> item {
                    Box(modifier = Modifier.fillMaxWidth().padding(vertical = 32.dp), contentAlignment = Alignment.Center) {
                        CircularProgressIndicator(color = InsightrColors.Accent)
                    }
                }
                grouped.isEmpty() -> item {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clip(RoundedCornerShape(20.dp))
                            .background(Color.White.copy(alpha = 0.06f))
                            .padding(24.dp),
                        horizontalAlignment = Alignment.CenterHorizontally
                    ) {
                        Icon(Icons.Default.Celebration, contentDescription = null, tint = InsightrColors.Accent)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("All caught up! Nothing pending.", color = InsightrColors.TextOnDarkMuted, fontSize = 13.sp)
                    }
                }
                else -> {
                    grouped.forEach { (key, pairs) ->
                        val (entryId, title) = key
                        item {
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { if (entryId >= 0) onEntryClick(entryId) },
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(Icons.Default.Description, contentDescription = null, tint = InsightrColors.TextOnDarkMuted, modifier = Modifier.size(16.dp))
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(title, color = InsightrColors.TextOnDarkMuted, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                                Spacer(modifier = Modifier.weight(1f))
                                Icon(Icons.Default.ChevronRight, contentDescription = null, tint = InsightrColors.TextOnDarkMuted, modifier = Modifier.size(16.dp))
                            }
                        }
                        pairs.forEach { (action, _) ->
                            item {
                                Row(
                                    modifier = Modifier
                                        .fillMaxWidth()
                                        .clip(RoundedCornerShape(16.dp))
                                        .background(InsightrColors.Cream)
                                        .clickable {
                                            val newDone = !action.done
                                            items = items.map { (a, t) -> if (a.id == action.id) a.copy(done = newDone) to t else a to t }
                                            scope.launch {
                                                when (val result = InsightrRepository.checkTodo(action.id, newDone)) {
                                                    is ApiResult.Error -> {
                                                        items = items.map { (a, t) -> if (a.id == action.id) a.copy(done = !newDone) to t else a to t }
                                                        snackbarHostState.showSnackbar(result.message)
                                                    }
                                                    is ApiResult.Success -> {}
                                                }
                                            }
                                        }
                                        .padding(horizontal = 16.dp, vertical = 14.dp),
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(22.dp)
                                            .clip(CircleShape)
                                            .background(if (action.done) InsightrColors.Success else InsightrColors.CreamMuted),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        if (action.done) {
                                            Icon(Icons.Default.Check, contentDescription = null, tint = InsightrColors.Cream, modifier = Modifier.size(14.dp))
                                        }
                                    }
                                    Spacer(modifier = Modifier.width(12.dp))
                                    Text(
                                        action.text,
                                        color = if (action.done) InsightrColors.TextOnCreamMuted else InsightrColors.TextOnCream,
                                        fontSize = 14.sp,
                                        modifier = Modifier.weight(1f)
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }

        SnackbarHost(hostState = snackbarHostState, modifier = Modifier.align(Alignment.BottomCenter).padding(16.dp))
    }
}

@Composable
private fun ProgressCard(done: Int, total: Int, progress: Float) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(InsightrColors.Cream)
            .padding(20.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Box(modifier = Modifier.size(56.dp), contentAlignment = Alignment.Center) {
            CircularProgressIndicator(
                progress = { progress },
                modifier = Modifier.fillMaxSize(),
                color = InsightrColors.Accent,
                trackColor = InsightrColors.CreamMuted,
                strokeWidth = 5.dp
            )
            Text("${(progress * 100).toInt()}%", color = InsightrColors.TextOnCream, fontSize = 12.sp, fontWeight = FontWeight.Bold)
        }
        Spacer(modifier = Modifier.width(16.dp))
        Column {
            Text("$done of $total done", color = InsightrColors.TextOnCream, fontSize = 16.sp, fontWeight = FontWeight.Bold)
            Text(
                if (done == total && total > 0) "Everything actioned — nice work!" else "Keep the momentum going.",
                color = InsightrColors.TextOnCreamMuted,
                fontSize = 12.sp
            )
        }
    }
}
