package com.insightr.app

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.insightr.app.data.ApiResult
import com.insightr.app.data.CollectionDto
import com.insightr.app.data.InsightrRepository
import kotlinx.coroutines.launch

/**
 * Full structured view of a KnowledgeEntry — covers every field from the
 * new schema.py:
 *  - summary (headline + body)
 *  - type_specific_fields (per content_types.py template)
 *  - key_points (markdown bullet text)
 *  - action_items (toggle -> POST /api/todo/{id}/check)
 *  - claims, topic_map, referenced_artifacts, explore_further
 *  - next_step
 *  - concepts (-> CardDetailScreen)
 *  - connections (-> other entries)
 *  - export (-> GET /api/export/{id}, shared via Android share sheet)
 *  - vaults / collections (-> GET/POST /api/collections)
 */
@Composable
fun EntryDetailScreen(
    entryId: Int,
    onBack: () -> Unit = {},
    onEntryClick: (Int) -> Unit = {},
    onCardClick: (Int) -> Unit = {}
) {
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current

    var entry by remember { mutableStateOf<KnowledgeEntry?>(null) }
    var isLoading by remember { mutableStateOf(true) }
    var loadError by remember { mutableStateOf<String?>(null) }
    var offline by remember { mutableStateOf(false) }

    var actionItems by remember { mutableStateOf<List<ActionItem>>(emptyList()) }
    var collections by remember { mutableStateOf<List<CollectionDto>>(emptyList()) }
    var memberCollections by remember { mutableStateOf<Set<String>>(emptySet()) }

    LaunchedEffect(entryId) {
        isLoading = true
        when (val result = InsightrRepository.getEntry(entryId)) {
            is ApiResult.Success -> {
                entry = result.data
                actionItems = result.data.actionItems
                offline = result.offline
            }
            is ApiResult.Error -> loadError = result.message
        }
        when (val result = InsightrRepository.getCollections()) {
            is ApiResult.Success -> collections = result.data
            is ApiResult.Error -> {}
        }
        isLoading = false
    }

    Box(modifier = Modifier.fillMaxSize().background(InsightrColors.BackgroundGradient)) {
        when {
            isLoading -> Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                CircularProgressIndicator(color = InsightrColors.Accent)
            }
            loadError != null -> Column(
                modifier = Modifier.fillMaxSize().padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.Center
            ) {
                Text(loadError ?: "Something went wrong", color = InsightrColors.TextOnDark, fontSize = 14.sp)
                Spacer(modifier = Modifier.height(12.dp))
                PillButton(text = "Back", onClick = onBack)
            }
            entry != null -> {
                val current = entry!!
                LazyColumn(
                    modifier = Modifier.fillMaxSize().padding(horizontal = 24.dp),
                    contentPadding = PaddingValues(top = 32.dp, bottom = 32.dp),
                    verticalArrangement = Arrangement.spacedBy(18.dp)
                ) {
                    item {
                        TopBar(
                            onBack = onBack,
                            onExport = {
                                scope.launch {
                                    when (val result = InsightrRepository.exportEntry(current.id)) {
                                        is ApiResult.Success -> {
                                            val sendIntent = Intent(Intent.ACTION_SEND).apply {
                                                type = "text/plain"
                                                putExtra(Intent.EXTRA_TEXT, result.data)
                                                putExtra(Intent.EXTRA_SUBJECT, current.title)
                                            }
                                            context.startActivity(Intent.createChooser(sendIntent, "Export \"${current.title}\""))
                                        }
                                        is ApiResult.Error -> snackbarHostState.showSnackbar(result.message)
                                    }
                                }
                            }
                        )
                    }

                    if (offline) item { OfflineBanner(onOpenSettings = {}) }

                    item { HeaderSection(current) }
                    item { SummaryCard(current.summary) }

                    if (current.typeSpecificFields.isNotEmpty()) {
                        item { TypeSpecificFieldsSection(current) }
                    }

                    item { KeyPointsSection(current.keyPoints) }

                    if (actionItems.isNotEmpty()) {
                        item {
                            ActionItemsSection(
                                items = actionItems,
                                onToggle = { item ->
                                    val newDone = !item.done
                                    actionItems = actionItems.map { if (it.id == item.id) it.copy(done = newDone) else it }
                                    scope.launch {
                                        when (val result = InsightrRepository.checkTodo(item.id, newDone)) {
                                            is ApiResult.Error -> {
                                                // revert on failure
                                                actionItems = actionItems.map { if (it.id == item.id) it.copy(done = !newDone) else it }
                                                snackbarHostState.showSnackbar(result.message)
                                            }
                                            is ApiResult.Success -> {}
                                        }
                                    }
                                }
                            )
                        }
                    }

                    if (current.claims.isNotEmpty()) {
                        item { ClaimsSection(current.claims) }
                    }

                    item { TopicMapSection(current.topicMap) }

                    if (current.referencedArtifacts.isNotEmpty()) {
                        item { ArtifactsSection(current.referencedArtifacts) }
                    }

                    if (current.concepts.isNotEmpty()) {
                        item { ConceptsSection(current.concepts, onCardClick) }
                    }

                    if (current.connections.isNotEmpty()) {
                        item { ConnectionsSection(current.connections, onEntryClick) }
                    }

                    if (current.exploreFurther.isNotEmpty()) {
                        item { ExploreFurtherSection(current.exploreFurther) }
                    }

                    item { NextStepSection(current.nextStep) }

                    item {
                        CollectionsSection(
                            allCollections = collections.map { it.name },
                            selected = memberCollections,
                            onToggle = { name ->
                                val adding = name !in memberCollections
                                memberCollections = if (adding) memberCollections + name else memberCollections - name
                                if (adding) {
                                    scope.launch {
                                        when (val result = InsightrRepository.addToCollection(name, current.id)) {
                                            is ApiResult.Success -> snackbarHostState.showSnackbar("Added to \"$name\"")
                                            is ApiResult.Error -> {
                                                memberCollections = memberCollections - name
                                                snackbarHostState.showSnackbar(result.message)
                                            }
                                        }
                                    }
                                }
                            },
                            onCreateNew = { name ->
                                if (name.isNotBlank()) {
                                    collections = collections + CollectionDto(name, 0)
                                    memberCollections = memberCollections + name
                                    scope.launch {
                                        when (val result = InsightrRepository.addToCollection(name, current.id)) {
                                            is ApiResult.Success -> snackbarHostState.showSnackbar("Created \"$name\"")
                                            is ApiResult.Error -> snackbarHostState.showSnackbar(result.message)
                                        }
                                    }
                                }
                            }
                        )
                    }
                }
            }
        }

        SnackbarHost(hostState = snackbarHostState, modifier = Modifier.align(Alignment.BottomCenter).padding(16.dp))
    }
}

