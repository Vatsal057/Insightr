package com.insightr.data.repository

import com.insightr.data.api.ApiService
import com.insightr.data.api.ConceptDto
import com.insightr.data.api.FeedItem
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ConceptRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getConcepts(
        conceptType: String? = null,
        query: String? = null
    ): Result<List<ConceptDto>> {
        return try {
            val concepts = apiService.getConcepts(conceptType, query)
            Result.success(concepts)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getConceptEntries(conceptId: Int): Result<List<FeedItem>> {
        return try {
            val entries = apiService.getConceptEntries(conceptId)
            Result.success(entries)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
