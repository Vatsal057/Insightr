package com.example.vault.data.api

import com.google.gson.annotations.SerializedName

// ─── Summary Feed Card (from GET /api/feed) ───────────────────────────────────
data class SummaryCard(
    val id: Int,
    val title: String,
    val headline: String,
    val field: String,
    @SerializedName("content_type") val contentType: String,
    val tags: List<String>,
    @SerializedName("created_at") val createdAt: String,
)

// ─── Type-specific field (label/value pair) ───────────────────────────────────
data class TypeSpecificField(
    val label: String,
    val value: String,
)

// ─── Action Item ──────────────────────────────────────────────────────────────
data class ActionItem(
    val text: String,
    val done: Boolean = false,
)

// ─── Claim ────────────────────────────────────────────────────────────────────
data class Claim(
    val claim: String,
    val verifiability: String, // "fact" | "opinion" | "unverified"
    val note: String?,
)

// ─── Topic Map ────────────────────────────────────────────────────────────────
data class TopicMap(
    @SerializedName("main_topic") val mainTopic: String,
    val subtopics: List<String>,
)

// ─── Referenced Artifact ─────────────────────────────────────────────────────
data class ReferencedArtifact(
    val name: String,
    val type: String,   // "tool" | "book" | "link" | "template" | "other"
    val url: String?,
    val snippet: String?,
)

// ─── Concept ─────────────────────────────────────────────────────────────────
data class Concept(
    val id: Int?,
    @SerializedName("concept_type") val conceptType: String,
    val name: String,
    val summary: String,
)

// ─── Connection (related entry) ───────────────────────────────────────────────
data class Connection(
    @SerializedName("entry_id") val entryId: Int,
    val title: String,
    val reason: String,
)

// ─── Extras (secondary context) ───────────────────────────────────────────────
data class EntryExtras(
    @SerializedName("referenced_artifacts") val referencedArtifacts: List<ReferencedArtifact>,
    val claims: List<Claim>,
    @SerializedName("explore_further") val exploreFurther: List<String>,
    @SerializedName("topic_map") val topicMap: TopicMap,
    val concepts: List<Concept>,
    val connections: List<Connection>,
)

// ─── Full Insight Card (from GET /api/entries/{id}) ───────────────────────────
data class InsightCard(
    val id: Int,
    val title: String,
    @SerializedName("source_url") val sourceUrl: String,
    val field: String,
    val tags: List<String>,
    @SerializedName("content_type") val contentType: String,
    @SerializedName("created_at") val createdAt: String,
    val headline: String,
    val summary: String,
    @SerializedName("key_points") val keyPoints: String,
    @SerializedName("type_specific_fields") val typeSpecificFields: List<TypeSpecificField>,
    @SerializedName("action_items") val actionItems: List<ActionItem>,
    @SerializedName("next_step") val nextStep: String,
    val extras: EntryExtras,
)

// ─── Process Request / Status ─────────────────────────────────────────────────
data class ProcessResponse(
    val message: String,
    @SerializedName("task_id") val taskId: String,
)

data class TaskStatus(
    val status: String,        // "processing" | "completed" | "failed"
    @SerializedName("entry_id") val entryId: Int?,
    val error: String?,
    val url: String?,
)

// ─── Search Result ────────────────────────────────────────────────────────────
data class SearchResult(
    val id: Int,
    val title: String,
    val field: String,
    @SerializedName("content_type") val contentType: String,
    @SerializedName("created_at") val createdAt: String,
)

// ─── Concept entry row (from /api/concepts/{id}/entries) ─────────────────────
data class ConceptEntry(
    val id: Int,
    val title: String,
    val field: String,
    @SerializedName("created_at") val createdAt: String,
)