@Composable
private fun TopBar(onBack: () -> Unit, onExport: () -> Unit) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        CircleIconButton(icon = Icons.Default.ArrowBack, onClick = onBack, filled = false)
        CircleIconButton(icon = Icons.Default.IosShare, onClick = onExport, filled = false)
    }
}

@Composable
private fun HeaderSection(entry: KnowledgeEntry) {
    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(entry.field.uppercase(), color = InsightrColors.Accent, fontSize = 12.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.width(8.dp))
            Dot()
            Spacer(modifier = Modifier.width(8.dp))
            Text(ContentTypes.displayName(entry.contentType), color = InsightrColors.TextOnDarkMuted, fontSize = 12.sp)
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(entry.title, color = InsightrColors.TextOnDark, fontSize = 26.sp, fontWeight = FontWeight.Bold, lineHeight = 32.sp)
        Spacer(modifier = Modifier.height(8.dp))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(entry.tags) { tag ->
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(12.dp))
                        .background(Color.White.copy(alpha = 0.06f))
                        .padding(horizontal = 10.dp, vertical = 6.dp)
                ) {
                    Text("#$tag", color = InsightrColors.TextOnDarkMuted, fontSize = 11.sp)
                }
            }
        }
    }
}

@Composable
private fun SummaryCard(summary: Summary) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(24.dp))
            .background(InsightrColors.Cream)
            .padding(20.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Bolt, contentDescription = null, tint = InsightrColors.Accent, modifier = Modifier.size(18.dp))
            Spacer(modifier = Modifier.width(6.dp))
            Text("Headline", color = InsightrColors.TextOnCreamMuted, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(summary.headline, color = InsightrColors.TextOnCream, fontSize = 19.sp, fontWeight = FontWeight.Bold, lineHeight = 26.sp)
        Spacer(modifier = Modifier.height(10.dp))
        Text(summary.body, color = InsightrColors.TextOnCreamMuted, fontSize = 14.sp, lineHeight = 20.sp)
    }
}

