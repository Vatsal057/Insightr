package com.insightr.ui.screens.onboarding

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.pager.HorizontalPager
import androidx.compose.foundation.pager.rememberPagerState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.insightr.ui.theme.InsightrColors
import kotlinx.coroutines.launch

@Composable
fun OnboardingScreen(
    onComplete: () -> Unit
) {
    val pagerState = rememberPagerState(pageCount = { 3 })
    val scope = rememberCoroutineScope()

    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(InsightrColors.Background)
    ) {
        HorizontalPager(
            state = pagerState,
            modifier = Modifier.fillMaxSize()
        ) { page ->
            when (page) {
                0 -> OnboardingPage1()
                1 -> OnboardingPage2()
                2 -> OnboardingPage3(onComplete = onComplete)
            }
        }

        // Page indicator
        Row(
            modifier = Modifier
                .align(Alignment.BottomCenter)
                .padding(bottom = 48.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            repeat(3) { index ->
                Box(
                    modifier = Modifier
                        .size(if (pagerState.currentPage == index) 24.dp else 8.dp, 8.dp)
                        .clip(CircleShape)
                        .background(
                            if (pagerState.currentPage == index) InsightrColors.Accent
                            else InsightrColors.TextDisabled
                        )
                )
            }
        }
    }
}

@Composable
private fun OnboardingPage1() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Logo
        Text(
            text = "\u26A1 Insightr",
            style = MaterialTheme.typography.headlineMedium,
            color = InsightrColors.Accent
        )

        Spacer(modifier = Modifier.height(48.dp))

        Text(
            text = "Short-form videos",
            style = MaterialTheme.typography.bodyMedium,
            color = InsightrColors.TextSecondary
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Knowledge,\nCaptured.",
            style = MaterialTheme.typography.displayLarge,
            color = InsightrColors.TextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Card(
            shape = RoundedCornerShape(20.dp),
            colors = CardDefaults.cardColors(
                containerColor = InsightrColors.Card
            )
        ) {
            Row(
                modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "\uD83E\uDDE0",
                    style = MaterialTheme.typography.bodyLarge
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = "AI-powered recall",
                    style = MaterialTheme.typography.bodyMedium,
                    color = InsightrColors.TextPrimary
                )
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            text = "Turn every reel into structured, searchable knowledge \u2014 automatically.",
            style = MaterialTheme.typography.bodyLarge,
            color = InsightrColors.TextSecondary,
            textAlign = TextAlign.Center
        )
    }
}

@Composable
private fun OnboardingPage2() {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Logo
        Text(
            text = "\u26A1 Insightr",
            style = MaterialTheme.typography.headlineMedium,
            color = InsightrColors.Accent
        )

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            text = "\uD83C\uDFAC",
            style = MaterialTheme.typography.displayLarge
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Every Reel,\nStructured.",
            style = MaterialTheme.typography.displayLarge,
            color = InsightrColors.TextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Our AI watches, listens, and organizes \u2014 so you never lose a good idea again.",
            style = MaterialTheme.typography.bodyLarge,
            color = InsightrColors.TextSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Feature cards
        Card(
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = CardDefaults.cardColors(
                containerColor = InsightrColors.Card
            )
        ) {
            Column(
                modifier = Modifier.padding(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                FeatureRow(icon = "\uD83D\uDCCB", title = "Auto-summary", subtitle = "Key points extracted instantly")
                FeatureRow(icon = "\uD83C\uDFF7\uFE0F", title = "Smart tags", subtitle = "Topics detected & labeled")
                FeatureRow(icon = "\uD83D\uDD0D", title = "Instant search", subtitle = "Find anything you saved")
            }
        }

        Spacer(modifier = Modifier.height(16.dp))

        Row(
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Accent.copy(alpha = 0.15f)
                )
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(text = "\uD83D\uDCA0", style = MaterialTheme.typography.bodySmall)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "3 key insights",
                        style = MaterialTheme.typography.labelSmall,
                        color = InsightrColors.Accent
                    )
                }
            }

            Card(
                shape = RoundedCornerShape(20.dp),
                colors = CardDefaults.cardColors(
                    containerColor = InsightrColors.Accent.copy(alpha = 0.15f)
                )
            ) {
                Row(
                    modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(text = "\u23F0", style = MaterialTheme.typography.bodySmall)
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "2m 14s saved",
                        style = MaterialTheme.typography.labelSmall,
                        color = InsightrColors.Accent
                    )
                }
            }
        }
    }
}

