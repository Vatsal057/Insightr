package com.insightr.app.data

import android.content.Context
import android.content.SharedPreferences
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import com.google.gson.Gson
import com.google.gson.GsonBuilder
import okhttp3.OkHttpClient
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.converter.scalars.ScalarsConverterFactory
import java.util.concurrent.TimeUnit

/**
 * Holds the user-configurable backend URL (e.g. "http://192.168.1.50:8000/")
 * and lazily (re)builds the Retrofit/ApiService instance whenever it changes.
 *
 * Supports mDNS/NSD auto-discovery to find the backend on the same Wi-Fi.
 */
object NetworkConfig {

    private const val TAG = "NetworkConfig"
    private const val PREFS = "insightr_prefs"
    private const val KEY_BASE_URL = "base_url"
    private const val SERVICE_TYPE = "_insightr._tcp."
    
    const val DEFAULT_BASE_URL = "http://192.168.0.107:8000/" // Fallback

    private lateinit var prefs: SharedPreferences
    private var cachedService: InsightrApiService? = null
    private var cachedUrl: String? = null
    private var nsdManager: NsdManager? = null

    fun init(context: Context) {
        prefs = context.applicationContext.getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager
        startDiscovery()
    }

    private fun startDiscovery() {
        val discoveryListener = object : NsdManager.DiscoveryListener {
            override fun onDiscoveryStarted(regType: String) {
                Log.d(TAG, "Service discovery started")
            }

            override fun onServiceFound(service: NsdServiceInfo) {
                Log.d(TAG, "Service found: ${service.serviceName}")
                if (service.serviceType == SERVICE_TYPE) {
                    nsdManager?.resolveService(service, object : NsdManager.ResolveListener {
                        override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
                            Log.e(TAG, "Resolve failed: $errorCode")
                        }

                        override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
                            Log.d(TAG, "Service resolved: ${serviceInfo.host.hostAddress}:${serviceInfo.port}")
                            val url = "http://${serviceInfo.host.hostAddress}:${serviceInfo.port}/"
                            setBaseUrl(url)
                        }
                    })
                }
            }

            override fun onServiceLost(service: NsdServiceInfo) {
                Log.e(TAG, "Service lost: ${service.serviceName}")
            }

            override fun onDiscoveryStopped(regType: String) {
                Log.i(TAG, "Discovery stopped: $regType")
            }

            override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.e(TAG, "Discovery failed: $errorCode")
                nsdManager?.stopServiceDiscovery(this)
            }

            override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
                Log.e(TAG, "Stop discovery failed: $errorCode")
                nsdManager?.stopServiceDiscovery(this)
            }
        }

        try {
            nsdManager?.discoverServices(SERVICE_TYPE, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
        } catch (e: Exception) {
            Log.e(TAG, "Failed to start service discovery", e)
        }
    }

    fun getBaseUrl(): String = prefs.getString(KEY_BASE_URL, DEFAULT_BASE_URL) ?: DEFAULT_BASE_URL

    fun setBaseUrl(url: String) {
        val normalized = if (url.endsWith("/")) url else "$url/"
        if (getBaseUrl() != normalized) {
            Log.i(TAG, "Updating base URL to: $normalized")
            prefs.edit().putString(KEY_BASE_URL, normalized).apply()
            cachedService = null // force rebuild on next access
        }
    }

    val api: InsightrApiService
        get() {
            val url = getBaseUrl()
            if (cachedService == null || cachedUrl != url) {
                cachedService = buildService(url)
                cachedUrl = url
            }
            return cachedService!!
        }

    private fun buildService(baseUrl: String): InsightrApiService {
        val gson: Gson = GsonBuilder().setLenient().create()

        val client = OkHttpClient.Builder()
            .connectTimeout(15, TimeUnit.SECONDS)
            .readTimeout(60, TimeUnit.SECONDS)
            .writeTimeout(60, TimeUnit.SECONDS)
            .build()

        val retrofit = Retrofit.Builder()
            .baseUrl(baseUrl)
            .client(client)
            // Scalars first so plain-text endpoints (markdown export) aren't
            // forced through Gson; Gson handles everything else.
            .addConverterFactory(ScalarsConverterFactory.create())
            .addConverterFactory(GsonConverterFactory.create(gson))
            .build()

        return retrofit.create(InsightrApiService::class.java)
    }
}
