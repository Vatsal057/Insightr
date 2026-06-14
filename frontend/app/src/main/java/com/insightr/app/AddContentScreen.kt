package com.insightr.app

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
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
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.insightr.app.data.ApiResult
import com.insightr.app.data.InsightrRepository
import kotlinx.coroutines.delay

/**
 * Covers `main.py process <url>`:
 *  POST /api/process -> {task_id}
 *  GET  /api/status/{task_id} -> {status: processing|completed|failed, entry_id?, error?}
 *
 * The backend doesn't report per-step progress, so the step list below is a
 * cosmetic "what's probably happening" indicator driven by elapsed polling
 * time — it turns a 20-60s wait into a reward sequence without claiming
 * precision the backend doesn't provide.
 */

private enum class PipelineStep(val label: String, val icon: androidx.compose.ui.graphics.vector.ImageVector, val etaSeconds: Int) {
    DOWNLOAD("Downloading content", Icons.Default.Download, 5),
    TRANSCRIBE("Transcribing audio", Icons.Default.RecordVoiceOver, 25),
    KEYFRAMES("Extracting keyframes & OCR", Icons.Default.PhotoLibrary, 10),
    EXTRACT("Generating knowledge entry", Icons.Default.AutoAwesome, 20),
    SAVE("Saving & finding connections", Icons.Default.Save, 5)
}

private sealed class PipelineState {
    object Idle : PipelineState()
    object Starting : PipelineState()
    data class Processing(val elapsedSeconds: Int) : PipelineState()
    data class Done(val entryId: Int) : PipelineState()
    data class Failed(val message: String) : PipelineState()
}

@Composable
fun AddContentScreen(onDone: (Int) -> Unit = {}) {
    var url by remember { mutableStateOf("") }
    var state by remember { mutableStateOf<PipelineState>(PipelineState.Idle) }

    fun start() {
        state = PipelineState.Starting
    }

    // Owns the actual task id + polling loop
    var taskId by remember { mutableStateOf<String?>(null) }
    LaunchedEffect(state is PipelineState.Starting) {
        if (state is PipelineState.Starting) {
            when (val result = InsightrRepository.processUrl(url)) {
                is ApiResult.Success -> {
                    taskId = result.data
                    state = PipelineState.Processing(0)
                }
                is ApiResult.Error -> state = PipelineState.Failed(result.message)
            }
        }
    }

    LaunchedEffect(taskId, state is PipelineState.Processing) {
        val id = taskId ?: return@LaunchedEffect
        if (state !is PipelineState.Processing) return@LaunchedEffect
        var elapsed = 0
        while (true) {
            delay(2000)
            elapsed += 2
            when (val result = InsightrRepository.getStatus(id)) {
                is ApiResult.Success -> {
                    val status = result.data
                    when (status.status) {
                        "completed" -> {
                            state = PipelineState.Done(status.entryId ?: -1)
                            return@LaunchedEffect
                        }
                        "failed" -> {
                            state = PipelineState.Failed(status.error ?: "Processing failed.")
                            return@LaunchedEffect
                        }
                        else -> state = PipelineState.Processing(elapsed)
                    }
                }
                is ApiResult.Error -> {
                    state = PipelineState.Failed(result.message)
                    return@LaunchedEffect
                }
            }
        }
    }

    LaunchedEffect(state) {
        if (state is PipelineState.Done) {
            delay(900)
            onDone((state as PipelineState.Done).entryId)
        }
    }

    val isBusy = state is PipelineState.Starting || state is PipelineState.Processing || state is PipelineState.Done

    Box(modifier = Modifier.fillMaxSize().background(InsightrColors.BackgroundGradient)) {
        Column(modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 32.dp)) {
            SectionHeader(
                title = "Add Knowledge",
                subtitle = "Paste a Reel, Short, or TikTok link and Insightr will turn it into a structured note."
            )

            Spacer(modifier = Modifier.height(24.dp))

            UrlInputField(url = url, onUrlChange = { url = it }, enabled = !isBusy)

            Spacer(modifier = Modifier.height(12.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SourceChip("Instagram")
                SourceChip("TikTok")
                SourceChip("YouTube Shorts")
            }

            Spacer(modifier = Modifier.height(24.dp))

            if (!isBusy) {
                PillButton(
                    text = "Extract Knowledge",
                    onClick = { if (url.isNotBlank()) start() },
                    enabled = url.isNotBlank()
                )
            }

            (state as? PipelineState.Failed)?.let { failed ->
                Spacer(modifier = Modifier.height(16.dp))
                ErrorPanel(message = failed.message, onRetry = { state = PipelineState.Idle })
            }

            Spacer(modifier = Modifier.height(32.dp))

            AnimatedVisibility(visible = isBusy, enter = fadeIn(), exit = fadeOut()) {
                PipelinePanel(state = state)
            }

            Spacer(modifier = Modifier.weight(1f))
        }
    }
}

