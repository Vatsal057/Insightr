package com.insightr.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.api.FeedItem
import com.insightr.data.repository.EntryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ExportUiState(
    val isLoading: Boolean = true,
    val markdown: String = "",
    val entryTitle: String = "",
    val error: String? = null,
    val isSingleNote: Boolean = true
)

@HiltViewModel
class ExportViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val entryRepository: EntryRepository
) : ViewModel() {

    private val entryId: Int = savedStateHandle.get<Int>("entryId") ?: 0

    private val _uiState = MutableStateFlow(ExportUiState())
    val uiState: StateFlow<ExportUiState> = _uiState.asStateFlow()

    init {
        loadExport()
    }

    fun loadExport() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            entryRepository.exportEntry(entryId)
                .onSuccess { markdown ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        markdown = markdown
                    )
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load export"
                    )
                }
        }
    }
}
