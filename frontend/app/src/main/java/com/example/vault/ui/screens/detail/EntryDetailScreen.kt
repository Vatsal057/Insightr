package com.example.vault.ui.screens.detail

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.expandVertically
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.platform.LocalUriHandler
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vault.data.api.*
import com.example.vault.data.repository.VaultRepository
import com.example.vault.ui.components.*
import com.example.vault.theme.*

@Composable
fun EntryDetailScreen(
    entryId: Int,
    repository: VaultRepository,
    onBack: () -> Unit,
    onConceptClick: (Int) -> Unit,
    onRelatedEntryClick: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val viewModel: EntryDetailViewModel = viewModel(
        key     = "entry_$entryId",
        factory = EntryDetailViewModel.factory(repository),
    )
    val uiState   by viewModel.uiState.collectAsStateWithLifecycle()
    val doneItems by viewModel.doneItems.collectAsStateWithLifecycle()

    LaunchedEffect(entryId) { viewModel.loadEntry(entryId) }

    Box(modifier = modifier.fillMaxSize().background(VaultBackground)) {
        when (val state = uiState) {
            is DetailUiState.Loading -> {
                Box(Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    CircularProgressIndicator(color = VaultAccent)
                }
            }
            is DetailUiState.Error -> {
                Column(
                    modifier = Modifier.align(Alignment.Center),
                    horizontalAlignment = Alignment.CenterHorizontally,
                ) {
                    Text("⚠", fontSize = 32.sp)
                    Text(state.message, color = VaultTextSecondary)
                }
            }
            is DetailUiState.Success -> {
                val card = state.card
                var extrasExpanded by remember { mutableStateOf(false) }
                val uriHandler = LocalUriHandler.current

                LazyColumn(contentPadding = PaddingValues(bottom = 140.dp)) {
                    // ── Hero ──────────────────────────────────────────────
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .background(Brush.verticalGradient(listOf(VaultAccentDim, VaultBackground)))
                                .statusBarsPadding()
                                .padding(top = 16.dp, bottom = 32.dp, start = 24.dp, end = 24.dp),
                        ) {
                            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                    FieldChip(card.field)
                                    ContentTypeChip(card.contentType)
                                }
                                Text(
                                    card.title,
                                    color = VaultTextPrimary,
                                    fontSize = 26.sp,
                                    fontWeight = FontWeight.Bold,
                                    lineHeight = 34.sp,
                                )
                                Text(
                                    "\"${card.headline}\"",
                                    color = VaultTextSecondary,
                                    fontSize = 16.sp,
                                    fontStyle = FontStyle.Italic,
                                    fontFamily = PlayfairFamily,
                                    lineHeight = 24.sp,
                                )
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(6.dp),
                                    verticalAlignment = Alignment.CenterVertically,
                                ) {
                                    card.tags.take(4).forEach { TagPill(it) }
                                    Spacer(Modifier.weight(1f))
                                    Text(formatDate(card.createdAt), color = VaultTextTertiary, fontSize = 11.sp)
                                }
                            }
                        }
                    }

                    // ── Summary ───────────────────────────────────────────
                    item {
                        SectionCard("Summary") {
                            Text(card.summary, color = VaultTextSecondary, fontSize = 15.sp, lineHeight = 24.sp)
                        }
                    }

                    // ── Key Points ────────────────────────────────────────
                    item {
                        SectionCard("Key Points") {
                            card.keyPoints.lines().filter { it.isNotBlank() }.forEach { line ->
                                Row(
                                    modifier = Modifier.padding(vertical = 4.dp),
                                    horizontalArrangement = Arrangement.spacedBy(12.dp),
                                ) {
                                    Box(
                                        Modifier.width(3.dp).height(20.dp).background(
                                            Brush.verticalGradient(listOf(VaultAccent, VaultAccentMuted))
                                        )
                                    )
                                    Text(
                                        line.trimStart('-', '•', '*', ' '),
                                        color = VaultTextPrimary,
                                        fontSize = 14.sp,
                                        lineHeight = 22.sp,
                                        modifier = Modifier.weight(1f),
                                    )
                                }
                            }
                        }
                    }

                    // ── Type-specific fields ──────────────────────────────
                    if (card.typeSpecificFields.isNotEmpty()) {
                        item {
                            SectionCard(card.contentType.replace("_", " ").replaceFirstChar { it.uppercase() }) {
                                card.typeSpecificFields.forEach { field ->
                                    Column(
                                        modifier = Modifier.padding(vertical = 8.dp),
                                        verticalArrangement = Arrangement.spacedBy(4.dp),
                                    ) {
                                        Text(field.label, color = VaultAccent, fontSize = 11.sp,
                                            fontWeight = FontWeight.SemiBold, letterSpacing = 0.5f.sp)
                                        Text(field.value, color = VaultTextPrimary, fontSize = 14.sp, lineHeight = 22.sp)
                                        HorizontalDivider(color = VaultDivider, modifier = Modifier.padding(top = 8.dp))
                                    }
                                }
                            }
                        }
                    }

                    // ── Action Items ──────────────────────────────────────
                    if (card.actionItems.isNotEmpty()) {
                        item {
                            SectionCard("Action Items") {
                                card.actionItems.forEachIndexed { idx, item ->
                                    ActionItemRow(
                                        text     = item.text,
                                        done     = idx in doneItems || item.done,
                                        onToggle = { viewModel.toggleActionItem(idx) },
                                        modifier = Modifier.padding(vertical = 2.dp),
                                    )
                                }
                            }
                        }
                    }

                    // ── Next Step CTA ─────────────────────────────────────
                    item {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(horizontal = 20.dp, vertical = 8.dp)
                                .background(
                                    Brush.horizontalGradient(listOf(VaultAccentMuted, VaultAccentDim)),
                                    LargeCorner,
                                )
                                .border(1.dp, VaultAccent.copy(0.2f), LargeCorner)
                                .padding(20.dp),
                        ) {
                            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                Text("What to do now", color = VaultAccent, fontSize = 11.sp,
                                    fontWeight = FontWeight.SemiBold, letterSpacing = 0.5f.sp)
                                Text(card.nextStep, color = VaultTextPrimary, fontSize = 15.sp, lineHeight = 24.sp)
                            }
                        }
                    }

                    // ── Dive Deeper toggle ────────────────────────────────
                    item {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .clickable { extrasExpanded = !extrasExpanded }
                                .padding(horizontal = 24.dp, vertical = 16.dp),
                            verticalAlignment = Alignment.CenterVertically,
                            horizontalArrangement = Arrangement.SpaceBetween,
                        ) {
                            Text("Dive Deeper", color = VaultTextPrimary, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
                            Text(if (extrasExpanded) "▲" else "▼", color = VaultTextTertiary, fontSize = 12.sp)
                        }
                        HorizontalDivider(color = VaultDivider, modifier = Modifier.padding(horizontal = 24.dp))
                    }

                    // ── Extras ────────────────────────────────────────────
                    item {
                        AnimatedVisibility(
                            visible = extrasExpanded,
                            enter   = expandVertically(),
                            exit    = shrinkVertically(),
                        ) {
                            val extras = card.extras
                            Column {
                                if (extras.concepts.isNotEmpty()) {
                                    SectionCard("Concepts") {
                                        FlowRow(
                                            horizontalArrangement = Arrangement.spacedBy(8.dp),
                                            verticalArrangement   = Arrangement.spacedBy(8.dp),
                                        ) {
                                            extras.concepts.forEach { concept ->
                                                ConceptChip(
                                                    name = concept.name,
                                                    conceptType = concept.conceptType,
                                                    onClick = concept.id?.let { id -> { onConceptClick(id) } },
                                                )
                                            }
                                        }
                                    }
                                }

                                if (extras.connections.isNotEmpty()) {
                                    SectionCard("Connected Entries") {
                                        LazyRow(horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                                            items(extras.connections) { conn ->
                                                ConnectionCard(
                                                    connection = conn,
                                                    onClick    = { onRelatedEntryClick(conn.entryId) },
                                                )
                                            }
                                        }
                                    }
                                }

                                if (extras.claims.isNotEmpty()) {
                                    SectionCard("Claims") {
                                        extras.claims.forEach { claim ->
                                            ClaimRow(claim)
                                            HorizontalDivider(
                                                color = VaultDivider,
                                                modifier = Modifier.padding(vertical = 8.dp),
                                            )
                                        }
                                    }
                                }

                                if (extras.exploreFurther.isNotEmpty()) {
                                    SectionCard("Explore Further") {
                                        extras.exploreFurther.forEach { q ->
                                            Row(
                                                modifier = Modifier.fillMaxWidth().padding(vertical = 6.dp),
                                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                                            ) {
                                                Text("→", color = VaultAccent, fontSize = 14.sp)
                                                Text(q, color = VaultTextSecondary, fontSize = 14.sp, lineHeight = 20.sp)
                                            }
                                        }
                                    }
                                }

                                if (extras.referencedArtifacts.isNotEmpty()) {
                                    SectionCard("Resources") {
                                        extras.referencedArtifacts.forEach { artifact ->
                                            ArtifactRow(
                                                artifact = artifact,
                                                onClick  = artifact.url?.let { url -> { uriHandler.openUri(url) } },
                                            )
                                        }
                                    }
                                }

                                SectionCard("Source") {
                                    Text(
                                        card.sourceUrl,
                                        color = VaultAccent,
                                        fontSize = 13.sp,
                                        modifier = Modifier.clickable { uriHandler.openUri(card.sourceUrl) },
                                    )
                                }
                            }
                        }
                    }
                }

                // ── Back button ───────────────────────────────────────────
                // Uses text symbol "←" — no material-icons dependency needed
                Box(
                    modifier = Modifier
                        .padding(16.dp)
                        .align(Alignment.TopStart)
                        .background(VaultSurfaceL2.copy(alpha = 0.85f), PillCorner)
                        .clickable(onClick = onBack)
                        .padding(horizontal = 16.dp, vertical = 10.dp),
                ) {
                    Text("←", color = VaultTextPrimary, fontSize = 20.sp)
                }
            }
        }
    }
}

