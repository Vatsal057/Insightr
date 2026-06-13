package com.example.vault.ui.screens.capture

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vault.data.local.ProcessingHistoryDao
import com.example.vault.data.local.ProcessingHistoryEntity
import com.example.vault.data.repository.VaultRepository
import com.example.vault.ui.components.ProcessingStep
import com.example.vault.ui.components.StepState
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

sealed class CaptureUiState {
    object Idle          : CaptureUiState()
    data class Processing(val steps: List<ProcessingStep>, val url: String) : CaptureUiState()
    data class Done(val entryId: Int) : CaptureUiState()
    data class Failed(val message: String) : CaptureUiState()
}

private val PIPELINE_LABELS = listOf(
    "Downloading content",
    "Transcribing audio",
    "Extracting frames + OCR",
    "Running AI analysis",
    "Building knowledge card",
)

class CaptureViewModel(
    private val repository: VaultRepository,
    private val historyDao: ProcessingHistoryDao,
) : ViewModel() {

    private val _uiState = MutableStateFlow<CaptureUiState>(CaptureUiState.Idle)
    val uiState: StateFlow<CaptureUiState> = _uiState

    val history = historyDao.getAll()
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), emptyList())

    fun submit(url: String) {
        if (url.isBlank()) return
        viewModelScope.launch {
            _uiState.value = CaptureUiState.Processing(buildSteps(0), url)

            val result = repository.processUrl(url)
            result.onFailure { e ->
                _uiState.value = CaptureUiState.Failed(e.message ?: "Server unreachable")
                return@launch
            }

            val taskId = result.getOrThrow().taskId
            historyDao.upsert(ProcessingHistoryEntity(taskId, url, "processing", null, null))

            var stepIdx = 0
            val finalStatus = repository.pollStatus(taskId) { status ->
                stepIdx = when (status.status) {
                    "processing" -> minOf(stepIdx + 1, PIPELINE_LABELS.lastIndex)
                    "completed"  -> PIPELINE_LABELS.lastIndex
                    else         -> stepIdx
                }
                _uiState.value = CaptureUiState.Processing(buildSteps(stepIdx), url)
            }

            historyDao.updateStatus(taskId, finalStatus.status, finalStatus.entryId, finalStatus.error)

            if (finalStatus.status == "completed" && finalStatus.entryId != null) {
                _uiState.value = CaptureUiState.Done(finalStatus.entryId)
            } else {
                _uiState.value = CaptureUiState.Failed(
                    finalStatus.error ?: "Processing failed. Check the server logs."
                )
            }
        }
    }

    fun reset() { _uiState.value = CaptureUiState.Idle }

    private fun buildSteps(activeIndex: Int): List<ProcessingStep> =
        PIPELINE_LABELS.mapIndexed { idx, label ->
            ProcessingStep(
                label = label,
                state = when {
                    idx < activeIndex  -> StepState.Done
                    idx == activeIndex -> StepState.Active
                    else               -> StepState.Waiting
                },
            )
        }

    companion object {
        fun factory(repository: VaultRepository, dao: ProcessingHistoryDao) =
            object : ViewModelProvider.Factory {
                @Suppress("UNCHECKED_CAST")
                override fun <T : ViewModel> create(modelClass: Class<T>): T =
                    CaptureViewModel(repository, dao) as T
            }
    }
}
