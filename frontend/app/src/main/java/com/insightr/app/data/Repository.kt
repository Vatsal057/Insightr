package com.insightr.app.data

import com.insightr.app.*
import java.io.IOException

/** Result wrapper. [Success.offline] is true when data came from SampleData
 *  because the backend was unreachable — screens can show a small banner. */
sealed class ApiResult<out T> {
    data class Success<T>(val data: T, val offline: Boolean = false) : ApiResult<T>()
    data class Error(val message: String) : ApiResult<Nothing>()
}

private fun errorMessage(e: Exception): String = when (e) {
    is IOException -> "Can't reach the server. Check your backend URL in Settings."
    else -> e.message ?: "Something went wrong."
}

/**
 * Talks to InsightrApiService (api.py). On network failure for read
 * operations, falls back to SampleData so the app remains usable as a demo.
 * Write operations (check/process/collections) surface an error instead,
 * since there's nothing meaningful to fake.
 */
object InsightrRepository {

    // --- Feed / search ----------------------------------------------------

    suspend fun getFeed(limit: Int = 50): ApiResult<List<EntrySummary>> = try {
        ApiResult.Success(NetworkConfig.api.getFeed(limit).map { it.toUi() })
    } catch (e: Exception) {
        ApiResult.Success(SampleData.summaries, offline = true)
    }

    suspend fun search(query: String, field: String? = null): ApiResult<List<EntrySummary>> = try {
        ApiResult.Success(NetworkConfig.api.search(query = query, field = field).map { it.toSummaryUi() })
    } catch (e: Exception) {
        val q = query.trim().lowercase()
        val filtered = SampleData.summaries.filter { entry ->
            (field == null || entry.field == field) &&
                (q.isEmpty() || entry.title.lowercase().contains(q) || entry.headline.lowercase().contains(q) ||
                    entry.tags.any { it.lowercase().contains(q) })
        }
        ApiResult.Success(filtered, offline = true)
    }

    // --- Entry detail -------------------------------------------------------

    suspend fun getEntry(id: Int): ApiResult<KnowledgeEntry> = try {
        val card = NetworkConfig.api.getEntry(id)
        val todoForEntry = try {
            NetworkConfig.api.getTodo().filter { it.entryId == id }
        } catch (e: Exception) {
            emptyList()
        }
        ApiResult.Success(card.toUi(todoForEntry))
    } catch (e: Exception) {
        val sample = SampleData.entryById(id)
        if (sample != null) ApiResult.Success(sample, offline = true)
        else ApiResult.Error("Entry #$id not found.")
    }

    // --- Action items / Todo -------------------------------------------------

    suspend fun getTodo(done: Boolean? = null): ApiResult<List<ActionItem>> = try {
        ApiResult.Success(NetworkConfig.api.getTodo(done).map { it.toUi() })
    } catch (e: Exception) {
        val all = SampleData.allActionItems().map { (_, item) -> item }
        val filtered = if (done == null) all else all.filter { it.done == done }
        ApiResult.Success(filtered, offline = true)
    }

    /** Returns the entry title for each todo item, for grouping in the UI. */
    suspend fun getTodoWithEntryTitles(): ApiResult<List<Pair<ActionItem, String>>> = try {
        ApiResult.Success(NetworkConfig.api.getTodo().map { it.toUi() to it.title })
    } catch (e: Exception) {
        ApiResult.Success(
            SampleData.allActionItems().map { (entry, item) -> item to entry.title },
            offline = true
        )
    }

    suspend fun checkTodo(itemId: Int, done: Boolean): ApiResult<Unit> {
        if (itemId < 0) {
            return ApiResult.Error("This item hasn't synced with the server yet — try refreshing.")
        }
        return try {
            NetworkConfig.api.checkTodo(itemId, done)
            ApiResult.Success(Unit)
        } catch (e: Exception) {
            ApiResult.Error(errorMessage(e))
        }
    }

    // --- Collections / Vaults -------------------------------------------------

    suspend fun getCollections(): ApiResult<List<CollectionDto>> = try {
        ApiResult.Success(NetworkConfig.api.getCollections())
    } catch (e: Exception) {
        ApiResult.Success(
            SampleData.collectionNames.map { name ->
                CollectionDto(name, SampleData.collectionMembers[name]?.size ?: 0)
            },
            offline = true
        )
    }

    suspend fun getCollection(name: String): ApiResult<List<EntrySummary>> = try {
        ApiResult.Success(NetworkConfig.api.getCollection(name).map { it.toUi() })
    } catch (e: Exception) {
        val ids = SampleData.collectionMembers[name] ?: emptyList()
        ApiResult.Success(SampleData.summaries.filter { it.id in ids }, offline = true)
    }

    suspend fun addToCollection(name: String, entryId: Int): ApiResult<Unit> = try {
        NetworkConfig.api.addToCollection(name, entryId)
        ApiResult.Success(Unit)
    } catch (e: Exception) {
        ApiResult.Error(errorMessage(e))
    }

    // --- Concepts (knowledge cards / wiki) ------------------------------------

    suspend fun getConcepts(conceptType: String? = null, query: String? = null): ApiResult<List<Concept>> = try {
        ApiResult.Success(NetworkConfig.api.getConcepts(conceptType, query).map { it.toUi() })
    } catch (e: Exception) {
        val filtered = SampleData.allConcepts.filter {
            (conceptType == null || it.conceptType.name.lowercase() == conceptType.lowercase())
        }
        ApiResult.Success(filtered, offline = true)
    }

    suspend fun getConceptEntries(conceptId: Int): ApiResult<List<EntrySummary>> = try {
        ApiResult.Success(NetworkConfig.api.getConceptEntries(conceptId).map { it.toSummaryUi() })
    } catch (e: Exception) {
        ApiResult.Success(
            SampleData.entriesForConcept(conceptId).map { entry ->
                EntrySummary(entry.id, entry.title, entry.summary.headline, entry.field, entry.contentType, entry.tags, entry.createdAt)
            },
            offline = true
        )
    }

    // --- Processing pipeline ---------------------------------------------------

    suspend fun processUrl(url: String): ApiResult<String> = try {
        ApiResult.Success(NetworkConfig.api.processUrl(url).taskId)
    } catch (e: Exception) {
        ApiResult.Error(errorMessage(e))
    }

    suspend fun getStatus(taskId: String): ApiResult<StatusDto> = try {
        ApiResult.Success(NetworkConfig.api.getStatus(taskId))
    } catch (e: Exception) {
        ApiResult.Error(errorMessage(e))
    }

    // --- Markdown export -----------------------------------------------------

    suspend fun exportEntry(entryId: Int): ApiResult<String> = try {
        ApiResult.Success(NetworkConfig.api.exportEntry(entryId))
    } catch (e: Exception) {
        ApiResult.Error(errorMessage(e))
    }
}
