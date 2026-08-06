package com.example.demo.core.network

import android.content.Context
import java.util.UUID

/**
 * 设备标识（MSRV-016/019）。
 * 首次调用生成 UUID 并持久化到 SharedPreferences；同一账号同一设备重复登录视为同一设备，
 * 不触发"已在其他设备登录"的二次确认。
 */
object AndroidDeviceId {
    private const val PREFS = "demo_device_id"
    private const val KEY = "device_id"

    fun get(context: Context): String {
        val prefs = context.applicationContext
            .getSharedPreferences(PREFS, Context.MODE_PRIVATE)
        val existing = prefs.getString(KEY, null)
        if (!existing.isNullOrBlank()) return existing
        val generated = "android-" + UUID.randomUUID().toString()
        prefs.edit().putString(KEY, generated).apply()
        return generated
    }
}
