package com.insightr.data.api

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class FeedItem(
    val id: Int? = null,
    val title: String = "",
    val hook: String = "",
    val field: String = "",
    @SerialName("content_type") val contentType: String = "",
    val tags: List<String> = emptyList(),
    @SerialName("created_at") val createdAt: String = "",
    @SerialName("top_action") val topAction: ActionItemDto? = null,
    @SerialName("action_item_count") val actionItemCount: Int = 0,
    @SerialName("now_action_count") val nowActionCount: Int = 0,
    @SerialName("implementation_step_count") val implementationStepCount: Int = 0,
    @SerialName("tool_count") val toolCount: Int = 0,
    @SerialName("effort_pill") val effortPill: EffortPillDto? = null
)

@Serializable
data class EffortPillDto(
    val label: String = "",
    val difficulty: Int = 0,
    val effort: Int = 0,
    @SerialName("time_to_implement") val timeToImplement: String = "",
    @SerialName("time_to_learn") val timeToLearn: String = ""
)

@Serializable
data class ActionItemDto(
    val id: Int? = null,
    val text: String = "",
    val done: Boolean = false,
    val priority: String = "soon",
    @SerialName("time_estimate") val timeEstimate: String? = null,
    @SerialName("entry_id") val entryId: Int? = null,
    val title: String? = null
)

@Serializable
data class EntryResponse(
    val id: Int? = null,
    val title: String = "",
    @SerialName("source_url") val sourceUrl: String = "",
    val field: String = "",
    val tags: List<String> = emptyList(),
    @SerialName("content_type") val contentType: String = "",
    @SerialName("type_specific_fields") val typeSpecificFields: List<TypeSpecificFieldDto> = emptyList(),
    @SerialName("created_at") val createdAt: String = "",
    @SerialName("zone_grab") val zoneGrab: ZoneGrab = ZoneGrab(),
    @SerialName("zone_substance") val zoneSubstance: ZoneSubstance = ZoneSubstance(),
    @SerialName("zone_deep") val zoneDeep: ZoneDeep = ZoneDeep()
)

@Serializable
data class TypeSpecificFieldDto(
    val label: String = "",
    val value: String = ""
)

@Serializable
data class ZoneGrab(
    val hook: String = "",
    @SerialName("next_step") val nextStep: String = "",
    @SerialName("top_action") val topAction: ActionItemDto? = null,
    @SerialName("effort_pill") val effortPill: EffortPillDto? = null
)

@Serializable
data class ZoneSubstance(
    @SerialName("core_takeaway") val coreTakeaway: CoreTakeaway = CoreTakeaway(),
    @SerialName("note_blocks") val noteBlocks: List<NoteBlockDto> = emptyList(),
    @SerialName("action_items") val actionItems: List<ActionItemDto> = emptyList(),
    @SerialName("key_points") val keyPoints: String = "",
    @SerialName("tools_resources") val toolsResources: List<ToolResourceDto> = emptyList(),
    @SerialName("implementation_plan") val implementationPlan: List<ImplementationStepDto> = emptyList()
)

@Serializable
data class CoreTakeaway(
    val headline: String = "",
    val body: String = ""
)

@Serializable
data class NoteBlockDto(
    @SerialName("block_type") val blockType: String = "",
    val title: String = "",
    val content: String = ""
)

@Serializable
data class ToolResourceDto(
    val name: String = "",
    val type: String = "other",
    val description: String? = null,
    val url: String? = null
)

@Serializable
data class ImplementationStepDto(
    @SerialName("step_number") val stepNumber: Int = 0,
    val title: String = "",
    val description: String = "",
    @SerialName("time_estimate") val timeEstimate: String? = null
)

@Serializable
data class ZoneDeep(
    val claims: List<ClaimDto> = emptyList(),
    @SerialName("missing_context") val missingContext: List<MissingContextDto> = emptyList(),
    @SerialName("rabbit_hole") val rabbitHole: RabbitHoleDto = RabbitHoleDto(),
    @SerialName("knowledge_cards") val knowledgeCards: List<ConceptDto> = emptyList(),
    @SerialName("referenced_artifacts") val referencedArtifacts: List<ReferencedArtifactDto> = emptyList(),
    @SerialName("topic_map") val topicMap: TopicMapDto = TopicMapDto(),
    @SerialName("effort_estimation") val effortEstimation: EffortEstimationDto? = null,
    val connections: List<ConnectionDto> = emptyList()
)

@Serializable
data class ClaimDto(
    val claim: String = "",
    val verifiability: String = "unverified",
    val note: String? = null
)

@Serializable
data class MissingContextDto(
    val category: String = "",
    val text: String = ""
)

@Serializable
data class RabbitHoleDto(
    @SerialName("follow_up_questions") val followUpQuestions: List<String> = emptyList(),
    @SerialName("knowledge_gaps") val knowledgeGaps: List<String> = emptyList(),
    @SerialName("adjacent_topics") val adjacentTopics: List<String> = emptyList(),
    @SerialName("advanced_concepts") val advancedConcepts: List<String> = emptyList()
)

@Serializable
data class ConceptDto(
    val id: Int? = null,
    @SerialName("concept_type") val conceptType: String = "concept",
    val name: String = "",
    val summary: String = ""
)

@Serializable
data class ReferencedArtifactDto(
    val name: String = "",
    val type: String = "other",
    val description: String? = null,
    val url: String? = null,
    val snippet: String? = null
)

@Serializable
data class TopicMapDto(
    @SerialName("main_topic") val mainTopic: String = "",
    val subtopics: List<String> = emptyList()
)

@Serializable
data class EffortEstimationDto(
    @SerialName("time_to_learn") val timeToLearn: String = "",
    @SerialName("time_to_implement") val timeToImplement: String = "",
    val difficulty: Int = 3,
    val effort: Int = 3,
    @SerialName("difficulty_rationale") val difficultyRationale: String? = null
)

@Serializable
data class ConnectionDto(
    @SerialName("entry_id") val entryId: Int = 0,
    val title: String = "",
    val reason: String = ""
)

@Serializable
data class ProcessResponse(
    @SerialName("task_id") val taskId: String = "",
    val status: String = "",
    val url: String = ""
)

@Serializable
data class StatusResponse(
    val status: String = "",
    @SerialName("entry_id") val entryId: Int? = null,
    val error: String? = null,
    val url: String? = null
)

@Serializable
data class DeepResearchPromptResponse(
    @SerialName("entry_id") val entryId: Int = 0,
    @SerialName("deep_research_prompt") val deepResearchPrompt: String = ""
)

@Serializable
data class CollectionDto(
    val name: String = "",
    @SerialName("entry_count") val entryCount: Int = 0
)

@Serializable
data class AddToCollectionRequest(
    val name: String = "",
    @SerialName("entry_id") val entryId: Int = 0
)

@Serializable
data class ErrorResponse(
    val error: String = ""
)
