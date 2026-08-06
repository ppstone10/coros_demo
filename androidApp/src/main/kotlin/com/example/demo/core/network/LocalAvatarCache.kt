package com.example.demo.core.network

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File

/**
 * 当前账号头像本地存储（MSRV-015）：内部目录只保留**一份当前账号头像**
 * `files/avatar_current.jpg`。
 * - 登录/切换账号：先清除旧头像，再用服务器头像覆盖（[refreshFromServer]）；
 * - 换新头像：信息完善界面选图即保存，信息修改界面保存时才上传并覆盖；
 * - 显示一律读本文件，即时无占位闪烁。
 */
object AvatarStore {
    private const val FILE_NAME = "avatar_current.jpg"

    private fun file(context: Context): File = File(context.filesDir, FILE_NAME)

    fun has(context: Context): Boolean = file(context).exists()

    /** 读取当前头像 Bitmap；不存在或损坏返回 null。 */
    fun get(context: Context): Bitmap? {
        val f = file(context)
        if (!f.exists()) return null
        return runCatching { BitmapFactory.decodeFile(f.absolutePath) }.getOrNull()
    }

    /** 覆盖写入当前头像。 */
    fun save(context: Context, bytes: ByteArray) {
        runCatching { file(context).writeBytes(bytes) }
    }

    /** 删除当前头像（登出/切换账号/注销时调用，避免显示旧账号头像）。 */
    fun clear(context: Context) {
        runCatching { file(context).delete() }
    }

    /**
     * 登录/切换账号后刷新当前头像：清除旧的，再按 avatarUri 从服务器拉取覆盖。
     * avatarUri 为空或非服务器路径时仅清除。
     */
    fun refreshFromServer(context: Context, avatarUri: String?, deviceId: String) {
        clear(context)
        if (avatarUri.isNullOrBlank() || !avatarUri.startsWith("/api/avatar/")) return
        val http = MockServerHttpClient(MockServerConfig.baseUrl, deviceId = deviceId)
        try {
            val response = http.getBinary(avatarUri)
            if (response.status in 200..299) save(context, response.bytes)
        } finally {
            http.shutdown()
        }
    }
}
