package com.example.vault.data.repository

import com.example.vault.data.api.*
import kotlinx.coroutines.delay

class VaultRepository(private val api: VaultApi) {

    // ─── Feed ─────────────────────────────────────────────────────────────────
    suspend fun getFeed(limit: Int = 50): Result<List<SummaryCard>> = runCatching {
        api.getFeed(limit)
    }

    // ─── Entry ────────────────────────────────────────────────────────────────
    suspend fun getEntry(id: Int): Result<InsightCard> = runCatching {
        api.getEntry(id)
    }

    // ─── Capture ──────────────────────────────────────────────────────────────
    suspend fun processUrl(url: String): Result<ProcessResponse> = runCatching {
        api.processUrl(url)
    }

    suspend fun pollStatus(taskId: String, onUpdate: (TaskStatus) -> Unit): TaskStatus {
        while (true) {
            val status = api.getStatus(taskId)
            onUpdate(status)
            if (status.status == "completed" || status.status == "failed") return status
            delay(2000)
        }
    }

    // ─── Concepts ─────────────────────────────────────────────────────────────
    suspend fun getConcepts(conceptType: String? = null, query: String? = null): Result<List<Concept>> =
        runCatching { api.getConcepts(conceptType = conceptType, query = query) }

    suspend fun getConceptEntries(conceptId: Int): Result<List<ConceptEntry>> =
        runCatching { api.getConceptEntries(conceptId) }

    // ─── Search ───────────────────────────────────────────────────────────────
    suspend fun search(
        query: String = "",
        tag: String? = null,
        field: String? = null,
        contentType: String? = null,
    ): Result<List<SearchResult>> = runCatching {
        api.search(query = query, tag = tag, field = field, contentType = contentType)
    }
}
