package com.example.demo.core.network

import java.net.HttpURLConnection
import java.net.URL
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

/**
 * 极简同步 HTTP 客户端：把网络 I/O 放到独立工作线程，同步阻塞等待结果。
 * 仅供 Android 平台层远程数据源使用；common 不感知本类。
 */
class MockServerHttpClient(
    private val baseUrl: String,
    private val timeoutSeconds: Int = 5
) {
    private val executor = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "mock-server-http").apply { isDaemon = true }
    }

    data class Response(val status: Int, val body: String)

    data class BinaryResponse(val status: Int, val bytes: ByteArray)

    fun post(path: String, json: String): Response = call("POST", path, json)
    fun put(path: String, json: String): Response = call("PUT", path, json)
    fun delete(path: String, json: String): Response = call("DELETE", path, json)
    fun get(path: String): Response = call("GET", path, null)

    /** 上传二进制（头像等）。 */
    fun putBinary(path: String, bytes: ByteArray, contentType: String = "image/jpeg"): Int {
        val future = executor.submit<Int> {
            val connection = URL(baseUrl + path).openConnection() as HttpURLConnection
            try {
                connection.requestMethod = "PUT"
                connection.connectTimeout = timeoutSeconds * 1000
                connection.readTimeout = timeoutSeconds * 1000
                connection.setRequestProperty("Content-Type", contentType)
                connection.doOutput = true
                connection.outputStream.use { it.write(bytes) }
                connection.responseCode
            } finally {
                connection.disconnect()
            }
        }
        return try {
            future.get(timeoutSeconds.toLong(), TimeUnit.SECONDS)
        } catch (e: Exception) {
            future.cancel(true)
            -1
        }
    }

    /** 下载二进制（头像等）。 */
    fun getBinary(path: String): BinaryResponse {
        val future = executor.submit<BinaryResponse> {
            val connection = URL(baseUrl + path).openConnection() as HttpURLConnection
            try {
                connection.requestMethod = "GET"
                connection.connectTimeout = timeoutSeconds * 1000
                connection.readTimeout = timeoutSeconds * 1000
                val status = connection.responseCode
                val stream = if (status in 200..299) connection.inputStream else connection.errorStream
                val bytes = stream?.use { it.readBytes() } ?: ByteArray(0)
                BinaryResponse(status, bytes)
            } finally {
                connection.disconnect()
            }
        }
        return try {
            future.get(timeoutSeconds.toLong(), TimeUnit.SECONDS)
        } catch (e: Exception) {
            future.cancel(true)
            BinaryResponse(-1, ByteArray(0))
        }
    }

    private fun call(method: String, path: String, json: String?): Response {
        val future = executor.submit<Response> {
            val connection = URL(baseUrl + path).openConnection() as HttpURLConnection
            try {
                connection.requestMethod = method
                connection.connectTimeout = timeoutSeconds * 1000
                connection.readTimeout = timeoutSeconds * 1000
                connection.setRequestProperty("Content-Type", "application/json")
                if (json != null) {
                    connection.doOutput = true
                    connection.outputStream.use { it.write(json.toByteArray(Charsets.UTF_8)) }
                }
                val status = connection.responseCode
                val stream = if (status in 200..299) connection.inputStream else connection.errorStream
                val body = stream?.use { it.readBytes().toString(Charsets.UTF_8) }.orEmpty()
                Response(status, body)
            } finally {
                connection.disconnect()
            }
        }
        return try {
            future.get(timeoutSeconds.toLong(), TimeUnit.SECONDS)
        } catch (e: Exception) {
            future.cancel(true)
            Response(-1, "")
        }
    }

    fun shutdown() {
        executor.shutdownNow()
    }
}
