package com.insightr.data.repository

import com.insightr.data.api.ApiService
import com.insightr.data.api.CollectionDto
import com.insightr.data.api.FeedItem
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class CollectionRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getCollections(): Result<List<CollectionDto>> {
        return try {
            val collections = apiService.getCollections()
            Result.success(collections)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun addToCollection(name: String, entryId: Int): Result<CollectionDto> {
        return try {
            val collection = apiService.addToCollection(name, entryId)
            Result.success(collection)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getCollection(name: String): Result<List<FeedItem>> {
        return try {
            val entries = apiService.getCollection(name)
            Result.success(entries)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun exportCollection(name: String): Result<String> {
        return try {
            val markdown = apiService.exportCollection(name)
            Result.success(markdown)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
