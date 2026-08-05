package com.example.demo.core.network

/**
 * Mock 服务器地址配置（MSRV-007）。
 * Android 模拟器通过 10.0.2.2 访问宿主机；真机/其他环境按需覆盖。
 */
object MockServerConfig {
    var baseUrl: String = "http://10.0.2.2:3000"

    const val DefaultTimeoutSeconds = 5
}
