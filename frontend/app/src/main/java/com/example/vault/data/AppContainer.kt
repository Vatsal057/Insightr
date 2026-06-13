package com.example.vault.data

import android.content.Context
import androidx.room.Room
import com.example.vault.data.api.VaultApi
import com.example.vault.data.local.ProcessingHistoryDao
import com.example.vault.data.local.VaultDatabase
import com.example.vault.data.repository.VaultRepository
import com.google.gson.GsonBuilder
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Manual service locator — holds all singletons.
 * Created once in VaultApplication and passed down via CompositionLocal.
 */
class AppContainer(context: Context) {

    val serverUrlManager = ServerUrlManager(context)

    private val gson = GsonBuilder().create()

    private val okHttpClient = OkHttpClient.Builder()
        .addInterceptor(HttpLoggingInterceptor().apply {
            level = HttpLoggingInterceptor.Level.BODY
        })
        .connectTimeout(5, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .writeTimeout(5, TimeUnit.SECONDS)
        .build()

    private fun buildApi(): VaultApi = Retrofit.Builder()
        .baseUrl(serverUrlManager.baseUrl.trimEnd('/') + "/")
        .client(okHttpClient)
        .addConverterFactory(GsonConverterFactory.create(gson))
        .build()
        .create(VaultApi::class.java)

    val api: VaultApi by lazy { buildApi() }

    val repository: VaultRepository by lazy { VaultRepository(api) }

    private val database: VaultDatabase = Room.databaseBuilder(
        context.applicationContext,
        VaultDatabase::class.java,
        "vault.db",
    ).fallbackToDestructiveMigration(dropAllTables = true).build()

    val processingHistoryDao: ProcessingHistoryDao = database.processingHistoryDao()
}
