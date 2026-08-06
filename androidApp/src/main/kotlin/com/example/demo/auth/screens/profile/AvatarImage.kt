package com.example.demo.auth.screens.profile

import android.graphics.Bitmap
import androidx.compose.foundation.Image
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.unit.Dp
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext

/**
 * 头像显示组件：异步后台下载 + 内存缓存。
 * - key 由 `avatarUri + revision` 组成：上传新图后递增 revision，强制重新下载。
 * - 下载在 Dispatchers.IO 进行，不在主线程阻塞（修复"选完照片显示慢"）。
 * - 空 avatarUri 时显示占位（fallback 内容由调用方通过 [placeholder] 提供）。
 */
@Composable
internal fun AvatarImage(
    avatarUri: String?,
    size: Dp,
    modifier: Modifier = Modifier,
    placeholder: @Composable (() -> Unit)? = null
) {
    var bitmap by remember(avatarUri) { mutableStateOf<Bitmap?>(null) }

    LaunchedEffect(avatarUri) {
        bitmap = if (avatarUri.isNullOrBlank()) null else withContext(Dispatchers.IO) {
            resolveAvatarBitmap(avatarUri)
        }
    }

    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(androidx.compose.ui.graphics.Color.Transparent),
        contentAlignment = Alignment.Center
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap!!.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            placeholder?.invoke()
        }
    }
}

/**
 * 头像在编辑页使用：带 revision，上传成功后递增 revision 触发重载。
 * 用法：在持有 avatarUri 的可组合内 `var avatarRevision by remember { mutableStateOf(0) }`，
 * 上传成功后将 avatarRevision++，并传入本组件。
 */
@Composable
internal fun AvatarImageWithRevision(
    avatarUri: String?,
    revision: Int,
    size: Dp,
    modifier: Modifier = Modifier,
    placeholder: @Composable (() -> Unit)? = null
) {
    val key = "$avatarUri#$revision"
    var bitmap by remember(key) { mutableStateOf<Bitmap?>(null) }

    LaunchedEffect(key) {
        bitmap = if (avatarUri.isNullOrBlank()) null else withContext(Dispatchers.IO) {
            resolveAvatarBitmap(avatarUri)
        }
    }

    Box(
        modifier = modifier
            .size(size)
            .clip(CircleShape)
            .background(androidx.compose.ui.graphics.Color.Transparent),
        contentAlignment = Alignment.Center
    ) {
        if (bitmap != null) {
            Image(
                bitmap = bitmap!!.asImageBitmap(),
                contentDescription = null,
                modifier = Modifier.fillMaxSize(),
                contentScale = ContentScale.Crop
            )
        } else {
            placeholder?.invoke()
        }
    }
}
