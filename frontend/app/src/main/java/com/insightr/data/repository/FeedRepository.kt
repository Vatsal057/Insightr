package com.insightr.data.repository

import com.insightr.data.api.ApiService
import com.insightr.data.api.FeedItem
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class FeedRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getFeed(limit: Int? = null): Result<List<FeedItem>> {
        return try {
            val feed = apiService.getFeed(limit)
            Result.success(feed)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
