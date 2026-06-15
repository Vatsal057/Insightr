package com.insightr.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.api.StatusResponse
import com.insightr.data.repository.ProcessingRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ProcessingUiState(
    val isProcessing: Boolean = true,
    val currentStep: Int = 0,
    val progress: Float = 0f,
    val error: String? = null,
    val entryId: Int? = null,
    val taskId: String? = null,
    val url: String = "",
    val steps: List<ProcessingStep> = listOf(
        ProcessingStep("Downloading", "Fetching video source", true),
        ProcessingStep("Transcribing audio", "Speech-to-text model", true),
        ProcessingStep("Extracting frames", "Key visual moments", false),
        ProcessingStep("Running AI analysis", "Semantic understanding", false),
        ProcessingStep("Saving to vault", "Building insight card", false)
    )
)

data class ProcessingStep(
    val title: String,
    val subtitle: String,
    val completed: Boolean = false
)

@HiltViewModel
class ProcessingViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val processingRepository: ProcessingRepository
) : ViewModel() {

    private val url: String = savedStateHandle.get<String>("url") ?: ""

    private val _uiState = MutableStateFlow(ProcessingUiState(url = url))
    val uiState: StateFlow<ProcessingUiState> = _uiState.asStateFlow()

    init {
        startProcessing()
    }

    private fun startProcessing() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isProcessing = true, error = null)
            processingRepository.processUrl(url)
                .onSuccess { response ->
                    _uiState.value = _uiState.value.copy(taskId = response.taskId)
                    pollStatus(response.taskId)
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isProcessing = false,
                        error = e.message ?: "Failed to start processing"
                    )
                }
        }
    }

    private suspend fun pollStatus(taskId: String) {
        while (_uiState.value.isProcessing) {
            delay(2000)
            processingRepository.getStatus(taskId)
                .onSuccess { status ->
                    when (status.status) {
                        "completed" -> {
                            _uiState.value = _uiState.value.copy(
                                isProcessing = false,
                                entryId = status.entryId,
                                progress = 1f,
                                steps = _uiState.value.steps.map { it.copy(completed = true) }
                            )
                            return
                        }
                        "failed" -> {
                            _uiState.value = _uiState.value.copy(
                                isProcessing = false,
                                error = status.error ?: "Processing failed"
                            )
                            return
                        }
                        else -> {
                            updateProgress()
                        }
                    }
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isProcessing = false,
                        error = e.message ?: "Failed to check status"
                    )
                    return
                }
        }
    }

    private fun updateProgress() {
        val current = _uiState.value.currentStep
        if (current < 4) {
            val newSteps = _uiState.value.steps.toMutableList()
            newSteps[current] = newSteps[current].copy(completed = true)
            _uiState.value = _uiState.value.copy(
                currentStep = current + 1,
                progress = (current + 1) / 5f,
                steps = newSteps
            )
        }
    }

    fun retry() {
        startProcessing()
    }
}
