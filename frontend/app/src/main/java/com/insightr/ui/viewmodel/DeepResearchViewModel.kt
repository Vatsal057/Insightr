package com.insightr.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.api.DeepResearchPromptResponse
import com.insightr.data.repository.EntryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class DeepResearchUiState(
    val isLoading: Boolean = true,
    val prompt: DeepResearchPromptResponse? = null,
    val error: String? = null
)

@HiltViewModel
class DeepResearchViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val entryRepository: EntryRepository
) : ViewModel() {

    private val entryId: Int = savedStateHandle.get<Int>("entryId") ?: 0

    private val _uiState = MutableStateFlow(DeepResearchUiState())
    val uiState: StateFlow<DeepResearchUiState> = _uiState.asStateFlow()

    init {
        loadPrompt()
    }

    fun loadPrompt() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            entryRepository.getDeepResearchPrompt(entryId)
                .onSuccess { prompt ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        prompt = prompt
                    )
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load deep research prompt"
                    )
                }
        }
    }
}
