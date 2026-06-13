package com.example.vault.ui.screens.capture

import androidx.compose.animation.*
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush

import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vault.data.local.ProcessingHistoryDao
import com.example.vault.data.local.ProcessingHistoryEntity
import com.example.vault.data.repository.VaultRepository
import com.example.vault.ui.components.*
import com.example.vault.theme.*

@Composable
fun CaptureScreen(
    repository: VaultRepository,
    historyDao: ProcessingHistoryDao,
    onEntryReady: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val viewModel: CaptureViewModel = viewModel(factory = CaptureViewModel.factory(repository, historyDao))
    val uiState by viewModel.uiState.collectAsStateWithLifecycle()
    val history by viewModel.history.collectAsStateWithLifecycle()
    val clipboard = androidx.compose.ui.platform.LocalClipboard.current

    var urlText by remember { mutableStateOf("") }
    var tab by remember { mutableIntStateOf(0) }

    LaunchedEffect(uiState) {
        if (uiState is CaptureUiState.Done) {
            onEntryReady((uiState as CaptureUiState.Done).entryId)
            viewModel.reset()
        }
    }

    LaunchedEffect(Unit) {
        val clip = clipboard.getClipEntry()?.clipData?.getItemAt(0)?.text?.toString()
            ?: return@LaunchedEffect
        if (clip.startsWith("http") && urlText.isBlank()) urlText = clip
    }

    Box(modifier = modifier.fillMaxSize().background(VaultBackground)) {
        Column(modifier = Modifier.fillMaxSize()) {
            // Header
            Column(
                modifier = Modifier.fillMaxWidth()
                    .background(Brush.verticalGradient(listOf(VaultAccentDim, VaultBackground)))
                    .statusBarsPadding()
                    .padding(horizontal = 24.dp, vertical = 16.dp),
            ) {
                Text("Capture", color = VaultTextPrimary, fontSize = 32.sp, fontWeight = FontWeight.Bold)
                Text("Drop a link. AI does the rest.", color = VaultTextSecondary, fontSize = 14.sp, modifier = Modifier.padding(top = 4.dp))
            }

            // Tabs
            Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 24.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                listOf("Capture", "History").forEachIndexed { idx, label ->
                    Box(
                        modifier = Modifier
                            .background(if (tab == idx) VaultAccentMuted else VaultSurfaceL2, PillCorner)
                            .clickable { tab = idx }
                            .padding(horizontal = 16.dp, vertical = 8.dp),
                    ) {
                        Text(label, color = if (tab == idx) VaultAccent else VaultTextTertiary, fontSize = 13.sp, fontWeight = FontWeight.Medium)
                    }
                }
            }

            AnimatedContent(targetState = tab, label = "capture_tab") { currentTab ->
                if (currentTab == 0) {
                    CaptureTab(
                        uiState = uiState,
                        urlText = urlText,
                        onUrlChange = { urlText = it },
                        onSubmit = { viewModel.submit(urlText) },
                        onReset = { viewModel.reset(); urlText = "" },
                    )
                } else {
                    HistoryTab(history = history)
                }
            }
        }
    }
}

@Composable
private fun CaptureTab(
    uiState: CaptureUiState,
    urlText: String,
    onUrlChange: (String) -> Unit,
    onSubmit: () -> Unit,
    onReset: () -> Unit,
) {
    Column(modifier = Modifier.fillMaxSize().padding(24.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
        when (uiState) {
            is CaptureUiState.Idle, is CaptureUiState.Failed -> {
                GlassCard(shape = LargeCorner, elevation = GlassElevation.Level2, modifier = Modifier.fillMaxWidth()) {
                    OutlinedTextField(
                        value = urlText,
                        onValueChange = onUrlChange,
                        placeholder = { Text("Paste a link to anything…", color = VaultTextTertiary, fontSize = 16.sp) },
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedBorderColor = androidx.compose.ui.graphics.Color.Transparent,
                            focusedBorderColor   = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedTextColor   = VaultTextPrimary,
                            focusedTextColor     = VaultTextPrimary,
                            cursorColor          = VaultAccent,
                        ),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Uri, imeAction = ImeAction.Done),
                        keyboardActions = KeyboardActions(onDone = { onSubmit() }),
                        modifier = Modifier.fillMaxWidth().padding(8.dp),
                        minLines = 3,
                    )
                }
                if (uiState is CaptureUiState.Failed) {
                    Text("⚠ ${uiState.message}", color = VaultError, fontSize = 13.sp)
                }
                Box(
                    modifier = Modifier.fillMaxWidth()
                        .background(if (urlText.isNotBlank()) VaultAccent else VaultSurfaceL2, LargeCorner)
                        .clickable(enabled = urlText.isNotBlank(), onClick = onSubmit)
                        .padding(vertical = 18.dp),
                    contentAlignment = Alignment.Center,
                ) {
                    Text(
                        "Analyze with AI",
                        color = if (urlText.isNotBlank()) VaultBackground else VaultTextTertiary,
                        fontSize = 16.sp,
                        fontWeight = FontWeight.SemiBold,
                    )
                }
            }
            is CaptureUiState.Processing -> {
                Text("Processing: ${uiState.url.take(50)}…", color = VaultTextTertiary, fontSize = 12.sp)
                GlassCard(shape = LargeCorner, elevation = GlassElevation.Level2, modifier = Modifier.fillMaxWidth()) {
                    Column(modifier = Modifier.padding(24.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                        Text("AI is working…", color = VaultTextPrimary, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                        Text("This usually takes 30–90 seconds", color = VaultTextTertiary, fontSize = 12.sp)
                        Spacer(Modifier.height(16.dp))
                        ProcessingStepper(steps = uiState.steps)
                    }
                }
            }
            is CaptureUiState.Done -> {
                Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = VaultAccent)
                }
            }
        }
    }
}

@Composable
private fun HistoryTab(history: List<ProcessingHistoryEntity>) {
    if (history.isEmpty()) {
        Box(Modifier.fillMaxSize().padding(40.dp), contentAlignment = Alignment.Center) {
            Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Text("⏳", fontSize = 32.sp)
                Text("No processing history yet", color = VaultTextSecondary, fontSize = 15.sp)
            }
        }
        return
    }
    LazyColumn(contentPadding = PaddingValues(horizontal = 20.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(10.dp)) {
        items(history, key = { it.taskId }) { HistoryRow(it) }
    }
}

@Composable
private fun HistoryRow(item: ProcessingHistoryEntity) {
    val (icon, color) = when (item.status) {
        "completed"  -> Pair("✓",  VaultFact)
        "processing" -> Pair("⏳", VaultAccent)
        else         -> Pair("✕",  VaultError)
    }
    GlassCard(modifier = Modifier.fillMaxWidth(), shape = MediumCorner, elevation = GlassElevation.Level1) {
        Row(modifier = Modifier.padding(14.dp), horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(modifier = Modifier.size(32.dp).background(color.copy(0.15f), PillCorner), contentAlignment = Alignment.Center) {
                Text(icon, color = color, fontSize = 14.sp)
            }
            Column(modifier = Modifier.weight(1f)) {
                Text(item.url.take(50) + if (item.url.length > 50) "…" else "", color = VaultTextPrimary, fontSize = 13.sp, maxLines = 1)
                Text(item.status.replaceFirstChar { it.uppercase() }, color = color, fontSize = 11.sp)
                item.errorMessage?.let { Text(it, color = VaultError, fontSize = 11.sp, maxLines = 1) }
            }
        }
    }
}
