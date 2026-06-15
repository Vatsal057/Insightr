package com.insightr.data.repository

import com.insightr.data.api.ApiService
import com.insightr.data.api.FeedItem
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class SearchRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun search(
        query: String,
        tag: String? = null,
        field: String? = null,
        contentType: String? = null
    ): Result<List<FeedItem>> {
        return try {
            val results = apiService.search(query, tag, field, contentType)
            Result.success(results)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
