package com.insightr.data.repository

import com.insightr.data.api.ActionItemDto
import com.insightr.data.api.ApiService
import javax.inject.Inject
import javax.inject.Singleton

@Singleton
class TodoRepository @Inject constructor(
    private val apiService: ApiService
) {
    suspend fun getTodos(done: Boolean? = null): Result<List<ActionItemDto>> {
        return try {
            val todos = apiService.getTodo(done)
            Result.success(todos)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }

    suspend fun checkTodo(itemId: Int, done: Boolean): Result<ActionItemDto> {
        return try {
            val todo = apiService.checkTodo(itemId, done)
            Result.success(todo)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
}
