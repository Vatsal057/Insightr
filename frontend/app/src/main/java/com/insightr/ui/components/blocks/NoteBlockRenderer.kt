package com.insightr.ui.components.blocks

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.insightr.data.api.NoteBlockDto
import com.insightr.ui.theme.InsightrColors

@Composable
fun NoteBlockRenderer(
    block: NoteBlockDto,
    modifier: Modifier = Modifier
) {
    when (block.blockType) {
        "key_insight" -> KeyInsightBlock(block = block, modifier = modifier)
        "text" -> TextBlock(block = block, modifier = modifier)
        "bullets" -> BulletsBlock(block = block, modifier = modifier)
        "steps" -> StepsBlock(block = block, modifier = modifier)
        "checklist" -> ChecklistBlock(block = block, modifier = modifier)
        "stat_row" -> StatRowBlock(block = block, modifier = modifier)
        "comparison" -> ComparisonBlock(block = block, modifier = modifier)
        "label_values" -> LabelValuesBlock(block = block, modifier = modifier)
        "timeline" -> TimelineBlock(block = block, modifier = modifier)
        "quote" -> QuoteBlock(block = block, modifier = modifier)
        "code_snippet" -> CodeSnippetBlock(block = block, modifier = modifier)
    }
}

@Composable
fun KeyInsightBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = InsightrColors.AccentLight.copy(alpha = 0.1f)
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            if (block.title.isNotBlank()) {
                Text(
                    text = block.title.uppercase(),
                    style = MaterialTheme.typography.labelMedium,
                    color = InsightrColors.Accent,
                    letterSpacing = 1.sp
                )
                Spacer(modifier = Modifier.height(8.dp))
            }
            Text(
                text = block.content,
                style = MaterialTheme.typography.bodyLarge,
                color = InsightrColors.TextPrimary
            )
        }
    }
}

@Composable
fun TextBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
        Text(
            text = block.content,
            style = MaterialTheme.typography.bodyMedium,
            color = InsightrColors.TextSecondary
        )
    }
}

@Composable
fun BulletsBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
        block.content.lines().filter { it.isNotBlank() }.forEach { line ->
            Row(
                modifier = Modifier.padding(vertical = 2.dp)
            ) {
                Text(
                    text = "\u2022",
                    style = MaterialTheme.typography.bodyMedium,
                    color = InsightrColors.Accent
                )
                Spacer(modifier = Modifier.width(8.dp))
                Text(
                    text = line.trim(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = InsightrColors.TextSecondary
                )
            }
        }
    }
}

@Composable
fun StepsBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
        block.content.lines().filter { it.isNotBlank() }.forEachIndexed { index, line ->
            Row(
                modifier = Modifier.padding(vertical = 4.dp),
                verticalAlignment = Alignment.Top
            ) {
                Box(
                    modifier = Modifier
                        .background(InsightrColors.Accent, RoundedCornerShape(50))
                        .padding(horizontal = 8.dp, vertical = 2.dp)
                ) {
                    Text(
                        text = "${index + 1}",
                        style = MaterialTheme.typography.labelSmall,
                        color = InsightrColors.Background
                    )
                }
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = line.trim(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = InsightrColors.TextSecondary
                )
            }
        }
    }
}

@Composable
fun ChecklistBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
        block.content.lines().filter { it.isNotBlank() }.forEach { line ->
            Row(
                modifier = Modifier.padding(vertical = 4.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Box(
                    modifier = Modifier
                        .background(InsightrColors.Accent.copy(alpha = 0.2f), RoundedCornerShape(4.dp))
                        .padding(4.dp)
                ) {
                    Text(
                        text = "\u2713",
                        style = MaterialTheme.typography.labelSmall,
                        color = InsightrColors.Accent
                    )
                }
                Spacer(modifier = Modifier.width(12.dp))
                Text(
                    text = line.trim(),
                    style = MaterialTheme.typography.bodyMedium,
                    color = InsightrColors.TextSecondary
                )
            }
        }
    }
}

