package com.example.vault.data.local

import androidx.room.*
import kotlinx.coroutines.flow.Flow

// ─── Entity ───────────────────────────────────────────────────────────────────
@Entity(tableName = "processing_history")
data class ProcessingHistoryEntity(
    @PrimaryKey val taskId: String,
    val url: String,
    val status: String,         // "processing" | "completed" | "failed"
    val entryId: Int?,
    val errorMessage: String?,
    val submittedAt: Long = System.currentTimeMillis(),
)

// ─── DAO ──────────────────────────────────────────────────────────────────────
@Dao
interface ProcessingHistoryDao {
    @Query("SELECT * FROM processing_history ORDER BY submittedAt DESC")
    fun getAll(): Flow<List<ProcessingHistoryEntity>>

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun upsert(item: ProcessingHistoryEntity)

    @Query("UPDATE processing_history SET status = :status, entryId = :entryId, errorMessage = :error WHERE taskId = :taskId")
    suspend fun updateStatus(taskId: String, status: String, entryId: Int?, error: String?)

    @Query("DELETE FROM processing_history WHERE submittedAt < :before")
    suspend fun deleteOlderThan(before: Long)
}

// ─── Database ─────────────────────────────────────────────────────────────────
@Database(entities = [ProcessingHistoryEntity::class], version = 1, exportSchema = false)
abstract class VaultDatabase : RoomDatabase() {
    abstract fun processingHistoryDao(): ProcessingHistoryDao
}
