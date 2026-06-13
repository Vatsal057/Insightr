package com.example.vault.ui.screens.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalSoftwareKeyboardController
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.vault.BuildConfig
import com.example.vault.data.ServerUrlManager
import com.example.vault.ui.components.*
import com.example.vault.theme.*

/**
 * Profile screen with hidden Developer Settings panel.
 * Tap "Developer Settings" 3 times quickly to reveal it.
 * This avoids cluttering the main UI for regular users.
 */
@Composable
fun ProfileScreen(
    serverUrlManager: ServerUrlManager,
    modifier: Modifier = Modifier,
) {
    var devTapCount by remember { mutableIntStateOf(0) }
    var showDevSettings by remember { mutableStateOf(false) }
    var serverUrl by remember { mutableStateOf(serverUrlManager.baseUrl) }
    var urlSaved by remember { mutableStateOf(false) }
    val keyboard = LocalSoftwareKeyboardController.current

    Box(
        modifier = modifier
            .fillMaxSize()
            .background(VaultBackground),
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(24.dp)
                .padding(top = 40.dp),
            verticalArrangement = Arrangement.spacedBy(20.dp),
        ) {
            // ─── Header ──────────────────────────────────────────────────
            Column(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(
                        Brush.verticalGradient(listOf(VaultAccentDim, VaultBackground)),
                    )
                    .padding(vertical = 24.dp),
            ) {
                Text(
                    "Profile",
                    color = VaultTextPrimary,
                    fontSize = 32.sp,
                    fontWeight = FontWeight.Bold,
                )
            }

            // ─── App Info card ────────────────────────────────────────────
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                shape = LargeCorner,
                elevation = GlassElevation.Level2,
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp),
                ) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        Box(
                            modifier = Modifier
                                .size(56.dp)
                                .background(VaultAccentMuted, LargeCorner),
                            contentAlignment = Alignment.Center,
                        ) {
                            Text("◈", color = VaultAccent, fontSize = 28.sp)
                        }
                        Column {
                            Text(
                                "Vault",
                                color = VaultTextPrimary,
                                fontSize = 22.sp,
                                fontWeight = FontWeight.Bold,
                            )
                            Text(
                                "AI Knowledge Workspace",
                                color = VaultTextSecondary,
                                fontSize = 13.sp,
                            )
                        }
                    }

                    HorizontalDivider(color = VaultDivider)

                    Text(
                        "Version 1.0",
                        color = VaultTextTertiary,
                        fontSize = 12.sp,
                    )
                    Text(
                        "Built on Gemini • FastAPI • Whisper",
                        color = VaultTextTertiary,
                        fontSize = 12.sp,
                    )
                }
            }

            // ─── Server Status card ───────────────────────────────────────
            GlassCard(
                modifier = Modifier.fillMaxWidth(),
                shape = LargeCorner,
                elevation = GlassElevation.Level1,
            ) {
                Column(
                    modifier = Modifier.padding(20.dp),
                    verticalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Text(
                        "Server",
                        color = VaultTextTertiary,
                        fontSize = 11.sp,
                        fontWeight = FontWeight.SemiBold,
                        letterSpacing = 0.8f.sp,
                    )
                    Text(
                        text = serverUrlManager.baseUrl,
                        color = VaultTextPrimary,
                        fontSize = 13.sp,
                    )
                }
            }

            // ─── Developer Settings hidden trigger ────────────────────────
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable {
                        devTapCount++
                        if (devTapCount >= 3) {
                            showDevSettings = true
                        }
                    }
                    .padding(vertical = 12.dp),
                contentAlignment = Alignment.Center,
            ) {
                Text(
                    text = if (showDevSettings) "Developer Settings ▼" else "Developer Settings",
                    color = VaultTextTertiary,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                )
            }

            // ─── Developer Settings panel ─────────────────────────────────
            if (showDevSettings) {
                GlassCard(
                    modifier = Modifier.fillMaxWidth(),
                    shape = LargeCorner,
                    elevation = GlassElevation.Level3,
                ) {
                    Column(
                        modifier = Modifier.padding(20.dp),
                        verticalArrangement = Arrangement.spacedBy(14.dp),
                    ) {
                        Text(
                            "Developer Settings",
                            color = VaultAccent,
                            fontSize = 14.sp,
                            fontWeight = FontWeight.SemiBold,
                        )

                        Text(
                            "Emulator: http://10.0.2.2:8000\nPhysical device: http://192.168.x.x:8000",
                            color = VaultTextTertiary,
                            fontSize = 11.sp,
                            lineHeight = 18.sp,
                        )

                        OutlinedTextField(
                            value = serverUrl,
                            onValueChange = { serverUrl = it; urlSaved = false },
                            label = { Text("API Base URL", color = VaultTextTertiary) },
                            colors = OutlinedTextFieldDefaults.colors(
                                unfocusedBorderColor = VaultBorderStrong,
                                focusedBorderColor   = VaultAccent,
                                unfocusedTextColor   = VaultTextPrimary,
                                focusedTextColor     = VaultTextPrimary,
                                cursorColor          = VaultAccent,
                                unfocusedLabelColor  = VaultTextTertiary,
                                focusedLabelColor    = VaultAccent,
                            ),
                            keyboardOptions = KeyboardOptions(
                                keyboardType = KeyboardType.Uri,
                                imeAction    = ImeAction.Done,
                            ),
                            keyboardActions = KeyboardActions(onDone = {
                                serverUrlManager.baseUrl = serverUrl.trimEnd('/')
                                urlSaved = true
                                keyboard?.hide()
                            }),
                            modifier = Modifier.fillMaxWidth(),
                            singleLine = true,
                        )

                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Box(
                                modifier = Modifier
                                    .background(VaultAccent, MediumCorner)
                                    .clickable {
                                        serverUrlManager.baseUrl = serverUrl.trimEnd('/')
                                        urlSaved = true
                                        keyboard?.hide()
                                    }
                                    .padding(horizontal = 20.dp, vertical = 10.dp),
                            ) {
                                Text(
                                    "Save URL",
                                    color = VaultBackground,
                                    fontSize = 13.sp,
                                    fontWeight = FontWeight.SemiBold,
                                )
                            }

                            if (urlSaved) {
                                Text(
                                    "✓ Saved (restart app to apply)",
                                    color = VaultFact,
                                    fontSize = 11.sp,
                                )
                            }
                        }

                        // Reset to default
                        Text(
                            text = "Reset to default (${BuildConfig.API_BASE_URL})",
                            color = VaultTextTertiary,
                            fontSize = 11.sp,
                            modifier = Modifier.clickable {
                                serverUrl = BuildConfig.API_BASE_URL
                                serverUrlManager.baseUrl = BuildConfig.API_BASE_URL
                                urlSaved = true
                            },
                        )
                    }
                }
            }
        }
    }
}
