package com.insightr.ui.screens.export

import android.content.ClipData
import android.content.ClipboardManager
import android.content.Context
import android.widget.Toast
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.components.common.EmptyState
import com.insightr.ui.theme.InsightrColors
import com.insightr.ui.viewmodel.ExportViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun ExportScreen(
    onBackClick: () -> Unit,
    viewModel: ExportViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current

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
                text = "Export",
                style = MaterialTheme.typography.displayMedium,
                color = InsightrColors.TextPrimary
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        // Tab selector
        Row(
            modifier = Modifier.fillMaxWidth()
        ) {
            CategoryPill(
                label = "Single Note",
                isSelected = uiState.isSingleNote,
                onClick = { }
            )
            Spacer(modifier = Modifier.width(8.dp))
            CategoryPill(
                label = "Full Collection",
                isSelected = !uiState.isSingleNote,
                onClick = { }
            )
        }

        Spacer(modifier = Modifier.height(16.dp))

        when {
            uiState.isLoading -> {
                CircularProgressIndicator(
                    color = InsightrColors.Accent,
                    modifier = Modifier.align(Alignment.CenterHorizontally)
                )
            }
            uiState.error != null -> {
                EmptyState(
                    icon = Icons.Filled.ArrowBack,
                    title = "Error",
                    subtitle = uiState.error ?: "Unknown error"
                )
            }
            else -> {
                // Preview card
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.Card
                    )
                ) {
                    Column(
                        modifier = Modifier.padding(16.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = androidx.compose.foundation.layout.Arrangement.SpaceBetween
                        ) {
                            Text(
                                text = "PREVIEW",
                                style = MaterialTheme.typography.labelMedium,
                                color = InsightrColors.TextSecondary
                            )
                            Text(
                                text = "markdown",
                                style = MaterialTheme.typography.labelSmall,
                                color = InsightrColors.Accent
                            )
                        }

                        Spacer(modifier = Modifier.height(12.dp))

                        Text(
                            text = uiState.markdown,
                            style = MaterialTheme.typography.bodySmall.copy(
                                fontFamily = FontFamily.Monospace,
                                fontSize = 12.sp,
                                lineHeight = 18.sp
                            ),
                            color = InsightrColors.TextPrimary,
                            modifier = Modifier.verticalScroll(rememberScrollState())
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Copy button
                OutlinedButton(
                    onClick = {
                        val clipboard = context.getSystemService(Context.CLIPBOARD_SERVICE) as ClipboardManager
                        val clip = ClipData.newPlainText("Export", uiState.markdown)
                        clipboard.setPrimaryClip(clip)
                        Toast.makeText(context, "Copied to clipboard", Toast.LENGTH_SHORT).show()
                    },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Check,
                        contentDescription = null,
                        tint = InsightrColors.Accent
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Copy Markdown",
                        color = InsightrColors.Accent
                    )
                }

                Spacer(modifier = Modifier.height(8.dp))

                // Share button
                OutlinedButton(
                    onClick = { },
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(12.dp)
                ) {
                    Icon(
                        imageVector = Icons.Filled.Share,
                        contentDescription = null,
                        tint = InsightrColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    Text(
                        text = "Share to Obsidian",
                        color = InsightrColors.TextPrimary
                    )
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Info card
                Card(
                    modifier = Modifier.fillMaxWidth(),
                    shape = RoundedCornerShape(8.dp),
                    colors = CardDefaults.cardColors(
                        containerColor = InsightrColors.Accent.copy(alpha = 0.1f)
                    )
                ) {
                    Text(
                        text = "Compatible with Obsidian 1.4+, Logseq, and any Markdown editor. Wikilinks preserved.",
                        style = MaterialTheme.typography.bodySmall,
                        color = InsightrColors.TextSecondary,
                        modifier = Modifier.padding(12.dp)
                    )
                }
            }
        }
    }
}