@Composable
fun StatRowBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.spacedBy(8.dp)
        ) {
            block.content.lines().filter { it.isNotBlank() }.forEach { line ->
                val parts = line.split("|")
                if (parts.size >= 2) {
                    Card(
                        modifier = Modifier.weight(1f),
                        shape = RoundedCornerShape(8.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = InsightrColors.BackgroundSecondary
                        )
                    ) {
                        Column(
                            modifier = Modifier.padding(12.dp),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = parts[0].trim(),
                                style = MaterialTheme.typography.headlineSmall,
                                color = InsightrColors.Accent
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = parts[1].trim(),
                                style = MaterialTheme.typography.labelSmall,
                                color = InsightrColors.TextSecondary
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun ComparisonBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    val lines = block.content.lines().filter { it.isNotBlank() }
    if (lines.size < 2) return

    val headers = lines[0].split("|")
    val rows = lines.drop(1)

    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }

        Card(
            shape = RoundedCornerShape(8.dp),
            colors = CardDefaults.cardColors(
                containerColor = InsightrColors.BackgroundSecondary
            )
        ) {
            Column(modifier = Modifier.padding(12.dp)) {
                // Headers
                Row(modifier = Modifier.fillMaxWidth()) {
                    if (headers.isNotEmpty()) {
                        Text(
                            text = headers.getOrNull(0)?.trim() ?: "",
                            style = MaterialTheme.typography.labelMedium,
                            color = InsightrColors.Accent,
                            modifier = Modifier.weight(1f)
                        )
                    }
                    if (headers.size > 1) {
                        Text(
                            text = headers[1].trim(),
                            style = MaterialTheme.typography.labelMedium,
                            color = InsightrColors.Accent,
                            modifier = Modifier.weight(1f)
                        )
                    }
                }

                Spacer(modifier = Modifier.height(8.dp))

                rows.forEach { row ->
                    val cells = row.split("|")
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp)
                    ) {
                        if (cells.isNotEmpty()) {
                            Text(
                                text = cells[0].trim(),
                                style = MaterialTheme.typography.bodySmall,
                                color = InsightrColors.TextSecondary,
                                modifier = Modifier.weight(1f)
                            )
                        }
                        if (cells.size > 1) {
                            Text(
                                text = cells[1].trim(),
                                style = MaterialTheme.typography.bodySmall,
                                color = InsightrColors.TextSecondary,
                                modifier = Modifier.weight(1f)
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
fun LabelValuesBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
        block.content.lines().filter { it.isNotBlank() }.forEach { line ->
            val parts = line.split(":", limit = 2)
            if (parts.size >= 2) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(vertical = 4.dp)
                ) {
                    Text(
                        text = parts[0].trim(),
                        style = MaterialTheme.typography.labelMedium,
                        color = InsightrColors.TextSecondary,
                        modifier = Modifier.weight(0.4f)
                    )
                    Text(
                        text = parts[1].trim(),
                        style = MaterialTheme.typography.bodyMedium,
                        color = InsightrColors.TextPrimary,
                        modifier = Modifier.weight(0.6f)
                    )
                }
            }
        }
    }
}

@Composable
fun TimelineBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
        block.content.lines().filter { it.isNotBlank() }.forEachIndexed { index, line ->
            val parts = line.split(":", limit = 2)
            Row(
                modifier = Modifier.padding(vertical = 4.dp),
                verticalAlignment = Alignment.Top
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.width(24.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .background(InsightrColors.Accent, RoundedCornerShape(50))
                            .padding(4.dp)
                    ) {
                        Text(
                            text = "${index + 1}",
                            style = MaterialTheme.typography.labelSmall,
                            color = InsightrColors.Background
                        )
                    }
                    if (index < block.content.lines().filter { it.isNotBlank() }.size - 1) {
                        Box(
                            modifier = Modifier
                                .width(2.dp)
                                .height(24.dp)
                                .background(InsightrColors.Border)
                        )
                    }
                }
                Spacer(modifier = Modifier.width(12.dp))
                Column {
                    if (parts.size >= 2) {
                        Text(
                            text = parts[0].trim(),
                            style = MaterialTheme.typography.labelMedium,
                            color = InsightrColors.Accent
                        )
                        Text(
                            text = parts[1].trim(),
                            style = MaterialTheme.typography.bodySmall,
                            color = InsightrColors.TextSecondary
                        )
                    } else {
                        Text(
                            text = line.trim(),
                            style = MaterialTheme.typography.bodyMedium,
                            color = InsightrColors.TextSecondary
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun QuoteBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Card(
        modifier = modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = InsightrColors.BackgroundSecondary
        )
    ) {
        Column(
            modifier = Modifier.padding(16.dp)
        ) {
            Text(
                text = "\u201C${block.content}\u201D",
                style = MaterialTheme.typography.headlineSmall.copy(
                    fontStyle = FontStyle.Italic
                ),
                color = InsightrColors.TextPrimary
            )
            if (block.title.isNotBlank()) {
                Spacer(modifier = Modifier.height(8.dp))
                Text(
                    text = "\u2014 ${block.title}",
                    style = MaterialTheme.typography.bodySmall,
                    color = InsightrColors.TextSecondary
                )
            }
        }
    }
}

@Composable
fun CodeSnippetBlock(block: NoteBlockDto, modifier: Modifier = Modifier) {
    Column(modifier = modifier.fillMaxWidth()) {
        if (block.title.isNotBlank()) {
            Text(
                text = block.title,
                style = MaterialTheme.typography.titleMedium,
                color = InsightrColors.TextPrimary
            )
            Spacer(modifier = Modifier.height(8.dp))
        }
        Card(
            shape = RoundedCornerShape(8.dp),
            colors = CardDefaults.cardColors(
                containerColor = InsightrColors.BackgroundSecondary
            )
        ) {
            Text(
                text = block.content,
                style = MaterialTheme.typography.bodySmall.copy(
                    fontFamily = FontFamily.Monospace,
                    fontSize = 12.sp
                ),
                color = InsightrColors.TextPrimary,
                modifier = Modifier.padding(12.dp)
            )
        }
    }
}
