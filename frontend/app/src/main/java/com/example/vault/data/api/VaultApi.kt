package com.example.vault.data.api

import okhttp3.MultipartBody
import retrofit2.http.*

interface VaultApi {

    // ─── Feed ─────────────────────────────────────────────────────────────────
    @GET("api/feed")
    suspend fun getFeed(@Query("limit") limit: Int = 50): List<SummaryCard>

    // ─── Entry Detail ─────────────────────────────────────────────────────────
    @GET("api/entries/{id}")
    suspend fun getEntry(@Path("id") id: Int): InsightCard

    // ─── Capture / Process ────────────────────────────────────────────────────
    @FormUrlEncoded
    @POST("api/process")
    suspend fun processUrl(@Field("url") url: String): ProcessResponse

    @GET("api/status/{taskId}")
    suspend fun getStatus(@Path("taskId") taskId: String): TaskStatus

    // ─── Concepts ─────────────────────────────────────────────────────────────
    @GET("api/concepts")
    suspend fun getConcepts(
        @Query("concept_type") conceptType: String? = null,
        @Query("query") query: String? = null,
    ): List<Concept>

    @GET("api/concepts/{id}/entries")
    suspend fun getConceptEntries(@Path("id") id: Int): List<ConceptEntry>

    // ─── Search ───────────────────────────────────────────────────────────────
    @GET("api/search")
    suspend fun search(
        @Query("q") query: String = "",
        @Query("tag") tag: String? = null,
        @Query("field") field: String? = null,
        @Query("content_type") contentType: String? = null,
    ): List<SearchResult>
}
