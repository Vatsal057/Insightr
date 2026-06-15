package com.insightr.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.api.ActionItemDto
import com.insightr.data.repository.TodoRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class ActionsUiState(
    val isLoading: Boolean = true,
    val pendingTodos: List<ActionItemDto> = emptyList(),
    val completedTodos: List<ActionItemDto> = emptyList(),
    val error: String? = null,
    val selectedFilter: String? = null,
    val showCompleted: Boolean = false
)

@HiltViewModel
class ActionsViewModel @Inject constructor(
    private val todoRepository: TodoRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(ActionsUiState())
    val uiState: StateFlow<ActionsUiState> = _uiState.asStateFlow()

    init {
        loadTodos()
    }

    fun loadTodos() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            todoRepository.getTodos(done = false)
                .onSuccess { pending ->
                    todoRepository.getTodos(done = true)
                        .onSuccess { completed ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                pendingTodos = pending.sortedBy { todo ->
                                    when (todo.priority) {
                                        "now" -> 0
                                        "soon" -> 1
                                        else -> 2
                                    }
                                },
                                completedTodos = completed
                            )
                        }
                        .onFailure { e ->
                            _uiState.value = _uiState.value.copy(
                                isLoading = false,
                                error = e.message ?: "Failed to load todos"
                            )
                        }
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        isLoading = false,
                        error = e.message ?: "Failed to load todos"
                    )
                }
        }
    }

    fun toggleTodo(itemId: Int, done: Boolean) {
        viewModelScope.launch {
            todoRepository.checkTodo(itemId, done)
                .onSuccess {
                    loadTodos()
                }
                .onFailure { e ->
                    _uiState.value = _uiState.value.copy(
                        error = e.message ?: "Failed to update todo"
                    )
                }
        }
    }

    fun selectFilter(filter: String?) {
        _uiState.value = _uiState.value.copy(selectedFilter = filter)
    }

    fun toggleShowCompleted() {
        _uiState.value = _uiState.value.copy(
            showCompleted = !_uiState.value.showCompleted
        )
    }
}
