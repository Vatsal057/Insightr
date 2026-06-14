package com.insightr.app.data

import retrofit2.http.*

/**
 * Mirrors every endpoint in api.py (including the todo/collections/export
 * endpoints added alongside this app).
 */
interface InsightrApiService {

    // --- Processing pipeline (main.py `process`) ---------------------

    @FormUrlEncoded
    @POST("api/process")
    suspend fun processUrl(@Field("url") url: String): ProcessResponseDto

    @GET("api/status/{taskId}")
    suspend fun getStatus(@Path("taskId") taskId: String): StatusDto

    // --- Feed / entries -------------------------------------------------

    @GET("api/feed")
    suspend fun getFeed(@Query("limit") limit: Int = 50): List<EntrySummaryDto>

    @GET("api/entries/{entryId}")
    suspend fun getEntry(@Path("entryId") entryId: Int): EntryCardDto

    @GET("api/search")
    suspend fun search(
        @Query("q") query: String = "",
        @Query("tag") tag: String? = null,
        @Query("field") field: String? = null,
        @Query("content_type") contentType: String? = null
    ): List<SearchResultDto>

    // --- Concepts (main.py `concepts`) ----------------------------------

    @GET("api/concepts")
    suspend fun getConcepts(
        @Query("concept_type") conceptType: String? = null,
        @Query("query") query: String? = null
    ): List<ConceptDto>

    @GET("api/concepts/{conceptId}/entries")
    suspend fun getConceptEntries(@Path("conceptId") conceptId: Int): List<SearchResultDto>

    // --- Action items / Todo (main.py `todo` / `check`) -----------------

    @GET("api/todo")
    suspend fun getTodo(@Query("done") done: Boolean? = null): List<TodoItemDto>

    @POST("api/todo/{itemId}/check")
    suspend fun checkTodo(@Path("itemId") itemId: Int, @Query("done") done: Boolean = true): TodoItemDto

    // --- Collections (main.py `collection`) ------------------------------

    @GET("api/collections")
    suspend fun getCollections(): List<CollectionDto>

    @FormUrlEncoded
    @POST("api/collections")
    suspend fun addToCollection(@Field("name") name: String, @Field("entry_id") entryId: Int): CollectionDto

    @GET("api/collections/{name}")
    suspend fun getCollection(@Path("name") name: String): List<EntrySummaryDto>

    // --- Markdown export (main.py `export`) ------------------------------

    @GET("api/export/{entryId}")
    suspend fun exportEntry(@Path("entryId") entryId: Int): String

    @GET("api/export/collection/{name}")
    suspend fun exportCollection(@Path("name") name: String): String
}