// ── Private composables ───────────────────────────────────────────────────────

@Composable
private fun SectionCard(title: String, content: @Composable ColumnScope.() -> Unit) {
    Column(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp)) {
        Text(
            title,
            color = VaultTextTertiary,
            fontSize = 11.sp,
            fontWeight = FontWeight.SemiBold,
            letterSpacing = 0.8f.sp,
            modifier = Modifier.padding(bottom = 10.dp),
        )
        GlassCard(modifier = Modifier.fillMaxWidth(), shape = MediumCorner, elevation = GlassElevation.Level1) {
            Column(modifier = Modifier.padding(16.dp), content = content)
        }
    }
}

@Composable
private fun ConnectionCard(connection: Connection, onClick: () -> Unit) {
    GlassCard(
        modifier  = Modifier.width(160.dp).clickable(onClick = onClick),
        shape     = MediumCorner,
        elevation = GlassElevation.Level2,
    ) {
        Column(modifier = Modifier.padding(12.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
            Text(connection.title, color = VaultTextPrimary, fontSize = 13.sp,
                fontWeight = FontWeight.SemiBold, maxLines = 2, lineHeight = 18.sp)
            Text(connection.reason, color = VaultTextTertiary, fontSize = 11.sp, maxLines = 2, lineHeight = 16.sp)
        }
    }
}

@Composable
private fun ClaimRow(claim: Claim) {
    val (color, label) = when (claim.verifiability) {
        "fact"    -> Pair(VaultFact,       "FACT")
        "opinion" -> Pair(VaultOpinion,    "OPINION")
        else      -> Pair(VaultUnverified, "UNVERIFIED")
    }
    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        Box(
            modifier = Modifier
                .background(color.copy(0.12f), PillCorner)
                .padding(horizontal = 8.dp, vertical = 3.dp),
        ) {
            Text(label, color = color, fontSize = 9.sp, fontWeight = FontWeight.Bold)
        }
        Text(claim.claim, color = VaultTextSecondary, fontSize = 13.sp, lineHeight = 20.sp, modifier = Modifier.weight(1f))
    }
}

@Composable
private fun ArtifactRow(artifact: ReferencedArtifact, onClick: (() -> Unit)?) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .then(if (onClick != null) Modifier.clickable(onClick = onClick) else Modifier)
            .padding(vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(12.dp),
        verticalAlignment     = Alignment.CenterVertically,
    ) {
        Text(
            when (artifact.type) { "tool" -> "⚙"; "book" -> "📖"; "link" -> "🔗"; "template" -> "📄"; else -> "•" },
            fontSize = 16.sp,
        )
        Column(modifier = Modifier.weight(1f)) {
            Text(artifact.name, color = if (onClick != null) VaultAccent else VaultTextPrimary,
                fontSize = 14.sp, fontWeight = FontWeight.Medium)
            artifact.snippet?.let { Text(it, color = VaultTextTertiary, fontSize = 12.sp, maxLines = 1) }
        }
    }
}
