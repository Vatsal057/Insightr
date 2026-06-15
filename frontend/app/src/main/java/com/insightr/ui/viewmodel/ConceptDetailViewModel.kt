package com.insightr.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.api.ConceptDto
import com.insightr.data.api.FeedItem
import com.insightr.data.repository.ConceptRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ConceptDetailUiState(
    val isLoading: Boolean = true,
    val concept: ConceptDto? = null,
    val entries: List<FeedItem> = emptyList(),
    val error: String? = null
)

@HiltViewModel
class ConceptDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val conceptRepository: ConceptRepository
) : ViewModel() {

    private val conceptId: Int = savedStateHandle.get<Int>("conceptId") ?: 0

    private val _uiState = MutableStateFlow(ConceptDetailUiState())
    val uiState: StateFlow<ConceptDetailUiState> = _uiState.asStateFlow()

    init {
        loadConcept()
    }

    private fun loadConcept() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            conceptRepository.getConcepts()
                .onSuccess { concepts ->
                    val concept = concepts.find { it.id == conceptId }
                    conceptRepository.getConceptEntries(conceptId)
                        .onSuccess { entries ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                concept = concept,
                                entries = entries
                            )
                        }
                        .onFailure { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                concept = concept,
                                error = e.message ?: "Failed to load entries"
                            )
                        }
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load concept"
                    )
                }
        }
    }
}
