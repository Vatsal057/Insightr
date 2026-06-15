package com.insightr.ui.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.insightr.data.datastore.SettingsDataStore
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class SettingsUiState(
    val backendUrl: String = SettingsDataStore.DEFAULT_BACKEND_URL,
    val apiKey: String = "",
    val vaultStorage: String = "/obsidian/insightr",
    val exportPath: String = "/exports/notes",
    val instagramCookiesActive: Boolean = false,
    val theme: String = "dark"
)

@HiltViewModel
class SettingsViewModel @Inject constructor(
    private val settingsDataStore: SettingsDataStore
) : ViewModel() {

    private val _uiState = MutableStateFlow(SettingsUiState())
    val uiState: StateFlow<SettingsUiState> = _uiState.asStateFlow()

    init {
        loadSettings()
    }

    private fun loadSettings() {
        viewModelScope.launch {
            settingsDataStore.backendUrl.collect { url ->
                _uiState.value = _uiState.value.copy(backendUrl = url)
            }
        }
        viewModelScope.launch {
            settingsDataStore.apiKey.collect { key ->
                _uiState.value = _uiState.value.copy(apiKey = key)
            }
        }
        viewModelScope.launch {
            settingsDataStore.vaultStorage.collect { path ->
                _uiState.value = _uiState.value.copy(vaultStorage = path)
            }
        }
        viewModelScope.launch {
            settingsDataStore.exportPath.collect { path ->
                _uiState.value = _uiState.value.copy(exportPath = path)
            }
        }
        viewModelScope.launch {
            settingsDataStore.instagramCookiesActive.collect { active ->
                _uiState.value = _uiState.value.copy(instagramCookiesActive = active)
            }
        }
        viewModelScope.launch {
            settingsDataStore.theme.collect { theme ->
                _uiState.value = _uiState.value.copy(theme = theme)
            }
        }
    }

    fun setBackendUrl(url: String) {
        viewModelScope.launch {
            settingsDataStore.setBackendUrl(url)
            _uiState.value = _uiState.value.copy(backendUrl = url)
        }
    }
}
