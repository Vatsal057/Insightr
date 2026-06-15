package com.insightr.data.repository

import com.insightr.data.api.ApiService
import com.insightr.data.api.ProcessResponse
import com.insightr.data.api.StatusResponse
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class ProcessingRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun processUrl(url: String): Result<ProcessResponse> {
        return try {
            val response = apiService.processUrl(url)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun getStatus(taskId: String): Result<StatusResponse> {
        return try {
            val response = apiService.getStatus(taskId)
            Result.success(response)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
