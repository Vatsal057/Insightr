package com.insightr.ui.screens.processing

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Link
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.insightr.ui.components.chips.CategoryPill
import com.insightr.ui.theme.InsightrColors
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddUrlBottomSheet(
    onDismiss: () -> Unit,
    onProcess: (String) -> Unit
) {
    val sheetState = rememberModalBottomSheetState()
    val scope = rememberCoroutineScope()
    var url by remember { mutableStateOf("") }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState,
        containerColor = InsightrColors.Card,
        shape = RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp)
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp)
        ) {
            // Handle
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(bottom = 16.dp),
                contentAlignment = Alignment.Center
            ) {
                Box(
                    modifier = Modifier
                        .size(32.dp, 4.dp)
                        .background(InsightrColors.TextDisabled, RoundedCornerShape(2.dp))
                )
            }

            Text(
                text = "Add a Short",
                style = MaterialTheme.typography.headlineMedium,
                color = InsightrColors.TextPrimary
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "We'll extract insights automatically",
                style = MaterialTheme.typography.bodyMedium,
                color = InsightrColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(24.dp))

            // URL input
            OutlinedTextField(
                value = url,
                onValueChange = { url = it },
                modifier = Modifier.fillMaxWidth(),
                placeholder = {
                    Text(
                        text = "Paste URL here",
                        color = InsightrColors.TextDisabled
                    )
                },
                leadingIcon = {
                    Icon(
                        imageVector = Icons.Filled.Link,
                        contentDescription = null,
                        tint = InsightrColors.TextSecondary
                    )
                },
                shape = RoundedCornerShape(12.dp),
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor = InsightrColors.Accent,
                    unfocusedBorderColor = InsightrColors.Border,
                    focusedContainerColor = InsightrColors.BackgroundSecondary,
                    unfocusedContainerColor = InsightrColors.BackgroundSecondary,
                    focusedTextColor = InsightrColors.TextPrimary,
                    unfocusedTextColor = InsightrColors.TextPrimary
                ),
                singleLine = true
            )

            Spacer(modifier = Modifier.height(8.dp))

            Text(
                text = "Instagram, TikTok or YouTube Short",
                style = MaterialTheme.typography.bodySmall,
                color = InsightrColors.TextSecondary
            )

            Spacer(modifier = Modifier.height(16.dp))

            // Platform pills
            Row(
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                CategoryPill(label = "\uD83D\uDFE5 Instagram")
                CategoryPill(label = "\uD83D\uDFE8 TikTok")
                CategoryPill(label = "\u2B55 YouTube")
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Process button
            androidx.compose.material3.Button(
                onClick = {
                    if (url.isNotBlank()) {
                        scope.launch {
                            sheetState.hide()
                            onProcess(url)
                        }
                    }
                },
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(12.dp),
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(
                    containerColor = InsightrColors.Accent
                )
            ) {
                Text(
                    text = "\u25B6 Process",
                    color = InsightrColors.Background,
                    style = MaterialTheme.typography.titleMedium
                )
            }

            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
