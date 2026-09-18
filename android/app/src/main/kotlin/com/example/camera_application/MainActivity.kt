package com.example.camera_application

import android.content.Context
import android.net.wifi.WifiManager
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private companion object {
        const val MULTICAST_CHANNEL = "camera_application/multicast_lock"
    }

    private var multicastLock: WifiManager.MulticastLock? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, MULTICAST_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "acquire" -> {
                        val lock = multicastLock ?: createMulticastLock().also {
                            multicastLock = it
                        }
                        if (!lock.isHeld) {
                            lock.acquire()
                        }
                        result.success(null)
                    }

                    "release" -> {
                        multicastLock?.let { lock ->
                            if (lock.isHeld) {
                                lock.release()
                            }
                        }
                        result.success(null)
                    }

                    else -> result.notImplemented()
                }
            }
    }

    override fun onDestroy() {
        multicastLock?.let { lock ->
            if (lock.isHeld) {
                lock.release()
            }
        }
        super.onDestroy()
    }

    private fun createMulticastLock(): WifiManager.MulticastLock {
        val wifiManager = applicationContext.getSystemService(Context.WIFI_SERVICE) as WifiManager
        return wifiManager.createMulticastLock("camera_application:mdns").apply {
            setReferenceCounted(false)
        }
    }
}