@Composable
private fun TypeSpecificFieldsSection(entry: KnowledgeEntry) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(Color.White.copy(alpha = 0.06f))
            .padding(18.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(contentTypeIcon(entry.contentType), contentDescription = null, tint = InsightrColors.Accent, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(8.dp))
            Text(ContentTypes.displayName(entry.contentType), color = InsightrColors.TextOnDark, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
        }
        Spacer(modifier = Modifier.height(10.dp))
        entry.typeSpecificFields.forEachIndexed { index, field ->
            Column {
                Text(field.label, color = InsightrColors.Accent, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                Spacer(modifier = Modifier.height(2.dp))
                Text(field.value, color = InsightrColors.TextOnDarkMuted, fontSize = 13.sp, lineHeight = 18.sp)
            }
            if (index != entry.typeSpecificFields.lastIndex) {
                Spacer(modifier = Modifier.height(10.dp))
            }
        }
    }
}

@Composable
private fun KeyPointsSection(keyPoints: String) {
    Column {
        SectionLabel("Key Points", Icons.Default.Bolt)
        Spacer(modifier = Modifier.height(8.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(20.dp))
                .background(Color.White.copy(alpha = 0.06f))
                .padding(18.dp)
        ) {
            keyPoints.split("\n").filter { it.isNotBlank() }.forEach { line ->
                Row(modifier = Modifier.padding(bottom = 8.dp)) {
                    Text("•  ", color = InsightrColors.Accent, fontSize = 14.sp)
                    Text(
                        renderBold(line.removePrefix("- ").removePrefix("* ")),
                        color = InsightrColors.TextOnDark,
                        fontSize = 14.sp,
                        lineHeight = 20.sp
                    )
                }
            }
        }
    }
}

/** Renders simple **bold** markdown segments as an AnnotatedString. */
@Composable
private fun renderBold(text: String): androidx.compose.ui.text.AnnotatedString {
    val parts = text.split("**")
    return androidx.compose.ui.text.buildAnnotatedString {
        parts.forEachIndexed { index, part ->
            if (index % 2 == 1) {
                pushStyle(androidx.compose.ui.text.SpanStyle(fontWeight = FontWeight.Bold, color = InsightrColors.Accent))
                append(part)
                pop()
            } else {
                append(part)
            }
        }
    }
}

