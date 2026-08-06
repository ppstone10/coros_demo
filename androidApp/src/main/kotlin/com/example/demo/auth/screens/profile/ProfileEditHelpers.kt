package com.example.demo.auth.screens.profile

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.example.demo.R
import com.example.demo.common.auth.model.MeasurementSystem
import com.example.demo.core.network.AndroidDeviceId
import com.example.demo.core.network.AvatarStore
import com.example.demo.core.network.MockServerConfig
import com.example.demo.core.network.MockServerHttpClient
import java.io.ByteArrayOutputStream
import androidx.core.net.toUri
import androidx.core.graphics.scale

@Composable
internal fun MeasurementSystem.displayText(): String {
    return when (this) {
        MeasurementSystem.Metric -> stringResource(R.string.profile_unit_metric)
        MeasurementSystem.Imperial -> stringResource(R.string.profile_unit_imperial)
    }
}

@Composable
internal fun localizedCountryOptions(): List<Pair<String, String>> = listOf(
    "CN" to stringResource(R.string.common_china),
    "US" to stringResource(R.string.common_united_states),
    "GB" to stringResource(R.string.common_united_kingdom),
    "JP" to stringResource(R.string.common_japan)
)

internal fun parseBirthDate(value: String): Triple<Int, Int, Int> {
    val numbers = Regex("\\d+").findAll(value).map { it.value.toIntOrNull() ?: 0 }.toList()
    return Triple(
        numbers.getOrNull(0)?.takeIf { it in 1950..2026 } ?: 2002,
        numbers.getOrNull(1)?.takeIf { it in 1..12 } ?: 11,
        numbers.getOrNull(2)?.takeIf { it in 1..31 } ?: 17
    )
}

/** 头像缩放后的最大边长（像素）。控制上传体积。 */
private const val AVATAR_MAX_DIMENSION = 512

/** 头像文件在服务器上的相对路径前缀；avatarUri 只存相对路径，各端自行拼 base URL（MSRV-015）。 */
internal fun avatarServerPath(userId: String): String = "/api/avatar/$userId"

/**
 * 选择相册头像：读取 → 缩放 → JPEG → 上传到 mock server，并立即写入本地缓存。
 * 返回相对路径 `/api/avatar/{userId}`；失败返回 null。
 */
internal fun uploadAvatarFromUri(context: Context, uri: Uri, userId: String): String? {
    val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
    return uploadAvatarBytes(bytes, userId, AndroidDeviceId.get(context), context)
}

/** 拍摄头像：缩放 → JPEG → 上传到 mock server，并立即写入本地缓存；返回相对路径；失败返回 null。 */
internal fun uploadAvatarBitmap(bitmap: Bitmap, userId: String, deviceId: String, context: Context): String? {
    val scaled = bitmap.scaleToAvatar()
    val output = ByteArrayOutputStream()
    scaled.compress(Bitmap.CompressFormat.JPEG, 85, output)
    if (scaled !== bitmap) scaled.recycle()
    return uploadAvatarBytes(output.toByteArray(), userId, deviceId, context)
}

/** 上传头像字节到 mock server；成功后覆盖当前头像本地文件；返回相对路径，失败返回 null。 */
internal fun uploadAvatarBytes(bytes: ByteArray, userId: String, deviceId: String, context: Context): String? {
    val http = MockServerHttpClient(MockServerConfig.baseUrl, deviceId = deviceId)
    return try {
        val status = http.putBinary(avatarServerPath(userId), bytes)
        if (status in 200..299) {
            AvatarStore.save(context, bytes)
            avatarServerPath(userId)
        } else {
            null
        }
    } finally {
        http.shutdown()
    }
}

/** 按最大边长缩放；若已不超限则返回原对象。 */
internal fun Bitmap.scaleToAvatar(maxDimension: Int = AVATAR_MAX_DIMENSION): Bitmap {
    val width = width
    val height = height
    val longest = maxOf(width, height)
    if (longest <= maxDimension) return this
    val scale = maxDimension.toFloat() / longest
    val newWidth = (width * scale).toInt().coerceAtLeast(1)
    val newHeight = (height * scale).toInt().coerceAtLeast(1)
    return this.scale(newWidth, newHeight)
}

/** 仅读当前头像本地文件（不做网络），用于组合时同步初始值，避免占位闪烁。 */
internal fun resolveAvatarCached(avatarUri: String?, context: Context): Bitmap? {
    if (avatarUri.isNullOrBlank()) return null
    if (!avatarUri.startsWith("/api/avatar/")) return null
    return AvatarStore.get(context)
}

/**
 * 从 avatarUri 解析头像 Bitmap：
 * - `/api/avatar/{userId}`（服务器相对路径）→ 优先读当前头像本地文件，未命中再下载并覆盖（MSRV-015 即时显示）
 * - 其他旧格式（data URI / 本地文件路径）→ 回退本地解析
 */
internal fun resolveAvatarBitmap(avatarUri: String?, context: Context): Bitmap? {
    if (avatarUri.isNullOrBlank()) return null
    if (avatarUri.startsWith("/api/avatar/")) {
        AvatarStore.get(context)?.let { return it }
        val http = MockServerHttpClient(MockServerConfig.baseUrl)
        return try {
            val response = http.getBinary(avatarUri)
            if (response.status in 200..299) {
                AvatarStore.save(context, response.bytes)
                BitmapFactory.decodeByteArray(response.bytes, 0, response.bytes.size)
            } else {
                null
            }
        } finally {
            http.shutdown()
        }
    }
    if (avatarUri.startsWith("data:image")) {
        val comma = avatarUri.indexOf(',')
        if (comma < 0) return null
        val base64 = avatarUri.substring(comma + 1)
        return runCatching {
            BitmapFactory.decodeByteArray(
                android.util.Base64.decode(base64, android.util.Base64.NO_WRAP),
                0, 0, null
            )
        }.getOrNull()
    }
    return runCatching {
        BitmapFactory.decodeFile(avatarUri.toUri().path)
    }.getOrNull()
}
