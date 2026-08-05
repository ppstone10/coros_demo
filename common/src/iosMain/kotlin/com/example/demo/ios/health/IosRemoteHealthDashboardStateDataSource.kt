package com.example.demo.ios.health

import com.example.demo.common.auth.mock.AuthJson
import com.example.demo.common.health.mock.MockHealthDashboardStoreJson
import com.example.demo.common.health.model.HealthDashboardSnapshot
import com.example.demo.common.health.store.HealthDashboardStateDataSource
import com.example.demo.ios.net.IosHttpTransport

/**
 * iOS 平台层远程健康数据源（MSRV-002/004）。
 * 与 Android `RemoteHealthDashboardStateDataSource` 同契约，GET/PUT 整份快照，
 * HTTP 传输由 Swift 注入 [IosHttpTransport]，本地 [cache] 作兜底缓存（MSRV-009）。
 */
class IosRemoteHealthDashboardStateDataSource(
    private val http: IosHttpTransport,
    private val cache: HealthDashboardStateDataSource
) : HealthDashboardStateDataSource {

    override fun load(userId: String): HealthDashboardSnapshot? {
        val response = http("GET", "/api/health/$userId", null)
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
        val response = http("PUT", "/api/health/${snapshot.userId}", body)
        if (response.status !in 200..299) return false
        return cache.save(snapshot)
    }

    override fun clear(userId: String): Boolean {
        return cache.clear(userId)
    }
}
