package com.example.demo.health

import android.content.Context
import com.example.demo.common.health.HealthDashboardSnapshot
import com.example.demo.common.health.HealthDashboardStateDataSource
import com.example.demo.common.health.HealthMockScenario

/** SharedPreferences 是训练项目的本地 mock 存储；key 中包含 userId 以隔离不同账号。 */
class AndroidHealthDashboardStateDataSource(context: Context) : HealthDashboardStateDataSource {
    private val preferences = context.getSharedPreferences(PreferencesName, Context.MODE_PRIVATE)

    override fun load(userId: String): HealthDashboardSnapshot? {
        val raw = preferences.getString(key(userId), null) ?: return null
        val parts = raw.split('|', limit = 2)
        val scenario = runCatching { HealthMockScenario.valueOf(parts[0]) }.getOrDefault(HealthMockScenario.Normal)
        val types = parts.getOrNull(1)?.split(',')?.mapNotNull { name -> runCatching { com.example.demo.common.health.HealthCardType.valueOf(name) }.getOrNull() }.orEmpty()
        return HealthDashboardSnapshot(userId, scenario, types.ifEmpty { com.example.demo.common.health.DefaultHealthCardOrder })
    }

    override fun save(snapshot: HealthDashboardSnapshot): Boolean = preferences.edit()
        .putString(key(snapshot.userId), snapshot.scenario.name + "|" + snapshot.enabledCardTypes.joinToString(",") { it.name })
        .commit()

    override fun clear(userId: String): Boolean = preferences.edit().remove(key(userId)).commit()

    private fun key(userId: String) = "health_dashboard_$userId"

    private companion object { const val PreferencesName = "health_dashboard_mock_store" }
}
