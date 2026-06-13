package com.example.vault.ui.screens.explore

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.example.vault.data.api.Concept
import com.example.vault.data.api.SearchResult
import com.example.vault.data.repository.VaultRepository
import com.example.vault.ui.components.*
import com.example.vault.theme.*

private val CONCEPT_TYPES = listOf(
    null to "All", "concept" to "◈ Concept", "framework" to "⬡ Framework",
    "tool" to "⚙ Tool", "book" to "📖 Book", "person" to "◉ Person",
    "methodology" to "⟡ Method", "website" to "◎ Website",
)

@Composable
fun ExploreScreen(
    repository: VaultRepository,
    onEntryClick: (Int) -> Unit,
    onConceptClick: (Int) -> Unit,
    modifier: Modifier = Modifier,
) {
    val viewModel: ExploreViewModel = viewModel(factory = ExploreViewModel.factory(repository))
    val state by viewModel.state.collectAsStateWithLifecycle()

    Box(modifier = modifier.fillMaxSize()) {
        LazyColumn(modifier = Modifier.fillMaxSize(), contentPadding = PaddingValues(bottom = 120.dp)) {
            // Header
            item {
                Column(
                    modifier = Modifier.fillMaxWidth()
                        .background(Brush.verticalGradient(listOf(VaultAccentDim, VaultBackground)))
                        .statusBarsPadding()
                        .padding(horizontal = 24.dp).padding(top = 16.dp, bottom = 20.dp),
                ) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                        Text("Explore", color = VaultTextPrimary, fontSize = 32.sp, fontWeight = FontWeight.Bold)
                        Box(
                            modifier = Modifier
                                .background(if (state.graphMode) VaultAccentMuted else VaultSurfaceL2, PillCorner)
                                .clickable { viewModel.toggleGraphMode() }
                                .padding(horizontal = 14.dp, vertical = 8.dp),
                        ) {
                            Text("⬡ Graph", color = if (state.graphMode) VaultAccent else VaultTextTertiary, fontSize = 12.sp, fontWeight = FontWeight.Medium)
                        }
                    }
                }
            }

            // Search bar
            item {
                GlassCard(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp), shape = LargeCorner, elevation = GlassElevation.Level1) {
                    OutlinedTextField(
                        value = state.query,
                        onValueChange = viewModel::onQueryChange,
                        placeholder = { Text("Search your knowledge…", color = VaultTextTertiary) },
                        colors = OutlinedTextFieldDefaults.colors(
                            unfocusedBorderColor = androidx.compose.ui.graphics.Color.Transparent,
                            focusedBorderColor   = androidx.compose.ui.graphics.Color.Transparent,
                            unfocusedTextColor   = VaultTextPrimary,
                            focusedTextColor     = VaultTextPrimary,
                            cursorColor          = VaultAccent,
                        ),
                        keyboardOptions = KeyboardOptions(imeAction = ImeAction.Search),
                        modifier = Modifier.fillMaxWidth().padding(horizontal = 8.dp),
                        singleLine = true,
                        leadingIcon = { Text("⌕", color = VaultTextTertiary, fontSize = 18.sp, modifier = Modifier.padding(start = 8.dp)) },
                    )
                }
            }

            // Type filter chips
            item {
                LazyRow(contentPadding = PaddingValues(horizontal = 20.dp), horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.padding(vertical = 8.dp)) {
                    items(CONCEPT_TYPES) { (type, label) ->
                        val selected = state.selectedType == type
                        Box(
                            modifier = Modifier
                                .background(if (selected) VaultAccentMuted else VaultSurfaceL2, PillCorner)
                                .border(1.dp, if (selected) VaultAccent.copy(0.4f) else VaultBorder, PillCorner)
                                .clickable { viewModel.loadConcepts(type) }
                                .padding(horizontal = 14.dp, vertical = 8.dp),
                        ) {
                            Text(label, color = if (selected) VaultAccent else VaultTextSecondary, fontSize = 12.sp,
                                fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Normal)
                        }
                    }
                }
            }

            // Search results
            if (state.query.isNotBlank()) {
                if (state.isSearching) {
                    item { Box(Modifier.fillMaxWidth().padding(40.dp), Alignment.Center) { CircularProgressIndicator(color = VaultAccent) } }
                } else if (state.searchResults.isEmpty()) {
                    item { Box(Modifier.fillMaxWidth().padding(40.dp), Alignment.Center) { Text("No results for \"${state.query}\"", color = VaultTextSecondary, fontSize = 14.sp) } }
                } else {
                    item { Text("${state.searchResults.size} results", color = VaultTextTertiary, fontSize = 11.sp, modifier = Modifier.padding(horizontal = 24.dp, vertical = 8.dp)) }
                    items(state.searchResults, key = { it.id }) { result ->
                        SearchResultRow(result = result, onClick = { onEntryClick(result.id) })
                    }
                }
                return@LazyColumn
            }

            // Graph mode
            if (state.graphMode && state.concepts.isNotEmpty()) {
                item {
                    Column(modifier = Modifier.fillMaxWidth()) {
                        Text("Knowledge Map", color = VaultTextTertiary, fontSize = 11.sp, fontWeight = FontWeight.Medium,
                            letterSpacing = 0.8f.sp, modifier = Modifier.padding(start = 24.dp, top = 8.dp, bottom = 12.dp))
                        state.selectedConcept?.let { c ->
                            GlassCard(modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 12.dp), shape = MediumCorner, elevation = GlassElevation.Level2) {
                                Column(modifier = Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
                                    ConceptChip(c.name, c.conceptType)
                                    Text(c.summary, color = VaultTextSecondary, fontSize = 13.sp)
                                    c.id?.let { id -> Text("View entries →", color = VaultAccent, fontSize = 12.sp, modifier = Modifier.clickable { onConceptClick(id) }) }
                                }
                            }
                        }
                        KnowledgeGraphCanvas(concepts = state.concepts, onNodeTap = viewModel::onConceptSelect,
                            modifier = Modifier.fillMaxWidth().height(380.dp).padding(horizontal = 8.dp))
                    }
                }
                return@LazyColumn
            }

            // Concept list
            if (state.isLoadingConcepts) {
                items(3) { ShimmerBox(modifier = Modifier.fillMaxWidth().height(60.dp).padding(horizontal = 20.dp, vertical = 6.dp)) }
            } else {
                if (state.concepts.isEmpty()) {
                    item { Box(Modifier.fillMaxWidth().padding(40.dp), Alignment.Center) { Text("No concepts yet. Capture some content first!", color = VaultTextSecondary, fontSize = 14.sp) } }
                } else {
                    item { Text("${state.concepts.size} concepts", color = VaultTextTertiary, fontSize = 11.sp, modifier = Modifier.padding(start = 24.dp, top = 8.dp, bottom = 12.dp)) }
                    item {
                        val grouped = state.concepts.groupBy { it.conceptType }
                        Column(modifier = Modifier.padding(horizontal = 20.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
                            grouped.forEach { (type, concepts) ->
                                Column(verticalArrangement = Arrangement.spacedBy(10.dp)) {
                                    Text(type.replaceFirstChar { it.uppercase() }, color = conceptTypeColor(type), fontSize = 11.sp, fontWeight = FontWeight.SemiBold, letterSpacing = 0.8f.sp)
                                    FlowRow(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                        concepts.forEach { concept ->
                                            ConceptChip(concept.name, concept.conceptType, onClick = concept.id?.let { id -> { onConceptClick(id) } })
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun SearchResultRow(result: SearchResult, onClick: () -> Unit) {
    Row(modifier = Modifier.fillMaxWidth().clickable(onClick = onClick).padding(horizontal = 24.dp, vertical = 12.dp),
        horizontalArrangement = Arrangement.spacedBy(14.dp), verticalAlignment = Alignment.CenterVertically) {
        Box(modifier = Modifier.size(40.dp).background(VaultAccentMuted, MediumCorner), contentAlignment = Alignment.Center) {
            Text("◈", color = VaultAccent, fontSize = 18.sp)
        }
        Column(modifier = Modifier.weight(1f)) {
            Text(result.title, color = VaultTextPrimary, fontSize = 15.sp, fontWeight = FontWeight.Medium)
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(result.field, color = VaultAccent, fontSize = 11.sp)
                Text("·", color = VaultTextTertiary, fontSize = 11.sp)
                Text(result.contentType.replace("_", " "), color = VaultTextTertiary, fontSize = 11.sp)
            }
        }
        Text("→", color = VaultTextTertiary, fontSize = 16.sp)
    }
    HorizontalDivider(color = VaultDivider, modifier = Modifier.padding(horizontal = 24.dp))
}
