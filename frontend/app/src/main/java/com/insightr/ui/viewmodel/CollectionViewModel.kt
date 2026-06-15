package com.insightr.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.api.CollectionDto
import com.insightr.data.api.FeedItem
import com.insightr.data.repository.CollectionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class CollectionsUiState(
    val isLoading: Boolean = true,
    val collections: List<CollectionDto> = emptyList(),
    val error: String? = null
)

@HiltViewModel
class CollectionsViewModel @Inject constructor(
    private val collectionRepository: CollectionRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(CollectionsUiState())
    val uiState: StateFlow<CollectionsUiState> = _uiState.asStateFlow()

    init {
        loadCollections()
    }

    fun loadCollections() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            collectionRepository.getCollections()
                .onSuccess { collections ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        collections = collections
                    )
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load collections"
                    )
                }
        }
    }
}

data class CollectionDetailUiState(
    val isLoading: Boolean = true,
    val entries: List<FeedItem> = emptyList(),
    val collectionName: String = "",
    val error: String? = null
)

@HiltViewModel
class CollectionDetailViewModel @Inject constructor(
    savedStateHandle: androidx.lifecycle.SavedStateHandle,
    private val collectionRepository: CollectionRepository
) : ViewModel() {

    private val collectionName: String = savedStateHandle.get<String>("name") ?: ""

    private val _uiState = MutableStateFlow(CollectionDetailUiState(collectionName = collectionName))
    val uiState: StateFlow<CollectionDetailUiState> = _uiState.asStateFlow()

    init {
        loadCollection()
    }

    fun loadCollection() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            collectionRepository.getCollection(collectionName)
                .onSuccess { entries ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        entries = entries
                    )
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load collection"
                    )
                }
        }
    }
}
