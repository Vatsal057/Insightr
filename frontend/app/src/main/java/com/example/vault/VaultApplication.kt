package com.example.vault

import android.app.Application
import com.example.vault.data.AppContainer

class VaultApplication : Application() {
    lateinit var container: AppContainer
        private set

    override fun onCreate() {
        super.onCreate()
        container = AppContainer(this)
    }
}
