package com.insightr.ui.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.api.EntryResponse
import com.insightr.data.repository.EntryRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class EntryDetailUiState(
    val isLoading: Boolean = true,
    val entry: EntryResponse? = null,
    val error: String? = null,
    val isZone3Expanded: Boolean = false
)

@HiltViewModel
class EntryDetailViewModel @Inject constructor(
    savedStateHandle: SavedStateHandle,
    private val entryRepository: EntryRepository
) : ViewModel() {

    private val entryId: Int = savedStateHandle.get<Int>("entryId") ?: 0

    private val _uiState = MutableStateFlow(EntryDetailUiState())
    val uiState: StateFlow<EntryDetailUiState> = _uiState.asStateFlow()

    init {
        loadEntry()
    }

    fun loadEntry() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            entryRepository.getEntry(entryId)
                .onSuccess { entry ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        entry = entry
                    )
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load entry"
                    )
                }
        }
    }

    fun toggleZone3() {
        _uiState.value = _uiState.value.copy(
            isZone3Expanded = !_uiState.value.isZone3Expanded
        )
    }
}
