package com.insightr.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.api.ConceptDto
import com.insightr.data.api.CollectionDto
import com.insightr.data.repository.ConceptRepository
import com.insightr.data.repository.CollectionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class VaultUiState(
    val isLoading: Boolean = true,
    val concepts: List<ConceptDto> = emptyList(),
    val collections: List<CollectionDto> = emptyList(),
    val error: String? = null,
    val selectedConceptType: String? = null,
    val totalConcepts: Int = 0,
    val thisWeekCount: Int = 0,
    val linkedNotesCount: Int = 0
)

@HiltViewModel
class VaultViewModel @Inject constructor(
    private val conceptRepository: ConceptRepository,
    private val collectionRepository: CollectionRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(VaultUiState())
    val uiState: StateFlow<VaultUiState> = _uiState.asStateFlow()

    init {
        loadConcepts()
    }

    fun loadConcepts() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            conceptRepository.getConcepts(conceptType = _uiState.value.selectedConceptType)
                .onSuccess { concepts ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        concepts = concepts,
                        totalConcepts = concepts.size
                    )
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load concepts"
                    )
                }
        }
    }

    fun selectConceptType(type: String?) {
        _uiState.value = _uiState.value.copy(selectedConceptType = type)
        loadConcepts()
    }
}