@Composable
private fun UrlInputField(url: String, onUrlChange: (String) -> Unit, enabled: Boolean) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(InsightrColors.Cream)
            .padding(horizontal = 16.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Default.Link, contentDescription = null, tint = InsightrColors.TextOnCreamMuted)
        Spacer(modifier = Modifier.width(10.dp))
        Box(modifier = Modifier.weight(1f)) {
            if (url.isEmpty()) {
                Text("Paste a link to a Reel, Short, or TikTok...", color = InsightrColors.TextOnCreamMuted, fontSize = 14.sp)
            }
            BasicTextField(
                value = url,
                onValueChange = onUrlChange,
                enabled = enabled,
                singleLine = true,
                textStyle = TextStyle(color = InsightrColors.TextOnCream, fontSize = 14.sp),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun SourceChip(label: String) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .padding(horizontal = 12.dp, vertical = 6.dp)
    ) {
        Text(label, color = InsightrColors.TextOnDarkMuted, fontSize = 12.sp)
    }
}

@Composable
private fun ErrorPanel(message: String, onRetry: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(InsightrColors.Danger.copy(alpha = 0.15f))
            .padding(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = InsightrColors.Danger, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text("Couldn't process this link", color = InsightrColors.Danger, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(message, color = InsightrColors.TextOnDark, fontSize = 12.sp, lineHeight = 17.sp)
        Spacer(modifier = Modifier.height(10.dp))
        Text(
            "Try again",
            color = InsightrColors.Accent,
            fontSize = 13.sp,
            fontWeight = FontWeight.SemiBold,
            modifier = Modifier.clickable(onClick = onRetry)
        )
    }
}

@Composable
private fun PipelinePanel(state: PipelineState) {
    val totalEta = PipelineStep.values().sumOf { it.etaSeconds }
    val elapsed = when (state) {
        is PipelineState.Processing -> state.elapsedSeconds
        is PipelineState.Done -> totalEta
        else -> 0
    }
    val progress by animateFloatAsState(targetValue = (elapsed.toFloat() / totalEta).coerceIn(0f, 1f))

    // Figure out which step we're "probably" on based on cumulative ETA
    var cumulative = 0
    val activeIndex = PipelineStep.values().indexOfFirst { step ->
        cumulative += step.etaSeconds
        elapsed < cumulative
    }.let { if (it == -1) PipelineStep.values().lastIndex else it }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .padding(20.dp)
    ) {
        Text(
            when (state) {
                is PipelineState.Done -> "New entry saved to your vault! 🎉"
                is PipelineState.Starting -> "Starting..."
                else -> "Working on it..."
            },
            color = InsightrColors.TextOnDark,
            fontSize = 18.sp,
            fontWeight = FontWeight.Bold
        )
        Spacer(modifier = Modifier.height(12.dp))

        LinearProgressIndicator(
            progress = { progress },
            modifier = Modifier.fillMaxWidth().height(6.dp).clip(RoundedCornerShape(3.dp)),
            color = InsightrColors.Accent,
            trackColor = InsightrColors.PillDark
        )

        Spacer(modifier = Modifier.height(16.dp))

        PipelineStep.values().forEachIndexed { index, step ->
            val stepState = when {
                state is PipelineState.Done || index < activeIndex -> StepState.DONE
                index == activeIndex -> StepState.ACTIVE
                else -> StepState.PENDING
            }
            PipelineStepRow(step = step, state = stepState)
            if (index != PipelineStep.values().lastIndex) {
                Spacer(modifier = Modifier.height(10.dp))
            }
        }

        if (state is PipelineState.Processing && state.elapsedSeconds > totalEta) {
            Spacer(modifier = Modifier.height(10.dp))
            Text(
                "Still working — this one's taking a bit longer than usual.",
                color = InsightrColors.TextOnDarkMuted,
                fontSize = 12.sp
            )
        }
    }
}

private enum class StepState { DONE, ACTIVE, PENDING }

@Composable
private fun PipelineStepRow(step: PipelineStep, state: StepState) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Box(
            modifier = Modifier
                .size(32.dp)
                .clip(CircleShape)
                .background(
                    when (state) {
                        StepState.DONE -> InsightrColors.Success
                        StepState.ACTIVE -> InsightrColors.Accent
                        StepState.PENDING -> InsightrColors.PillDark
                    }
                ),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = if (state == StepState.DONE) Icons.Default.Check else step.icon,
                contentDescription = null,
                tint = if (state == StepState.PENDING) InsightrColors.TextOnDarkMuted else InsightrColors.TextOnCream,
                modifier = Modifier.size(16.dp)
            )
        }
        Spacer(modifier = Modifier.width(12.dp))
        Text(
            step.label,
            color = if (state == StepState.PENDING) InsightrColors.TextOnDarkMuted else InsightrColors.TextOnDark,
            fontSize = 14.sp,
            fontWeight = if (state == StepState.ACTIVE) FontWeight.SemiBold else FontWeight.Normal
        )
    }
}
