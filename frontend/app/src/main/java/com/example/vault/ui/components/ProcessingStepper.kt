package com.example.vault.ui.components

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.example.vault.theme.*

/** Represents one step in the processing pipeline. */
data class ProcessingStep(
    val label: String,
    val state: StepState,
)

enum class StepState { Waiting, Active, Done, Error }

/**
 * Animated 5-step processing stepper shown while Vault processes a URL.
 * Steps: Downloading → Transcribing → Extracting → Thinking → Done
 * Active step pulses; done steps show a solid green check circle.
 */
@Composable
fun ProcessingStepper(
    steps: List<ProcessingStep>,
    modifier: Modifier = Modifier,
) {
    Column(
        modifier = modifier,
        verticalArrangement = Arrangement.spacedBy(0.dp),
    ) {
        steps.forEachIndexed { index, step ->
            Row(
                verticalAlignment = Alignment.CenterVertically,
                modifier = Modifier.fillMaxWidth(),
            ) {
                // Node column
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    StepNode(state = step.state)
                    if (index < steps.lastIndex) {
                        Box(
                            modifier = Modifier
                                .width(2.dp)
                                .height(32.dp)
                                .background(
                                    if (step.state == StepState.Done) VaultFact.copy(0.4f)
                                    else VaultBorderStrong
                                )
                        )
                    }
                }

                Spacer(Modifier.width(16.dp))

                // Label
                Text(
                    text = step.label,
                    color = when (step.state) {
                        StepState.Done    -> VaultFact
                        StepState.Active  -> VaultTextPrimary
                        StepState.Error   -> VaultError
                        StepState.Waiting -> VaultTextTertiary
                    },
                    fontSize = 15.sp,
                    fontWeight = if (step.state == StepState.Active) FontWeight.SemiBold
                                 else FontWeight.Normal,
                )
            }
        }
    }
}

@Composable
private fun StepNode(state: StepState) {
    val pulse = rememberInfiniteTransition(label = "step_pulse")
    val scale by pulse.animateFloat(
        initialValue = 1f,
        targetValue  = 1.25f,
        animationSpec = infiniteRepeatable(
            tween(700, easing = FastOutSlowInEasing),
            RepeatMode.Reverse,
        ),
        label = "pulse_scale",
    )

    val nodeSize = 16.dp
    when (state) {
        StepState.Done -> Box(
            modifier = Modifier
                .size(nodeSize)
                .clip(CircleShape)
                .background(VaultFact),
            contentAlignment = Alignment.Center,
        ) {
            Text("✓", color = VaultBackground, fontSize = 9.sp, fontWeight = FontWeight.Bold)
        }

        StepState.Active -> Box(
            modifier = Modifier
                .size(nodeSize * scale)
                .clip(CircleShape)
                .background(
                    Brush.radialGradient(listOf(VaultAccent, VaultAccentMuted))
                )
                .border(1.dp, VaultAccent, CircleShape),
        )

        StepState.Error -> Box(
            modifier = Modifier
                .size(nodeSize)
                .clip(CircleShape)
                .background(VaultError),
            contentAlignment = Alignment.Center,
        ) {
            Text("✕", color = VaultBackground, fontSize = 9.sp, fontWeight = FontWeight.Bold)
        }

        StepState.Waiting -> Box(
            modifier = Modifier
                .size(nodeSize)
                .clip(CircleShape)
                .border(1.dp, VaultBorderStrong, CircleShape),
        )
    }
}
