package com.insightr.app

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Dns
import androidx.compose.material.icons.filled.ErrorOutline
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.insightr.app.data.InsightrRepository
import com.insightr.app.data.NetworkConfig
import kotlinx.coroutines.launch

/**
 * Lets the user point the app at their FastAPI backend (api.py), e.g.
 * "http://192.168.1.50:8000/". Stored in SharedPreferences via NetworkConfig.
 */
@Composable
fun SettingsScreen(onBack: () -> Unit = {}) {
    var url by remember { mutableStateOf(NetworkConfig.getBaseUrl()) }
    var testState by remember { mutableStateOf<TestState>(TestState.Idle) }
    val scope = rememberCoroutineScope()

    Box(modifier = Modifier.fillMaxSize().background(InsightrColors.BackgroundGradient)) {
        Column(
            modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp, vertical = 32.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Row(verticalAlignment = Alignment.CenterVertically) {
                CircleIconButton(icon = Icons.Default.ArrowBack, onClick = onBack, filled = false)
                Spacer(modifier = Modifier.width(12.dp))
                SectionHeader("Backend")
            }

            Text(
                "Point Insightr at the FastAPI server running api.py (e.g. your laptop's IP on the same Wi-Fi).",
                color = InsightrColors.TextOnDarkMuted,
                fontSize = 13.sp,
                lineHeight = 18.sp
            )

            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(20.dp))
                    .background(InsightrColors.Cream)
                    .padding(horizontal = 16.dp, vertical = 16.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.Dns, contentDescription = null, tint = InsightrColors.TextOnCreamMuted)
                Spacer(modifier = Modifier.width(10.dp))
                BasicTextField(
                    value = url,
                    onValueChange = { url = it; testState = TestState.Idle },
                    singleLine = true,
                    textStyle = TextStyle(color = InsightrColors.TextOnCream, fontSize = 14.sp),
                    modifier = Modifier.weight(1f)
                )
            }

            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                SourceTagButton("http://10.0.2.2:8000/") { url = it; testState = TestState.Idle }
                SourceTagButton("http://192.168.1.") { url = it; testState = TestState.Idle }
            }
            Text(
                "Tip: \"10.0.2.2\" reaches your computer's localhost from the Android emulator. On a real phone, use your computer's LAN IP.",
                color = InsightrColors.TextOnDarkMuted,
                fontSize = 11.sp,
                lineHeight = 16.sp
            )

            PillButton(
                text = "Save & Test Connection",
                onClick = {
                    NetworkConfig.setBaseUrl(url)
                    testState = TestState.Testing
                    scope.launch {
                        val result = InsightrRepository.getFeed()
                        testState = when (result) {
                            is com.insightr.app.data.ApiResult.Success ->
                                if (result.offline) TestState.Failed else TestState.Success
                            is com.insightr.app.data.ApiResult.Error -> TestState.Failed
                        }
                    }
                }
            )

            when (testState) {
                TestState.Testing -> StatusRow("Testing connection...", InsightrColors.TextOnDarkMuted, null)
                TestState.Success -> StatusRow("Connected! Your vault is live.", InsightrColors.Success, Icons.Default.CheckCircle)
                TestState.Failed -> StatusRow("Couldn't reach this server — showing demo data instead.", InsightrColors.Danger, Icons.Default.ErrorOutline)
                TestState.Idle -> {}
            }
        }
    }
}

private enum class TestState { Idle, Testing, Success, Failed }

@Composable
private fun StatusRow(text: String, color: Color, icon: androidx.compose.ui.graphics.vector.ImageVector?) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        icon?.let {
            Icon(it, contentDescription = null, tint = color, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(8.dp))
        }
        Text(text, color = color, fontSize = 13.sp)
    }
}

@Composable
private fun SourceTagButton(value: String, onClick: (String) -> Unit) {
    Box(
        modifier = Modifier
            .clip(RoundedCornerShape(14.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .clickable { onClick(value) }
            .padding(horizontal = 12.dp, vertical = 8.dp)
    ) {
        Text(value, color = InsightrColors.TextOnDarkMuted, fontSize = 11.sp)
    }
}

/** Small banner shown when a screen is displaying SampleData because the backend was unreachable. */
@Composable
fun OfflineBanner(onOpenSettings: () -> Unit) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(16.dp))
            .background(InsightrColors.Danger.copy(alpha = 0.15f))
            .clickable(onClick = onOpenSettings)
            .padding(horizontal = 14.dp, vertical = 10.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(Icons.Default.ErrorOutline, contentDescription = null, tint = InsightrColors.Danger, modifier = Modifier.size(16.dp))
        Spacer(modifier = Modifier.width(8.dp))
        Text(
            "Showing demo data — backend unreachable. Tap to configure.",
            color = InsightrColors.TextOnDark,
            fontSize = 12.sp,
            fontWeight = FontWeight.Medium
        )
    }
}
