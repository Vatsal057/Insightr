package com.example.vault.ui.screens.detail

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vault.data.api.InsightCard
import com.example.vault.data.repository.VaultRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

sealed class DetailUiState {
    object Loading : DetailUiState()
    data class Success(val card: InsightCard) : DetailUiState()
    data class Error(val message: String) : DetailUiState()
}

class EntryDetailViewModel(private val repository: VaultRepository) : ViewModel() {

    private val _uiState = MutableStateFlow<DetailUiState>(DetailUiState.Loading)
    val uiState: StateFlow<DetailUiState> = _uiState

    private val _doneItems = MutableStateFlow<Set<Int>>(emptySet())
    val doneItems: StateFlow<Set<Int>> = _doneItems

    fun loadEntry(id: Int) {
        viewModelScope.launch {
            _uiState.value = DetailUiState.Loading
            repository.getEntry(id).fold(
                onSuccess = { _uiState.value = DetailUiState.Success(it) },
                onFailure = { _uiState.value = DetailUiState.Error(it.message ?: "Failed to load") },
            )
        }
    }

    fun toggleActionItem(index: Int) {
        _doneItems.value = if (index in _doneItems.value) _doneItems.value - index
                           else _doneItems.value + index
    }

    companion object {
        fun factory(repository: VaultRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                EntryDetailViewModel(repository) as T
        }
    }
}