@Composable
private fun OnboardingPage3(onComplete: () -> Unit) {
    Column(
        modifier = Modifier
            .fillMaxSize()
            .padding(32.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        // Logo
        Text(
            text = "\u26A1 Insightr",
            style = MaterialTheme.typography.headlineMedium,
            color = InsightrColors.Accent
        )

        Spacer(modifier = Modifier.height(32.dp))

        Text(
            text = "\uD83D\uDCE6",
            style = MaterialTheme.typography.displayLarge
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Your Personal\nKnowledge Vault.",
            style = MaterialTheme.typography.displayLarge,
            color = InsightrColors.TextPrimary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(16.dp))

        Text(
            text = "Everything you learned from a video, organized, searchable, yours forever.",
            style = MaterialTheme.typography.bodyLarge,
            color = InsightrColors.TextSecondary,
            textAlign = TextAlign.Center
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Sample vault card
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
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    Text(
                        text = "My Vault",
                        style = MaterialTheme.typography.titleMedium,
                        color = InsightrColors.TextPrimary,
                        fontWeight = FontWeight.Bold
                    )
                    Text(
                        text = "\uD83D\uDCCB 24 insights",
                        style = MaterialTheme.typography.bodySmall,
                        color = InsightrColors.Accent
                    )
                }

                Spacer(modifier = Modifier.height(12.dp))

                VaultSampleItem(title = "The Attention Economy", field = "Psychology", time = "Today")
                VaultSampleItem(title = "How Interest Rates Work", field = "Finance", time = "Yesterday")
                VaultSampleItem(title = "Habit Stacking Explained", field = "Self-growth", time = "2 days ago")
            }
        }

        Spacer(modifier = Modifier.height(32.dp))

        Button(
            onClick = onComplete,
            modifier = Modifier.fillMaxWidth(),
            shape = RoundedCornerShape(12.dp),
            colors = ButtonDefaults.buttonColors(
                containerColor = InsightrColors.Accent
            )
        ) {
            Text(
                text = "Start Building My Vault",
                color = InsightrColors.Background,
                style = MaterialTheme.typography.titleMedium
            )
        }

        Spacer(modifier = Modifier.height(8.dp))

        TextButton(onClick = onComplete) {
            Text(
                text = "Maybe later",
                color = InsightrColors.TextSecondary
            )
        }
    }
}

@Composable
private fun FeatureRow(icon: String, title: String, subtitle: String) {
    Row(
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = icon, style = MaterialTheme.typography.bodyLarge)
        Spacer(modifier = Modifier.width(12.dp))
        Column {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyLarge,
                color = InsightrColors.TextPrimary,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                text = subtitle,
                style = MaterialTheme.typography.bodySmall,
                color = InsightrColors.TextSecondary
            )
        }
    }
}

@Composable
private fun VaultSampleItem(title: String, field: String, time: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(text = "\u25B6", style = MaterialTheme.typography.bodySmall, color = InsightrColors.Accent)
        Spacer(modifier = Modifier.width(12.dp))
        Column(modifier = Modifier.weight(1f)) {
            Text(
                text = title,
                style = MaterialTheme.typography.bodyMedium,
                color = InsightrColors.TextPrimary
            )
            Row {
                Text(
                    text = field,
                    style = MaterialTheme.typography.labelSmall,
                    color = InsightrColors.Accent
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = time,
                    style = MaterialTheme.typography.labelSmall,
                    color = InsightrColors.TextSecondary
                )
            }
        }
    }
}
