package com.example.demo.health

import android.content.Context
import com.example.demo.common.health.HealthDashboardSnapshot
import com.example.demo.common.health.HealthDashboardStateDataSource
import com.example.demo.common.health.JsonHealthDashboardStateDataSource

/** SharedPreferences 是训练项目的本地 mock 存储；key 中包含 userId 以隔离不同账号。 */
class AndroidHealthDashboardStateDataSource(context: Context) : HealthDashboardStateDataSource {
    private val preferences = context.getSharedPreferences(PreferencesName, Context.MODE_PRIVATE)

    private val delegate = JsonHealthDashboardStateDataSource(
        readString = { userId -> preferences.getString(key(userId), null) },
        writeString = { userId, json ->
            preferences.edit().putString(key(userId), json).commit()
        }
    )

    override fun load(userId: String): HealthDashboardSnapshot? = delegate.load(userId)

    override fun save(snapshot: HealthDashboardSnapshot): Boolean = delegate.save(snapshot)

    override fun clear(userId: String): Boolean = delegate.clear(userId)

    private fun key(userId: String) = "health_dashboard_$userId"

    private companion object { const val PreferencesName = "health_dashboard_mock_store" }
}
