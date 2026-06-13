package com.example.vault.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Paint
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.drawIntoCanvas
import androidx.compose.ui.graphics.nativeCanvas
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import com.example.vault.data.api.Concept
import com.example.vault.theme.*
import kotlin.math.*

/**
 * Knowledge Graph — a Canvas-drawn force-directed node graph.
 *
 * Renders concepts as coloured circles, with edges connecting
 * related concepts that appear together in entries.
 * Tap a node to select it (caller gets concept id via onNodeTap).
 *
 * Layout: simple circular arrangement with concept-type grouping.
 */
@Composable
fun KnowledgeGraphCanvas(
    concepts: List<Concept>,
    onNodeTap: (Concept) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (concepts.isEmpty()) return

    // Compute positions once (stable, circular layout)
    val positions = remember(concepts) { computeLayout(concepts) }
    var selectedId by remember { mutableStateOf<Int?>(null) }

    Canvas(
        modifier = modifier
            .fillMaxSize()
            .pointerInput(positions) {
                detectTapGestures { tap ->
                    // Find nearest node within 40dp tap radius
                    val hit = positions.entries.minByOrNull { (_, pos) ->
                        val dx = tap.x - pos.x * size.width
                        val dy = tap.y - pos.y * size.height
                        sqrt(dx * dx + dy * dy)
                    }
                    hit?.let { (idx, pos) ->
                        val dx = tap.x - pos.x * size.width
                        val dy = tap.y - pos.y * size.height
                        if (sqrt(dx * dx + dy * dy) < 80f) {
                            val concept = concepts[idx]
                            selectedId = concept.id
                            onNodeTap(concept)
                        }
                    }
                }
            }
    ) {
        val w = size.width
        val h = size.height

        // Draw edges between same-type concepts
        val typeGroups = concepts.indices.groupBy { concepts[it].conceptType }
        typeGroups.values.forEach { group ->
            if (group.size > 1) {
                for (i in 0 until group.size - 1) {
                    val a = positions[group[i]] ?: continue
                    val b = positions[group[i + 1]] ?: continue
                    drawLine(
                        color  = Color.White.copy(alpha = 0.04f),
                        start  = Offset(a.x * w, a.y * h),
                        end    = Offset(b.x * w, b.y * h),
                        strokeWidth = 1.dp.toPx(),
                    )
                }
            }
        }

        // Draw nodes
        concepts.forEachIndexed { idx, concept ->
            val pos = positions[idx] ?: return@forEachIndexed
            val cx  = pos.x * w
            val cy  = pos.y * h
            val r   = if (concept.id == selectedId) 28.dp.toPx() else 22.dp.toPx()
            val color = conceptTypeColorRaw(concept.conceptType)

            // Glow ring for selected
            if (concept.id == selectedId) {
                drawCircle(
                    color  = color.copy(alpha = 0.2f),
                    radius = r + 10.dp.toPx(),
                    center = Offset(cx, cy),
                )
            }

            // Node circle
            drawCircle(
                color  = color.copy(alpha = 0.15f),
                radius = r,
                center = Offset(cx, cy),
            )
            drawCircle(
                color  = color.copy(alpha = 0.6f),
                radius = r,
                center = Offset(cx, cy),
                style  = androidx.compose.ui.graphics.drawscope.Stroke(2.dp.toPx()),
            )

            // Label
            drawIntoCanvas { canvas ->
                val paint = android.graphics.Paint().apply {
                    this.color = android.graphics.Color.WHITE
                    this.alpha = 200
                    textSize   = 11.dp.toPx()
                    textAlign  = android.graphics.Paint.Align.CENTER
                    isFakeBoldText = concept.id == selectedId
                }
                canvas.nativeCanvas.drawText(
                    concept.name.take(12),
                    cx,
                    cy + r + 14.dp.toPx(),
                    paint,
                )
            }
        }
    }
}

/** Normalized (0..1) position for each concept index. */
data class NormPos(val x: Float, val y: Float)

/** Arrange concepts in a radial layout, grouped by type in concentric rings. */
private fun computeLayout(concepts: List<Concept>): Map<Int, NormPos> {
    val result = mutableMapOf<Int, NormPos>()
    val cx = 0.5f
    val cy = 0.5f

    if (concepts.size == 1) {
        result[0] = NormPos(cx, cy)
        return result
    }

    val total = concepts.size
    concepts.forEachIndexed { idx, _ ->
        val angle  = (2 * PI * idx / total).toFloat()
        val radius = 0.35f
        result[idx] = NormPos(
            x = cx + radius * cos(angle),
            y = cy + radius * sin(angle),
        )
    }
    return result
}

private fun conceptTypeColorRaw(type: String): Color = when (type) {
    "concept"     -> VaultConceptColor
    "framework"   -> VaultFrameworkColor
    "tool"        -> VaultToolColor
    "book"        -> VaultBookColor
    "person"      -> VaultPersonColor
    "methodology" -> VaultMethodColor
    "website"     -> VaultWebsiteColor
    else          -> VaultTextSecondary
}