@Composable
private fun ActionItemsSection(items: List<ActionItem>, onToggle: (ActionItem) -> Unit) {
    val done = items.count { it.done }
    Column {
        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
            SectionLabel("Action Items", Icons.Default.CheckCircle)
            Text("$done/${items.size}", color = InsightrColors.TextOnDarkMuted, fontSize = 12.sp, fontWeight = FontWeight.SemiBold)
        }
        Spacer(modifier = Modifier.height(8.dp))
        items.forEach { action ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(InsightrColors.Cream)
                    .clickable { onToggle(action) }
                    .padding(horizontal = 16.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Text(
                    action.text,
                    color = if (action.done) InsightrColors.TextOnCreamMuted else InsightrColors.TextOnCream,
                    fontSize = 14.sp,
                    modifier = Modifier.weight(1f)
                )
                Switch(
                    checked = action.done,
                    onCheckedChange = { onToggle(action) },
                    colors = SwitchDefaults.colors(checkedThumbColor = InsightrColors.Accent, checkedTrackColor = InsightrColors.AccentSoft)
                )
            }
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

@Composable
private fun ClaimsSection(claims: List<Claim>) {
    Column {
        SectionLabel("Claims", Icons.Default.FactCheck)
        Spacer(modifier = Modifier.height(8.dp))
        claims.forEach { claim ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .padding(14.dp)
            ) {
                Box(
                    modifier = Modifier
                        .clip(RoundedCornerShape(10.dp))
                        .background(verifiabilityColor(claim.verifiability).copy(alpha = 0.2f))
                        .padding(horizontal = 8.dp, vertical = 4.dp)
                ) {
                    Text(verifiabilityLabel(claim.verifiability), color = verifiabilityColor(claim.verifiability), fontSize = 10.sp, fontWeight = FontWeight.Bold)
                }
                Spacer(modifier = Modifier.width(10.dp))
                Column {
                    Text(claim.claim, color = InsightrColors.TextOnDark, fontSize = 13.sp, lineHeight = 18.sp)
                    claim.note?.let {
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(it, color = InsightrColors.TextOnDarkMuted, fontSize = 11.sp, lineHeight = 16.sp)
                    }
                }
            }
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

@Composable
private fun TopicMapSection(topicMap: TopicMap) {
    Column {
        SectionLabel("Topic Map", Icons.Default.AccountTree)
        Spacer(modifier = Modifier.height(8.dp))
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(20.dp))
                .background(Color.White.copy(alpha = 0.06f))
                .padding(16.dp)
        ) {
            Text(topicMap.mainTopic, color = InsightrColors.TextOnDark, fontSize = 15.sp, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(10.dp))
            LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                items(topicMap.subtopics) { sub ->
                    Box(
                        modifier = Modifier
                            .clip(RoundedCornerShape(14.dp))
                            .background(InsightrColors.PillDark)
                            .padding(horizontal = 12.dp, vertical = 8.dp)
                    ) {
                        Text(sub, color = InsightrColors.TextOnDark, fontSize = 12.sp)
                    }
                }
            }
        }
    }
}

@Composable
private fun ArtifactsSection(artifacts: List<ReferencedArtifact>) {
    val context = LocalContext.current
    Column {
        SectionLabel("Referenced", Icons.Default.LinkedCamera)
        Spacer(modifier = Modifier.height(8.dp))
        artifacts.forEach { artifact ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .let { m ->
                        if (artifact.url != null) m.clickable {
                            context.startActivity(Intent(Intent.ACTION_VIEW, android.net.Uri.parse(artifact.url)))
                        } else m
                    }
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(artifactIcon(artifact.type), contentDescription = null, tint = InsightrColors.TextOnDarkMuted, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(10.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(artifact.name, color = InsightrColors.TextOnDark, fontSize = 13.sp, fontWeight = FontWeight.SemiBold)
                    artifact.url?.let { Text(it, color = InsightrColors.TextOnDarkMuted, fontSize = 11.sp) }
                    artifact.snippet?.let { Text(it, color = InsightrColors.TextOnDarkMuted, fontSize = 11.sp, lineHeight = 16.sp) }
                }
                Text(artifact.type.name.lowercase(), color = InsightrColors.Accent, fontSize = 10.sp, fontWeight = FontWeight.Bold)
            }
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

private fun artifactIcon(type: ArtifactType): androidx.compose.ui.graphics.vector.ImageVector = when (type) {
    ArtifactType.TOOL -> Icons.Default.Build
    ArtifactType.BOOK -> Icons.Default.MenuBook
    ArtifactType.LINK -> Icons.Default.Link
    ArtifactType.TEMPLATE -> Icons.Default.Description
    ArtifactType.OTHER -> Icons.Default.Inventory2
}

@Composable
private fun ConceptsSection(concepts: List<Concept>, onCardClick: (Int) -> Unit) {
    Column {
        SectionLabel("Concepts", Icons.Default.Style)
        Spacer(modifier = Modifier.height(8.dp))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            items(concepts) { concept ->
                Column(
                    modifier = Modifier
                        .width(170.dp)
                        .clip(RoundedCornerShape(18.dp))
                        .background(InsightrColors.PillDark)
                        .let { m -> concept.id?.let { id -> m.clickable { onCardClick(id) } } ?: m }
                        .padding(16.dp)
                ) {
                    Icon(conceptTypeIcon(concept.conceptType), contentDescription = null, tint = InsightrColors.Accent, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.height(8.dp))
                    Text(concept.conceptType.name.lowercase().replaceFirstChar { it.uppercase() }, color = InsightrColors.Accent, fontSize = 11.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(concept.name, color = InsightrColors.TextOnDark, fontSize = 14.sp, fontWeight = FontWeight.Medium, lineHeight = 18.sp)
                }
            }
        }
    }
}

@Composable
private fun ConnectionsSection(connections: List<Connection>, onEntryClick: (Int) -> Unit) {
    Column {
        SectionLabel("Connections", Icons.Default.Hub)
        Spacer(modifier = Modifier.height(8.dp))
        connections.forEach { conn ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(InsightrColors.Cream)
                    .clickable { onEntryClick(conn.entryId) }
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.North, contentDescription = null, tint = InsightrColors.TextOnCreamMuted, modifier = Modifier.size(16.dp))
                Spacer(modifier = Modifier.width(10.dp))
                Column(modifier = Modifier.weight(1f)) {
                    Text(conn.title, color = InsightrColors.TextOnCream, fontSize = 14.sp, fontWeight = FontWeight.SemiBold)
                    Text(conn.reason, color = InsightrColors.TextOnCreamMuted, fontSize = 11.sp)
                }
                Icon(Icons.Default.ArrowForward, contentDescription = null, tint = InsightrColors.TextOnCreamMuted)
            }
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

@Composable
private fun ExploreFurtherSection(questions: List<String>) {
    Column {
        SectionLabel("Explore Further", Icons.Default.Explore)
        Spacer(modifier = Modifier.height(8.dp))
        questions.forEach { q ->
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(Color.White.copy(alpha = 0.06f))
                    .padding(14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Icon(Icons.Default.QuestionMark, contentDescription = null, tint = InsightrColors.Accent, modifier = Modifier.size(14.dp))
                Spacer(modifier = Modifier.width(10.dp))
                Text(q, color = InsightrColors.TextOnDark, fontSize = 13.sp, lineHeight = 18.sp, modifier = Modifier.weight(1f))
            }
            Spacer(modifier = Modifier.height(8.dp))
        }
    }
}

@Composable
private fun NextStepSection(nextStep: String) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(20.dp))
            .background(InsightrColors.Accent.copy(alpha = 0.15f))
            .padding(16.dp)
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(Icons.Default.Flag, contentDescription = null, tint = InsightrColors.Accent, modifier = Modifier.size(16.dp))
            Spacer(modifier = Modifier.width(6.dp))
            Text("Next Step", color = InsightrColors.Accent, fontSize = 12.sp, fontWeight = FontWeight.Bold)
        }
        Spacer(modifier = Modifier.height(6.dp))
        Text(nextStep, color = InsightrColors.TextOnDark, fontSize = 14.sp, lineHeight = 20.sp, fontWeight = FontWeight.Medium)
    }
}

@Composable
private fun CollectionsSection(
    allCollections: List<String>,
    selected: Set<String>,
    onToggle: (String) -> Unit,
    onCreateNew: (String) -> Unit
) {
    var newName by remember { mutableStateOf("") }

    Column {
        SectionLabel("Vaults", Icons.Default.Folder)
        Spacer(modifier = Modifier.height(8.dp))
        LazyRow(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            items(allCollections) { name ->
                val isSelected = name in selected
                Row(
                    modifier = Modifier
                        .clip(RoundedCornerShape(16.dp))
                        .background(if (isSelected) InsightrColors.Cream else Color.White.copy(alpha = 0.06f))
                        .clickable { onToggle(name) }
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(
                        if (isSelected) Icons.Default.Check else Icons.Default.Add,
                        contentDescription = null,
                        tint = if (isSelected) InsightrColors.TextOnCream else InsightrColors.TextOnDarkMuted,
                        modifier = Modifier.size(14.dp)
                    )
                    Spacer(modifier = Modifier.width(6.dp))
                    Text(name, color = if (isSelected) InsightrColors.TextOnCream else InsightrColors.TextOnDarkMuted, fontSize = 12.sp)
                }
            }
        }
        Spacer(modifier = Modifier.height(10.dp))
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(16.dp))
                .background(Color.White.copy(alpha = 0.06f))
                .padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(modifier = Modifier.weight(1f)) {
                if (newName.isEmpty()) {
                    Text("New vault name...", color = InsightrColors.TextOnDarkMuted, fontSize = 13.sp)
                }
                androidx.compose.foundation.text.BasicTextField(
                    value = newName,
                    onValueChange = { newName = it },
                    singleLine = true,
                    textStyle = androidx.compose.ui.text.TextStyle(color = InsightrColors.TextOnDark, fontSize = 13.sp),
                    modifier = Modifier.fillMaxWidth()
                )
            }
            Icon(
                Icons.Default.Add,
                contentDescription = "Create vault",
                tint = InsightrColors.TextOnDarkMuted,
                modifier = Modifier.clickable {
                    if (newName.isNotBlank()) {
                        onCreateNew(newName.trim())
                        newName = ""
                    }
                }
            )
        }
    }
}

@Composable
private fun SectionLabel(text: String, icon: androidx.compose.ui.graphics.vector.ImageVector) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        Icon(icon, contentDescription = null, tint = InsightrColors.TextOnDarkMuted, modifier = Modifier.size(16.dp))
        Spacer(modifier = Modifier.width(8.dp))
        Text(text, color = InsightrColors.TextOnDark, fontSize = 16.sp, fontWeight = FontWeight.SemiBold)
    }
}
