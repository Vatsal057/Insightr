package com.insightr.app.data

import com.google.gson.annotations.SerializedName
import com.insightr.app.*

/* =========================================================================
 * DTOs — shapes returned by api.py / feed.py (snake_case JSON)
 * ====================================================================== */

data class EntrySummaryDto(
    val id: Int?,
    val title: String,
    val headline: String?,
    val field: String,
    @SerializedName("content_type") val contentType: String,
    val tags: List<String> = emptyList(),
    @SerializedName("created_at") val createdAt: String
)

data class TypeSpecificFieldDto(val label: String, val value: String)

data class ActionItemDto(
    val id: Int? = null,
    val text: String,
    val done: Boolean = false,
    @SerializedName("entry_id") val entryId: Int? = null
)

data class ClaimDto(
    val claim: String,
    val verifiability: String = "unverified",
    val note: String? = null
)

data class TopicMapDto(
    @SerializedName("main_topic") val mainTopic: String,
    val subtopics: List<String> = emptyList()
)

data class ReferencedArtifactDto(
    val name: String,
    val type: String = "other",
    val url: String? = null,
    val snippet: String? = null
)

data class ConnectionDto(
    @SerializedName("entry_id") val entryId: Int,
    val title: String,
    val reason: String
)

data class ConceptDto(
    val id: Int? = null,
    @SerializedName("concept_type") val conceptType: String,
    val name: String,
    val summary: String,
    @SerializedName("source_entry_id") val sourceEntryId: Int? = null,
    @SerializedName("entry_count") val entryCount: Int? = null
)

data class ExtrasDto(
    @SerializedName("referenced_artifacts") val referencedArtifacts: List<ReferencedArtifactDto> = emptyList(),
    val claims: List<ClaimDto> = emptyList(),
    @SerializedName("explore_further") val exploreFurther: List<String> = emptyList(),
    @SerializedName("topic_map") val topicMap: TopicMapDto,
    val concepts: List<ConceptDto> = emptyList(),
    val connections: List<ConnectionDto> = emptyList()
)

data class EntryCardDto(
    val id: Int?,
    val title: String,
    @SerializedName("source_url") val sourceUrl: String,
    val field: String,
    val tags: List<String> = emptyList(),
    @SerializedName("content_type") val contentType: String,
    @SerializedName("created_at") val createdAt: String,
    val headline: String,
    val summary: String,
    @SerializedName("key_points") val keyPoints: String,
    @SerializedName("type_specific_fields") val typeSpecificFields: List<TypeSpecificFieldDto> = emptyList(),
    @SerializedName("action_items") val actionItems: List<ActionItemDto> = emptyList(),
    @SerializedName("next_step") val nextStep: String,
    val extras: ExtrasDto
)

/** Row shape from db.list_action_items — used by /api/todo. */
data class TodoItemDto(
    val id: Int,
    val text: String,
    val done: Boolean,
    @SerializedName("entry_id") val entryId: Int,
    val title: String
)

/** Row shape from db.list_collections — used by /api/collections. */
data class CollectionDto(
    val name: String,
    @SerializedName("entry_count") val entryCount: Int = 0
)

/** Row shape from db.search_entries / db.get_entries_for_concept. */
data class SearchResultDto(
    val id: Int?,
    val title: String,
    val field: String?,
    @SerializedName("content_type") val contentType: String?,
    val tags: List<String> = emptyList(),
    @SerializedName("created_at") val createdAt: String? = null,
    val headline: String? = null
)

data class ProcessResponseDto(val message: String, @SerializedName("task_id") val taskId: String)

data class StatusDto(
    val status: String,
    @SerializedName("entry_id") val entryId: Int? = null,
    val error: String? = null,
    val url: String? = null
)

/* =========================================================================
 * MAPPERS — DTO -> UI model
 * ====================================================================== */

fun EntrySummaryDto.toUi(): EntrySummary = EntrySummary(
    id = id ?: -1,
    title = title,
    headline = headline ?: "",
    field = field,
    contentType = contentType,
    tags = tags,
    createdAt = createdAt
)

fun SearchResultDto.toSummaryUi(): EntrySummary = EntrySummary(
    id = id ?: -1,
    title = title,
    headline = headline ?: "",
    field = field ?: "General",
    contentType = contentType ?: "general",
    tags = tags,
    createdAt = createdAt ?: ""
)

private fun parseArtifactType(raw: String): ArtifactType = when (raw.lowercase()) {
    "tool" -> ArtifactType.TOOL
    "book" -> ArtifactType.BOOK
    "link" -> ArtifactType.LINK
    "template" -> ArtifactType.TEMPLATE
    else -> ArtifactType.OTHER
}

private fun parseVerifiability(raw: String): Verifiability = when (raw.lowercase()) {
    "fact" -> Verifiability.FACT
    "opinion" -> Verifiability.OPINION
    else -> Verifiability.UNVERIFIED
}

private fun parseConceptType(raw: String): ConceptType = when (raw.lowercase()) {
    "framework" -> ConceptType.FRAMEWORK
    "tool" -> ConceptType.TOOL
    "book" -> ConceptType.BOOK
    "person" -> ConceptType.PERSON
    "methodology" -> ConceptType.METHODOLOGY
    "website" -> ConceptType.WEBSITE
    else -> ConceptType.CONCEPT
}

fun ConceptDto.toUi(): Concept = Concept(
    id = id,
    conceptType = parseConceptType(conceptType),
    name = name,
    summary = summary,
    sourceEntryId = sourceEntryId,
    entryCount = entryCount ?: 1
)

/**
 * Converts a full entry card DTO into a [KnowledgeEntry].
 *
 * `action_items` from feed.entry_to_card don't carry ids (schema.ActionItem
 * only has text/done), so we attach ids by matching against the global
 * /api/todo list for this entry (passed in as [todoForEntry]) when available.
 */
fun EntryCardDto.toUi(todoForEntry: List<TodoItemDto> = emptyList()): KnowledgeEntry {
    val actionItems = actionItems.mapIndexed { index, dto ->
        val matched = todoForEntry.getOrNull(index)
        ActionItem(
            id = dto.id ?: matched?.id ?: -(index + 1), // negative = no backend id yet
            text = dto.text,
            done = dto.done,
            entryId = id
        )
    }

    return KnowledgeEntry(
        id = id ?: -1,
        title = title,
        sourceUrl = sourceUrl,
        field = field,
        tags = tags,
        contentType = contentType,
        createdAt = createdAt,
        summary = Summary(headline = headline, body = summary),
        keyPoints = keyPoints,
        typeSpecificFields = typeSpecificFields.map { TypeSpecificField(it.label, it.value) },
        actionItems = actionItems,
        nextStep = nextStep,
        referencedArtifacts = extras.referencedArtifacts.map {
            ReferencedArtifact(it.name, parseArtifactType(it.type), it.url, it.snippet)
        },
        claims = extras.claims.map { Claim(it.claim, parseVerifiability(it.verifiability), it.note) },
        exploreFurther = extras.exploreFurther,
        topicMap = TopicMap(extras.topicMap.mainTopic, extras.topicMap.subtopics),
        concepts = extras.concepts.map { it.toUi() },
        connections = extras.connections.map { Connection(it.entryId, it.title, it.reason) }
    )
}

fun TodoItemDto.toUi(): ActionItem = ActionItem(id = id, text = text, done = done, entryId = entryId)
