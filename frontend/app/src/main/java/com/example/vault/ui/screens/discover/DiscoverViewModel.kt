package com.example.vault.ui.screens.discover

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.example.vault.data.api.SummaryCard
import com.example.vault.data.repository.VaultRepository
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import java.time.LocalDateTime
import java.time.temporal.ChronoUnit

sealed class DiscoverUiState {
    object Loading : DiscoverUiState()
    data class Success(
        val cards: List<SummaryCard>,
        val dailyPick: SummaryCard?,
        val dailyPickDaysAgo: Long,
    ) : DiscoverUiState()
    data class Error(val message: String) : DiscoverUiState()
}

class DiscoverViewModel(private val repository: VaultRepository) : ViewModel() {

    private val _uiState = MutableStateFlow<DiscoverUiState>(DiscoverUiState.Loading)
    val uiState: StateFlow<DiscoverUiState> = _uiState

    init { loadFeed() }

    fun loadFeed() {
        viewModelScope.launch {
            _uiState.value = DiscoverUiState.Loading
            repository.getFeed().fold(
                onSuccess = { cards ->
                    val daily   = pickDailyCard(cards)
                    val daysAgo = daily?.let { computeDaysAgo(it.createdAt) } ?: 0L
                    _uiState.value = DiscoverUiState.Success(cards, daily, daysAgo)
                },
                onFailure = {
                    _uiState.value = DiscoverUiState.Error(
                        it.message ?: "Unable to reach Vault server. Is it running?"
                    )
                },
            )
        }
    }

    private fun pickDailyCard(cards: List<SummaryCard>): SummaryCard? {
        val old = cards.filter { computeDaysAgo(it.createdAt) >= 7 }
        if (old.isEmpty()) return cards.lastOrNull()
        return old[LocalDateTime.now().dayOfYear % old.size]
    }

    private fun computeDaysAgo(iso: String): Long = try {
        val date = LocalDateTime.parse(iso.take(19))
        ChronoUnit.DAYS.between(date.toLocalDate(), LocalDateTime.now().toLocalDate())
    } catch (e: Exception) { 0L }

    companion object {
        fun factory(repository: VaultRepository) = object : ViewModelProvider.Factory {
            @Suppress("UNCHECKED_CAST")
            override fun <T : ViewModel> create(modelClass: Class<T>): T =
                DiscoverViewModel(repository) as T
        }
    }
}
