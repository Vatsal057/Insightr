package com.insightr.data.api

import retrofit2.http.Field
import retrofit2.http.FormUrlEncoded
import retrofit2.http.GET
import retrofit2.http.POST
import retrofit2.http.Path
import retrofit2.http.Query

interface ApiService {

    @FormUrlEncoded
    @POST("api/process")
    suspend fun processUrl(
        @Field("url") url: String
    ): ProcessResponse

    @GET("api/status/{task_id}")
    suspend fun getStatus(
        @Path("task_id") taskId: String
    ): StatusResponse

    @GET("api/feed")
    suspend fun getFeed(
        @Query("limit") limit: Int? = null
    ): List<FeedItem>

    @GET("api/entries/{id}")
    suspend fun getEntry(
        @Path("id") id: Int
    ): EntryResponse

    @GET("api/entries/{id}/deep-research-prompt")
    suspend fun getDeepResearchPrompt(
        @Path("id") id: Int
    ): DeepResearchPromptResponse

    @GET("api/todo")
    suspend fun getTodo(
        @Query("done") done: Boolean? = null
    ): List<ActionItemDto>

    @FormUrlEncoded
    @POST("api/todo/{item_id}/check")
    suspend fun checkTodo(
        @Path("item_id") itemId: Int,
        @Field("done") done: Boolean
    ): ActionItemDto

    @GET("api/search")
    suspend fun search(
        @Query("q") query: String = "",
        @Query("tag") tag: String? = null,
        @Query("field") field: String? = null,
        @Query("content_type") contentType: String? = null
    ): List<FeedItem>

    @GET("api/concepts")
    suspend fun getConcepts(
        @Query("concept_type") conceptType: String? = null,
        @Query("query") query: String? = null
    ): List<ConceptDto>

    @GET("api/concepts/{id}/entries")
    suspend fun getConceptEntries(
        @Path("id") id: Int
    ): List<FeedItem>

    @GET("api/collections")
    suspend fun getCollections(): List<CollectionDto>

    @FormUrlEncoded
    @POST("api/collections")
    suspend fun addToCollection(
        @Field("name") name: String,
        @Field("entry_id") entryId: Int
    ): CollectionDto

    @GET("api/collections/{name}")
    suspend fun getCollection(
        @Path("name") name: String
    ): List<FeedItem>

    @GET("api/export/{id}")
    suspend fun exportEntry(
        @Path("id") id: Int
    ): String

    @GET("api/export/collection/{name}")
    suspend fun exportCollection(
        @Path("name") name: String
    ): String
}
