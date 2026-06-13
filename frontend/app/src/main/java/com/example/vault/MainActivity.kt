package com.example.vault

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import com.example.vault.theme.VaultTheme

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        val container = (application as VaultApplication).container
        setContent {
            VaultTheme {
                MainNavigation(container = container)
            }
        }
    }

    override fun onResume() {
        super.onResume()
        (application as VaultApplication).container.serverUrlManager.startDiscovery()
    }

    override fun onPause() {
        super.onPause()
        (application as VaultApplication).container.serverUrlManager.stopDiscovery()
    }
}
