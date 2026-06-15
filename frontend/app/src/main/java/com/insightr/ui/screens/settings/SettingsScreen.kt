package com.insightr.ui.screens.settings

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.KeyboardArrowRight
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.viewmodel.SettingsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onBackClick: () -> Unit,
    viewModel: SettingsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(16.dp)
    ) {
        // Header
        Row(
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBackClick) {
                Icon(
                    imageVector = Icons.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = InsightrColors.TextPrimary
                )
            }
            Text(
                text = "Settings",
                style = MaterialTheme.typography.displayMedium,
                color = InsightrColors.TextPrimary
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        Column(
            modifier = Modifier.verticalScroll(rememberScrollState())
        ) {
            // INTEGRATIONS section
            SectionHeader(title = "INTEGRATIONS")

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Card
                )
            ) {
                Column {
                    SettingsItem(
                        icon = "\uD83D\uDD11",
                        title = "API Key",
                        value = "sk-\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u20223f9a",
                        onClick = { }
                    )
                    HorizontalDivider(color = InsightrColors.Border)
                    SettingsItem(
                        icon = "\uD83D\uDCBE",
                        title = "Vault Storage",
                        value = uiState.vaultStorage,
                        onClick = { }
                    )
                    HorizontalDivider(color = InsightrColors.Border)
                    SettingsItem(
                        icon = "\uD83D\uDCC2",
                        title = "Export Path",
                        value = uiState.exportPath,
                        onClick = { }
                    )
                    HorizontalDivider(color = InsightrColors.Border)
                    SettingsItem(
                        icon = "\uD83D\uDC27",
                        title = "Instagram Cookies",
                        value = if (uiState.instagramCookiesActive) "Active" else "Inactive",
                        onClick = { }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // APPEARANCE section
            SectionHeader(title = "APPEARANCE")

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Card
                )
            ) {
                SettingsItem(
                    icon = "\uD83C\uDF19",
                    title = "Theme",
                    value = "Dark \u2014 Locked",
                    trailingIcon = {
                        Icon(
                            imageVector = Icons.Filled.KeyboardArrowRight,
                            contentDescription = null,
                            tint = InsightrColors.TextSecondary
                        )
                    },
                    onClick = { }
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // ABOUT section
            SectionHeader(title = "ABOUT")

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Card
                )
            ) {
                Column {
                    SettingsItem(
                        icon = "",
                        title = "Version",
                        value = "1.2.0 (build 48)",
                        onClick = { }
                    )
                    HorizontalDivider(color = InsightrColors.Border)
                    SettingsItem(
                        icon = "\uD83D\uDCBB",
                        title = "Backend URL",
                        value = uiState.backendUrl,
                        onClick = { }
                    )
                    HorizontalDivider(color = InsightrColors.Border)
                    SettingsItem(
                        icon = "\uD83D\uDD12",
                        title = "Privacy Policy",
                        value = "",
                        trailingIcon = {
                            Icon(
                                imageVector = Icons.Filled.KeyboardArrowRight,
                                contentDescription = null,
                                tint = InsightrColors.TextSecondary
                            )
                        },
                        onClick = { }
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // DANGER ZONE
            SectionHeader(title = "DANGER ZONE")

            Card(
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Card
                )
            ) {
                SettingsItem(
                    icon = "\uD83D\uDDD1\uFE0F",
                    title = "Clear Vault",
                    value = "Permanently deletes all stored notes",
                    titleColor = InsightrColors.Danger,
                    onClick = { }
                )
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        text = title,
        style = MaterialTheme.typography.labelMedium,
        color = InsightrColors.TextSecondary,
        modifier = Modifier.padding(bottom = 8.dp)
    )
}

@Composable
private fun SettingsItem(
    icon: String,
    title: String,
    value: String,
    titleColor: androidx.compose.ui.graphics.Color = InsightrColors.TextPrimary,
    trailingIcon: @Composable (() -> Unit)? = null,
    onClick: () -> Unit
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon.isNotBlank()) {
            Text(text = icon, style = MaterialTheme.typography.bodyLarge)
            Spacer(modifier = Modifier.width(12.dp))
        }

        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = titleColor,
                fontWeight = FontWeight.Medium
            )
            if (value.isNotBlank()) {
                Text(
                    text = value,
                    style = MaterialTheme.typography.bodySmall,
                    color = InsightrColors.TextSecondary
                )
            }
        }

        trailingIcon?.invoke()
    }
}
