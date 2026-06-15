package com.insightr.data.repository

import com.insightr.data.api.ApiService
import com.insightr.data.api.EntryResponse
import com.insightr.data.api.DeepResearchPromptResponse
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class EntryRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getEntry(id: Int): Result<EntryResponse> {
        return try {
            val entry = apiService.getEntry(id)
            Result.success(entry)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getDeepResearchPrompt(id: Int): Result<DeepResearchPromptResponse> {
        return try {
            val prompt = apiService.getDeepResearchPrompt(id)
            Result.success(prompt)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun exportEntry(id: Int): Result<String> {
        return try {
            val markdown = apiService.exportEntry(id)
            Result.success(markdown)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
