package com.example.vault

import androidx.activity.compose.BackHandler
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import com.example.vault.data.AppContainer
import com.example.vault.ui.components.*
import com.example.vault.ui.screens.capture.CaptureScreen
import com.example.vault.ui.screens.detail.EntryDetailScreen
import com.example.vault.ui.screens.discover.DiscoverScreen
import com.example.vault.ui.screens.explore.ExploreScreen
import com.example.vault.ui.screens.library.LibraryScreen
import com.example.vault.ui.screens.profile.ProfileScreen
import com.example.vault.theme.VaultBackground

@Composable
fun MainNavigation(container: AppContainer) {
    var currentRoute  by remember { mutableStateOf("discover") }
    var entryDetailId by remember { mutableStateOf<Int?>(null) }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(VaultBackground),
    ) {
        when {
            entryDetailId != null -> {
                BackHandler { entryDetailId = null }
                EntryDetailScreen(
                    entryId            = entryDetailId!!,
                    repository         = container.repository,
                    onBack             = { entryDetailId = null },
                    onConceptClick     = { /* concept detail future */ },
                    onRelatedEntryClick = { id -> entryDetailId = id },
                    modifier           = Modifier.fillMaxSize(),
                )
            }

            else -> {
                if (currentRoute != "discover") {
                    BackHandler { currentRoute = "discover" }
                }
                when (currentRoute) {
                    "discover" -> DiscoverScreen(
                        repository   = container.repository,
                        onEntryClick = { entryDetailId = it },
                        modifier     = Modifier.fillMaxSize(),
                    )
                    "explore" -> ExploreScreen(
                        repository     = container.repository,
                        onEntryClick   = { entryDetailId = it },
                        onConceptClick = { /* future */ },
                        modifier       = Modifier.fillMaxSize(),
                    )
                    "capture" -> CaptureScreen(
                        repository   = container.repository,
                        historyDao   = container.processingHistoryDao,
                        onEntryReady = { id -> entryDetailId = id },
                        modifier     = Modifier.fillMaxSize(),
                    )
                    "library" -> LibraryScreen(
                        repository   = container.repository,
                        onEntryClick = { entryDetailId = it },
                        modifier     = Modifier.fillMaxSize(),
                    )
                    "profile" -> ProfileScreen(
                        serverUrlManager = container.serverUrlManager,
                        modifier         = Modifier.fillMaxSize(),
                    )
                }

                // Floating bottom nav — only when not in detail
                BottomNavBar(
                    currentRoute = currentRoute,
                    onNavigate   = { dest -> currentRoute = dest.route },
                    modifier     = Modifier.align(Alignment.BottomCenter),
                )
            }
        }
    }
}
