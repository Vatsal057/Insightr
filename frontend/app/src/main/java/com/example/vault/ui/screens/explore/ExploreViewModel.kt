package com.example.vault.ui.screens.explore

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vault.data.api.Concept
import com.example.vault.data.api.SearchResult
import com.example.vault.data.repository.VaultRepository
import kotlinx.coroutines.FlowPreview
import kotlinx.coroutines.flow.*
import kotlinx.coroutines.launch

data class ExploreUiState(
    val concepts: List<Concept>           = emptyList(),
    val searchResults: List<SearchResult> = emptyList(),
    val isLoadingConcepts: Boolean        = true,
    val isSearching: Boolean              = false,
    val query: String                     = "",
    val selectedType: String?             = null,
    val graphMode: Boolean                = false,
    val selectedConcept: Concept?         = null,
    val error: String?                    = null,
)

@OptIn(FlowPreview::class)
class ExploreViewModel(private val repository: VaultRepository) : ViewModel() {

    private val _state = MutableStateFlow(ExploreUiState())
    val state: StateFlow<ExploreUiState> = _state

    private val _queryFlow = MutableStateFlow("")

    init {
        loadConcepts()
        _queryFlow
            .debounce(400)
            .onEach { q -> if (q.isNotBlank()) doSearch(q) else clearSearch() }
            .launchIn(viewModelScope)
    }

    fun loadConcepts(type: String? = null) {
        viewModelScope.launch {
            _state.update { it.copy(isLoadingConcepts = true, selectedType = type) }
            repository.getConcepts(conceptType = type).fold(
                onSuccess = { _state.update { s -> s.copy(concepts = it, isLoadingConcepts = false) } },
                onFailure = { _state.update { s -> s.copy(error = it.message, isLoadingConcepts = false) } },
            )
        }
    }

    fun onQueryChange(q: String) {
        _state.update { it.copy(query = q) }
        _queryFlow.value = q
    }

    fun toggleGraphMode() = _state.update { it.copy(graphMode = !it.graphMode) }

    fun onConceptSelect(concept: Concept) = _state.update { it.copy(selectedConcept = concept) }

    private suspend fun doSearch(q: String) {
        _state.update { it.copy(isSearching = true) }
        repository.search(query = q).fold(
            onSuccess = { _state.update { s -> s.copy(searchResults = it, isSearching = false) } },
            onFailure = { _state.update { s -> s.copy(error = it.message, isSearching = false) } },
        )
    }

    private fun clearSearch() = _state.update { it.copy(searchResults = emptyList()) }

    companion object {
        fun factory(repository: VaultRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                ExploreViewModel(repository) as T
        }
    }
}
