package com.insightr.data.datastore

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import dagger.hilt.android.qualifiers.ApplicationContext
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map
import javax.inject.Inject
import javax.inject.Singleton

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "insightr_settings")

@Singleton
class SettingsDataStore @Inject constructor(
    @ApplicationContext private val context: Context
) {
    private object Keys {
        val BACKEND_URL = stringPreferencesKey("backend_url")
        val ONBOARDING_COMPLETED = booleanPreferencesKey("onboarding_completed")
        val API_KEY = stringPreferencesKey("api_key")
        val VAULT_STORAGE = stringPreferencesKey("vault_storage")
        val EXPORT_PATH = stringPreferencesKey("export_path")
        val INSTAGRAM_COOKIES_ACTIVE = booleanPreferencesKey("instagram_cookies_active")
        val THEME = stringPreferencesKey("theme")
    }

    val backendUrl: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.BACKEND_URL] ?: DEFAULT_BACKEND_URL
    }

    val onboardingCompleted: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.ONBOARDING_COMPLETED] ?: false
    }

    val apiKey: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.API_KEY] ?: ""
    }

    val vaultStorage: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.VAULT_STORAGE] ?: "/obsidian/insightr"
    }

    val exportPath: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.EXPORT_PATH] ?: "/exports/notes"
    }

    val instagramCookiesActive: Flow<Boolean> = context.dataStore.data.map { prefs ->
        prefs[Keys.INSTAGRAM_COOKIES_ACTIVE] ?: false
    }

    val theme: Flow<String> = context.dataStore.data.map { prefs ->
        prefs[Keys.THEME] ?: "dark"
    }

    suspend fun setBackendUrl(url: String) {
        context.dataStore.edit { prefs ->
            prefs[Keys.BACKEND_URL] = url
        }
    }

    suspend fun setOnboardingCompleted(completed: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[Keys.ONBOARDING_COMPLETED] = completed
        }
    }

    suspend fun setApiKey(key: String) {
        context.dataStore.edit { prefs ->
            prefs[Keys.API_KEY] = key
        }
    }

    suspend fun setVaultStorage(path: String) {
        context.dataStore.edit { prefs ->
            prefs[Keys.VAULT_STORAGE] = path
        }
    }

    suspend fun setExportPath(path: String) {
        context.dataStore.edit { prefs ->
            prefs[Keys.EXPORT_PATH] = path
        }
    }

    suspend fun setInstagramCookiesActive(active: Boolean) {
        context.dataStore.edit { prefs ->
            prefs[Keys.INSTAGRAM_COOKIES_ACTIVE] = active
        }
    }

    suspend fun setTheme(theme: String) {
        context.dataStore.edit { prefs ->
            prefs[Keys.THEME] = theme
        }
    }

    companion object {
        const val DEFAULT_BACKEND_URL = "http://10.0.2.2:8000"
    }
}
