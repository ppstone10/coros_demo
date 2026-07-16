package com.example.demo.common.health

class JsonHealthDashboardStateDataSource(
    private val readString: (userId: String) -> String?,
    private val writeString: (userId: String, json: String) -> Boolean
) : HealthDashboardStateDataSource {
    override fun load(userId: String): HealthDashboardSnapshot? {
        val raw = readString(userId)?.takeIf { it.isNotBlank() } ?: return null
        return runCatching { MockHealthDashboardStoreJson.decode(raw) }.getOrNull()
    }

    override fun save(snapshot: HealthDashboardSnapshot): Boolean {
        return writeString(snapshot.userId, MockHealthDashboardStoreJson.encode(snapshot))
    }

    override fun clear(userId: String): Boolean = writeString(userId, "")
}
