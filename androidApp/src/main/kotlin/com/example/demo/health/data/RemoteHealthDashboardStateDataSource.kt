package com.example.demo.health.data

import com.example.demo.common.auth.mock.AuthJson
import com.example.demo.common.health.mock.MockHealthDashboardStoreJson
import com.example.demo.common.health.model.HealthDashboardSnapshot
import com.example.demo.common.health.store.HealthDashboardStateDataSource
import com.example.demo.core.network.MockServerHttpClient

/**
 * Android 平台层远程健康数据源（MSRV-002/004）。
 * 实现与本地 [HealthDashboardStateDataSource] 相同的同步接口，
 * GET/PUT `/api/health/{userId}` 整份快照，服务器按 userId 隔离。
 */
class RemoteHealthDashboardStateDataSource(
    private val http: MockServerHttpClient,
    private val cache: HealthDashboardStateDataSource
) : HealthDashboardStateDataSource {

    /** MSRV-019：服务器返回"已被其他设备登录"时回调，触发清会话并回登录页。 */
    var onSessionKicked: (() -> Unit)? = null

    override fun load(userId: String): HealthDashboardSnapshot? {
        val response = http.get("/api/health/$userId")
        if (response.status == 401 && response.body.contains("SESSION_EXPIRED_ELSEWHERE")) {
            onSessionKicked?.invoke()
        }
        return when {
            response.status in 200..299 -> {
                val snapshotJson = AuthJson.optionalObject(response.body, "snapshot")
                    ?: return null
                runCatching { MockHealthDashboardStoreJson.decode(snapshotJson) }
                    .getOrNull()
                    ?.also { cache.save(it) }
            }
            response.status == 404 -> null
            else -> cache.load(userId)
        }
    }

    override fun save(snapshot: HealthDashboardSnapshot): Boolean {
        val body = runCatching { MockHealthDashboardStoreJson.encode(snapshot) }
            .getOrNull() ?: return false
        val response = http.put("/api/health/${snapshot.userId}", body)
        if (response.status == 401 && response.body.contains("SESSION_EXPIRED_ELSEWHERE")) {
            onSessionKicked?.invoke()
        }
        if (response.status !in 200..299) return false
        return cache.save(snapshot)
    }

    override fun clear(userId: String): Boolean {
        return cache.clear(userId)
    }
}
