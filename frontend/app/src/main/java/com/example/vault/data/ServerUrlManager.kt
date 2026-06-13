package com.example.vault.data

import android.content.Context
import android.content.SharedPreferences
import androidx.core.content.edit
import com.example.vault.BuildConfig

/**
 * Manages the server base URL at runtime.
 * Default: BuildConfig.API_BASE_URL (10.0.2.2:8000 for emulator).
 * Override via Developer Settings screen.
 */
class ServerUrlManager(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("vault_settings", Context.MODE_PRIVATE)

    var baseUrl: String
        get() = prefs.getString(KEY_SERVER_URL, BuildConfig.API_BASE_URL)
            ?: BuildConfig.API_BASE_URL
        set(value) = prefs.edit { putString(KEY_SERVER_URL, value) }

    companion object {
        private const val KEY_SERVER_URL = "server_base_url"
    }
}
