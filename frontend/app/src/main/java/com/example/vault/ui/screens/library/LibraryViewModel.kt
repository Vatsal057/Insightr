package com.example.vault.ui.screens.library

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vault.data.api.SummaryCard
import com.example.vault.data.repository.VaultRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

data class LibraryUiState(
    val allEntries: List<SummaryCard> = emptyList(),
    val favorites: List<SummaryCard>  = emptyList(),
    val isLoading: Boolean            = true,
    val error: String?                = null,
    val favoriteIds: Set<Int>         = emptySet(),
)

class LibraryViewModel(private val repository: VaultRepository) : ViewModel() {

    private val _state = MutableStateFlow(LibraryUiState())
    val state: StateFlow<LibraryUiState> = _state

    init { loadLibrary() }

    fun loadLibrary() {
        viewModelScope.launch {
            _state.update { it.copy(isLoading = true) }
            repository.getFeed(limit = 200).fold(
                onSuccess = { cards ->
                    val favIds = _state.value.favoriteIds
                    _state.update { s ->
                        s.copy(
                            allEntries = cards,
                            favorites  = cards.filter { it.id in favIds },
                            isLoading  = false,
                        )
                    }
                },
                onFailure = {
                    _state.update { s -> s.copy(error = it.message, isLoading = false) }
                },
            )
        }
    }

    fun toggleFavorite(id: Int) {
        _state.update { s ->
            val newFavs = if (id in s.favoriteIds) s.favoriteIds - id else s.favoriteIds + id
            s.copy(
                favoriteIds = newFavs,
                favorites   = s.allEntries.filter { it.id in newFavs },
            )
        }
    }

    companion object {
        fun factory(repository: VaultRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                LibraryViewModel(repository) as T
        }
    }
}
