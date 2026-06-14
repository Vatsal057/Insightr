package com.insightr.app

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.ArrowForward
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun OnboardingScreen(onGetStarted: () -> Unit = {}) {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(InsightrColors.BackgroundGradient)
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 24.dp, vertical = 32.dp)
        ) {

            Row(
                modifier = Modifier.fillMaxWidth().padding(top = 24.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                CircleIconButton(icon = Icons.Default.ArrowBack, filled = false)
                Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    repeat(3) { i ->
                        Box(
                            modifier = Modifier
                                .size(if (i == 1) 8.dp else 6.dp)
                                .clip(CircleShape)
                                .background(if (i == 1) InsightrColors.Cream else InsightrColors.TextOnDarkMuted)
                        )
                    }
                }
                CircleIconButton(icon = Icons.Default.ArrowForward, onClick = onGetStarted)
            }

            Spacer(modifier = Modifier.height(40.dp))

            Box(
                modifier = Modifier
                    .clip(RoundedCornerShape(28.dp))
                    .background(InsightrColors.Cream)
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Column {
                    Text("Knowledge Cards,", color = InsightrColors.TextOnCream, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    Text("Built Automatically", color = InsightrColors.TextOnCream, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                }
            }

            Spacer(modifier = Modifier.weight(1f))

            Box(
                modifier = Modifier
                    .align(Alignment.End)
                    .clip(RoundedCornerShape(28.dp))
                    .background(InsightrColors.PillDark.copy(alpha = 0.85f))
                    .padding(horizontal = 16.dp, vertical = 14.dp)
            ) {
                Text(
                    "Stop losing what\nyou learn online",
                    color = InsightrColors.TextOnDark,
                    fontSize = 13.sp,
                    fontWeight = FontWeight.Medium,
                    textAlign = TextAlign.End,
                    lineHeight = 16.sp
                )
            }

            Spacer(modifier = Modifier.height(28.dp))

            Text(
                text = "Reels into\nReal Knowledge",
                color = InsightrColors.TextOnDark,
                fontSize = 44.sp,
                fontWeight = FontWeight.Bold,
                lineHeight = 50.sp
            )

            Spacer(modifier = Modifier.height(12.dp))

            Text(
                text = "Drop in a video or post and Insightr turns it into a structured, " +
                        "searchable note — hooks, action items, claims, and all.",
                color = InsightrColors.TextOnDarkMuted,
                fontSize = 14.sp,
                lineHeight = 20.sp
            )

            Spacer(modifier = Modifier.height(28.dp))

            PillButton(text = "Get Started", onClick = onGetStarted)
        }
    }
}
