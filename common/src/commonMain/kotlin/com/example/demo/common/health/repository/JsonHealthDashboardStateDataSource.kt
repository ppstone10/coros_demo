package com.example.demo.common.health.repository
import com.example.demo.common.auth.model.MockError
import com.example.demo.common.auth.model.MockResult
import com.example.demo.common.health.mock.MockHealthDashboardStoreJson
import com.example.demo.common.health.model.HealthDashboardSnapshot
import com.example.demo.common.health.store.HealthDashboardStateDataSource

class JsonHealthDashboardStateDataSource(
    private val readString: (userId: String) -> String?,
    private val writeString: (userId: String, json: String) -> Boolean
) : HealthDashboardStateDataSource {
    override fun load(userId: String): HealthDashboardSnapshot? {
        val raw = readString(userId)?.takeIf { it.isNotBlank() } ?: return null
        return runCatching { MockHealthDashboardStoreJson.decode(raw) }.getOrNull()
    }

    override fun save(snapshot: HealthDashboardSnapshot): MockResult<Unit> {
        return if (writeString(snapshot.userId, MockHealthDashboardStoreJson.encode(snapshot))) {
            MockResult.Success(Unit)
        } else {
            MockResult.Failure(MockError.PersistFailed)
        }
    }

    override fun clear(userId: String): Boolean = writeString(userId, "")
}
