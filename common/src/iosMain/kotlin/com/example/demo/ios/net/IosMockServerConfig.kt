package com.example.demo.ios.net

/**
 * iOS 平台层 Mock 服务器地址与设备标识配置（MSRV-007/016）。
 * iOS 模拟器访问宿主机使用 localhost；真机按需覆盖 baseUrl。
 * deviceId 由 Swift 侧生成并持久化，用于单设备登录与会话校验。
 */
object IosMockServerConfig {
    var baseUrl: String = "http://localhost:3000"

    var deviceId: String = "device-default"

    const val DefaultTimeoutSeconds = 5L
}

/** Kotlin 侧 HTTP 抽象结果，Swift 注入的真实客户端填充。 */
data class IosHttpResponse(val status: Int, val body: String)

/**
 * Kotlin 侧 HTTP 传输函数类型：由 Swift 提供 URLSession 实现（MSRV-002/007），
 * 保持与既有 `loadJson/saveJson` 一致的“平台注入闭包”模式。
 * 参数：method / path / json body（GET 传 null）。
 */
typealias IosHttpTransport = (method: String, path: String, json: String?) -> IosHttpResponse
