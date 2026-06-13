package com.example.vault.data

import android.content.Context
import android.content.SharedPreferences
import android.net.nsd.NsdManager
import android.net.nsd.NsdServiceInfo
import android.util.Log
import androidx.core.content.edit
import com.example.vault.BuildConfig

/**
 * Manages the server base URL at runtime.
 * Discovers the local backend using mDNS (Zeroconf) automatically.
 * Falls back to BuildConfig.API_BASE_URL (10.0.2.2:8000 for emulator).
 */
class ServerUrlManager(context: Context) {

    private val prefs: SharedPreferences =
        context.getSharedPreferences("vault_settings", Context.MODE_PRIVATE)

    var baseUrl: String
        get() = prefs.getString(KEY_SERVER_URL, BuildConfig.API_BASE_URL)
            ?: BuildConfig.API_BASE_URL
        set(value) {
            Log.d("VaultNSD", "Setting new Base URL: $value")
            prefs.edit { putString(KEY_SERVER_URL, value) }
        }

    private val nsdManager = context.getSystemService(Context.NSD_SERVICE) as NsdManager
    private val serviceType = "_insightr._tcp."

    private val discoveryListener = object : NsdManager.DiscoveryListener {
        override fun onDiscoveryStarted(regType: String) {
            Log.d("VaultNSD", "Service discovery started")
        }

        override fun onServiceFound(service: NsdServiceInfo) {
            Log.d("VaultNSD", "Service found: ${service.serviceName}")
            if (service.serviceType == serviceType) {
                nsdManager.resolveService(service, resolveListener)
            }
        }

        override fun onServiceLost(service: NsdServiceInfo) {
            Log.d("VaultNSD", "Service lost: ${service.serviceName}")
        }

        override fun onDiscoveryStopped(serviceType: String) {
            Log.d("VaultNSD", "Discovery stopped: $serviceType")
        }

        override fun onStartDiscoveryFailed(serviceType: String, errorCode: Int) {
            Log.e("VaultNSD", "Discovery failed: Error code:$errorCode")
            nsdManager.stopServiceDiscovery(this)
        }

        override fun onStopDiscoveryFailed(serviceType: String, errorCode: Int) {
            Log.e("VaultNSD", "Discovery failed: Error code:$errorCode")
            nsdManager.stopServiceDiscovery(this)
        }
    }

    private val resolveListener = object : NsdManager.ResolveListener {
        override fun onResolveFailed(serviceInfo: NsdServiceInfo, errorCode: Int) {
            Log.e("VaultNSD", "Resolve failed: $errorCode")
        }

        override fun onServiceResolved(serviceInfo: NsdServiceInfo) {
            Log.d("VaultNSD", "Resolve Succeeded. $serviceInfo")
            val host = serviceInfo.host.hostAddress
            val port = serviceInfo.port
            val newUrl = "http://$host:$port/"
            
            // Only update if it's different and valid
            if (host != null && host != "127.0.0.1") {
                baseUrl = newUrl
            }
        }
    }

    fun startDiscovery() {
        try {
            nsdManager.discoverServices(serviceType, NsdManager.PROTOCOL_DNS_SD, discoveryListener)
        } catch (e: Exception) {
            Log.e("VaultNSD", "Could not start NSD: ${e.message}")
        }
    }

    fun stopDiscovery() {
        try {
            nsdManager.stopServiceDiscovery(discoveryListener)
        } catch (e: Exception) {
            Log.e("VaultNSD", "Could not stop NSD: ${e.message}")
        }
    }

    companion object {
        private const val KEY_SERVER_URL = "server_base_url"
    }
}
