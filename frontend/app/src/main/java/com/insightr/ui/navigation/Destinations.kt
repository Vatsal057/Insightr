package com.insightr.ui.navigation

object Destinations {
    const val FEED = "feed"
    const val ACTIONS = "actions"
    const val SEARCH = "search"
    const val VAULT = "vault"
    const val ENTRY_DETAIL = "entry/{entryId}"
    const val DEEP_RESEARCH = "deep_research/{entryId}"
    const val CONCEPT_DETAIL = "concept/{conceptId}"
    const val PROCESSING = "processing?url={url}"
    const val PROCESSING_RESULT = "processing_result?taskId={taskId}"
    const val COLLECTIONS = "collections"
    const val COLLECTION_DETAIL = "collection/{name}"
    const val EXPORT = "export/{entryId}"
    const val SETTINGS = "settings"
    const val ONBOARDING = "onboarding"

    fun entryDetail(entryId: Int) = "entry/$entryId"
    fun deepResearch(entryId: Int) = "deep_research/$entryId"
    fun conceptDetail(conceptId: Int) = "concept/$conceptId"
    fun processing(url: String) = "processing?url=$url"
    fun processingResult(taskId: String) = "processing_result?taskId=$taskId"
    fun collectionDetail(name: String) = "collection/$name"
    fun export(entryId: Int) = "export/$entryId"
}
